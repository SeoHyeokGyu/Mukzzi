package usecase

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"math"
	"net/http"
	"net/url"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/repository"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

// ─────────────────────────────────────────
// 인터페이스
// ─────────────────────────────────────────

type SeedUsecase interface {
	// SeedMenus 메뉴 영양소 데이터 수집을 시작합니다 (온디맨드 배치).
	// 이미 실행 중이면 ErrSeedAlreadyRunning을 반환합니다.
	SeedMenus(ctx context.Context, source string, limit int) error

	// GetSeedStatus 마지막 실행 결과를 반환합니다.
	GetSeedStatus() *SeedJobStatus

	// SyncMenusToRedis DB의 메뉴 데이터를 Redis ZSET으로 동기화합니다.
	SyncMenusToRedis(ctx context.Context) error
}

var ErrSeedAlreadyRunning = fmt.Errorf("이미 수집 작업이 실행 중입니다")

// ─────────────────────────────────────────
// 상태 타입
// ─────────────────────────────────────────

type SeedJobState string

const (
	SeedJobStateIdle    SeedJobState = "IDLE"
	SeedJobStateRunning SeedJobState = "RUNNING"
	SeedJobStateDone    SeedJobState = "DONE"
	SeedJobStateFailed  SeedJobState = "FAILED"
)

type SeedJobStatus struct {
	State     SeedJobState `json:"state"`
	Source    string       `json:"source"`
	StartedAt *time.Time   `json:"started_at,omitempty"`
	EndedAt   *time.Time   `json:"ended_at,omitempty"`
	Inserted  int          `json:"inserted"`
	Skipped   int          `json:"skipped"`
	Error     string       `json:"error,omitempty"`
}

// ─────────────────────────────────────────
// 구현체
// ─────────────────────────────────────────

type seedUsecase struct {
	menuRepo    repository.MenuRepository
	menuUsecase MenuUsecase
	db          *gorm.DB

	mu     sync.Mutex
	status SeedJobStatus
}

func NewSeedUsecase(
	menuRepo repository.MenuRepository,
	menuUsecase MenuUsecase,
	db *gorm.DB,
) SeedUsecase {
	return &seedUsecase{
		menuRepo:    menuRepo,
		menuUsecase: menuUsecase,
		db:          db,
		status:      SeedJobStatus{State: SeedJobStateIdle},
	}
}

func (u *seedUsecase) GetSeedStatus() *SeedJobStatus {
	u.mu.Lock()
	defer u.mu.Unlock()
	s := u.status
	return &s
}

func (u *seedUsecase) SeedMenus(ctx context.Context, source string, limit int) error {
	u.mu.Lock()
	if u.status.State == SeedJobStateRunning {
		u.mu.Unlock()
		return ErrSeedAlreadyRunning
	}
	now := time.Now()
	u.status = SeedJobStatus{
		State:     SeedJobStateRunning,
		Source:    source,
		StartedAt: &now,
	}
	u.mu.Unlock()

	// 실제 수집은 goroutine에서 실행 (HTTP 응답을 블로킹하지 않음)
	go func() {
		bgCtx := context.Background()
		inserted, skipped, err := u.runSeed(bgCtx, source, limit)
		ended := time.Now()

		u.mu.Lock()
		defer u.mu.Unlock()

		if err != nil {
			u.status.State = SeedJobStateFailed
			u.status.Error = err.Error()
		} else {
			u.status.State = SeedJobStateDone
		}
		u.status.EndedAt = &ended
		u.status.Inserted = inserted
		u.status.Skipped = skipped
	}()

	return nil
}

func (u *seedUsecase) runSeed(ctx context.Context, source string, limit int) (inserted, skipped int, err error) {
	var menus []domain.Menu

	switch source {
	case "mfds":
		menus = fetchMFDS(ctx, limit)
	case "usda":
		menus = fetchUSDA(ctx, limit)
	default: // "all"
		menus = append(menus, fetchMFDS(ctx, limit)...)
		menus = append(menus, fetchUSDA(ctx, 500)...)
	}

	menus = filterInvalidMenus(menus)
	slog.Info("[seed] 수집 완료", slog.Int("total", len(menus)))

	inserted, skipped = bulkUpsert(u.db, menus)

	// 수집 완료 후 Redis 자동 동기화
	if syncErr := u.menuUsecase.SyncMenusToRedis(ctx); syncErr != nil {
		slog.Error("[seed] Redis 동기화 실패", slog.Any("error", syncErr))
		// Redis 실패는 치명적이지 않으므로 err로 올리지 않음
	}

	return inserted, skipped, nil
}

func (u *seedUsecase) SyncMenusToRedis(ctx context.Context) error {
	return u.menuUsecase.SyncMenusToRedis(ctx)
}

// ─────────────────────────────────────────
// MFDS (식약처)
// ─────────────────────────────────────────

// 공공데이터포털 식품영양성분DB 응답 구조
type mfdsResponse struct {
	Header struct {
		ResultCode string `json:"resultCode"`
		ResultMsg  string `json:"resultMsg"`
	} `json:"header"`
	Body struct {
		Items      []mfdsRow `json:"items"`
		NumOfRows  int       `json:"numOfRows"`
		PageNo     int       `json:"pageNo"`
		TotalCount int       `json:"totalCount"`
	} `json:"body"`
}

type mfdsRow struct {
	FoodName string `json:"FOOD_NM_KR"`
	FoodCat1 string `json:"FOOD_CAT1_NM"` // 식품대분류명
	Calories string `json:"AMT_NUM1"`     // 에너지(kcal)
	Protein  string `json:"AMT_NUM3"`     // 단백질(g)
	Fat      string `json:"AMT_NUM4"`     // 지방(g)
	Carbs    string `json:"AMT_NUM6"`     // 탄수화물(g)
	Fiber    string `json:"AMT_NUM8"`     // 식이섬유(g)
	VitaminC string `json:"AMT_NUM21"`    // 비타민C(mg)
}

func fetchMFDS(ctx context.Context, limit int) []domain.Menu {
	apiKey := os.Getenv("MFDS_API_KEY")
	if apiKey == "" {
		slog.Error("[seed] MFDS_API_KEY 환경 변수가 없습니다")
		return nil
	}

	baseURL := "https://apis.data.go.kr/1471000/FoodNtrCpntDbInfo02/getFoodNtrCpntDbInq02"
	pageSize := 500
	var allMenus []domain.Menu
	pageNo := 1

	for len(allMenus) < limit {
		reqURL := fmt.Sprintf("%s?serviceKey=%s&pageNo=%d&numOfRows=%d&type=json",
			baseURL, apiKey, pageNo, pageSize)
		slog.Info("[seed] MFDS 요청", slog.Int("page", pageNo))

		body, err := httpGet(ctx, reqURL)
		if err != nil {
			slog.Error("[seed] MFDS 요청 실패", slog.Any("error", err))
			break
		}

		var resp mfdsResponse
		if err := json.Unmarshal(body, &resp); err != nil {
			slog.Error("[seed] MFDS 파싱 실패", slog.Any("error", err), slog.String("body", string(body[:min(200, len(body))])))
			break
		}
		if resp.Header.ResultCode != "00" {
			slog.Error("[seed] MFDS API 오류",
				slog.String("code", resp.Header.ResultCode),
				slog.String("msg", resp.Header.ResultMsg))
			break
		}

		rows := resp.Body.Items
		if len(rows) == 0 {
			break
		}

		for _, row := range rows {
			name := strings.TrimSpace(row.FoodName)
			if name == "" {
				continue
			}
			allMenus = append(allMenus, domain.Menu{
				Name:                name,
				Category:            mfdsCategory(row.FoodCat1, name),
				Source:              domain.SourceMFDS,
				DefaultCalories:     parseFloat(row.Calories),
				DefaultCarbs:        parseFloat(row.Carbs),
				DefaultProtein:      parseFloat(row.Protein),
				DefaultFat:          parseFloat(row.Fat),
				DefaultFiber:        parseFloat(row.Fiber),
				DefaultVitaminScore: calcVitaminScore(parseFloat(row.VitaminC)),
			})
		}
		slog.Info("[seed] MFDS 수집 중", slog.Int("collected", len(allMenus)))

		// 마지막 페이지 확인
		if len(rows) < pageSize || len(allMenus) >= resp.Body.TotalCount {
			break
		}
		pageNo++
		time.Sleep(300 * time.Millisecond)
	}
	return allMenus
}

// ─────────────────────────────────────────
// USDA
// ─────────────────────────────────────────

type usdaSearchResponse struct {
	Foods []usdaFood `json:"foods"`
}

type usdaFood struct {
	FdcID        int            `json:"fdcId"`
	Description  string         `json:"description"`
	FoodCategory string         `json:"foodCategory"`
	Nutrients    []usdaNutrient `json:"foodNutrients"`
}

type usdaNutrient struct {
	NutrientID   int     `json:"nutrientId"`
	NutrientName string  `json:"nutrientName"`
	Value        float64 `json:"value"`
}

const (
	usdaEnergyID  = 1008
	usdaCarbsID   = 1005
	usdaProteinID = 1003
	usdaFatID     = 1004
	usdaFiberID   = 1079
	usdaVitCID    = 1162
)

var usdaKeywords = []string{
	"kimchi", "bibimbap", "bulgogi", "japchae", "tteokbokki",
	"samgyeopsal", "galbi", "doenjang", "gimbap", "ramyeon",
	"pizza", "pasta", "hamburger", "sandwich", "salad",
	"sushi", "ramen", "udon", "tempura", "yakitori",
	"fried rice", "noodles", "soup", "stew", "curry",
	"coffee", "latte", "bread", "cake", "cookie",
}

func fetchUSDA(ctx context.Context, limit int) []domain.Menu {
	apiKey := os.Getenv("USDA_API_KEY")
	if apiKey == "" {
		slog.Error("[seed] USDA_API_KEY 환경 변수가 없습니다")
		return nil
	}

	var allMenus []domain.Menu
	seen := make(map[string]struct{})
	perKeyword := limit / len(usdaKeywords)
	if perKeyword < 5 {
		perKeyword = 5
	}

	for _, keyword := range usdaKeywords {
		if len(allMenus) >= limit {
			break
		}
		params := url.Values{}
		params.Set("api_key", apiKey)
		params.Set("query", keyword)
		params.Set("dataType", "Survey (FNDDS)")
		params.Set("pageSize", fmt.Sprintf("%d", perKeyword))

		reqURL := "https://api.nal.usda.gov/fdc/v1/foods/search?" + params.Encode()
		body, err := httpGet(ctx, reqURL)
		if err != nil {
			slog.Error("[seed] USDA 요청 실패", slog.String("keyword", keyword), slog.Any("error", err))
			continue
		}

		var resp usdaSearchResponse
		if err := json.Unmarshal(body, &resp); err != nil {
			continue
		}

		for _, food := range resp.Foods {
			name := strings.TrimSpace(food.Description)
			if name == "" {
				continue
			}
			if _, exists := seen[name]; exists {
				continue
			}
			seen[name] = struct{}{}

			nutrients := usdaNutrientMap(food.Nutrients)
			allMenus = append(allMenus, domain.Menu{
				Name:                name,
				Category:            usdaCategory(food.FoodCategory, name),
				Source:              domain.SourceUSDA,
				DefaultCalories:     nutrients[usdaEnergyID],
				DefaultCarbs:        nutrients[usdaCarbsID],
				DefaultProtein:      nutrients[usdaProteinID],
				DefaultFat:          nutrients[usdaFatID],
				DefaultFiber:        nutrients[usdaFiberID],
				DefaultVitaminScore: calcVitaminScore(nutrients[usdaVitCID]),
			})
		}
		slog.Info("[seed] USDA 수집 중", slog.String("keyword", keyword), slog.Int("total", len(allMenus)))
		time.Sleep(200 * time.Millisecond)
	}
	return allMenus
}

// ─────────────────────────────────────────
// DB Upsert
// ─────────────────────────────────────────

func bulkUpsert(db *gorm.DB, menus []domain.Menu) (inserted, skipped int) {
	batchSize := 500
	for i := 0; i < len(menus); i += batchSize {
		end := i + batchSize
		if end > len(menus) {
			end = len(menus)
		}
		batch := menus[i:end]

		result := db.Clauses(clause.OnConflict{
			Columns: []clause.Column{{Name: "name"}, {Name: "category"}},
			DoUpdates: clause.Assignments(map[string]interface{}{
				"default_calories":      gorm.Expr("EXCLUDED.default_calories"),
				"default_carbs":         gorm.Expr("EXCLUDED.default_carbs"),
				"default_protein":       gorm.Expr("EXCLUDED.default_protein"),
				"default_fat":           gorm.Expr("EXCLUDED.default_fat"),
				"default_fiber":         gorm.Expr("EXCLUDED.default_fiber"),
				"default_vitamin_score": gorm.Expr("EXCLUDED.default_vitamin_score"),
				"source":                gorm.Expr("EXCLUDED.source"),
				"updated_at":            gorm.Expr("NOW()"),
			}),
		}).CreateInBatches(batch, batchSize)

		if result.Error != nil {
			slog.Error("[seed] DB upsert 실패", slog.Any("error", result.Error))
			continue
		}
		inserted += int(result.RowsAffected)
		skipped += len(batch) - int(result.RowsAffected)
	}
	return
}

// ─────────────────────────────────────────
// 카테고리 매핑 (기존 seeder와 동일)
// ─────────────────────────────────────────

func mfdsCategory(foodGroup, name string) domain.MenuCategory {
	name = strings.ToLower(name)
	group := strings.ToLower(foodGroup)

	cafeKw := []string{"커피", "라떼", "음료", "주스", "차", "tea", "coffee", "latte", "beverage"}
	for _, k := range cafeKw {
		if strings.Contains(name, k) || strings.Contains(group, k) {
			return domain.CategoryCafe
		}
	}
	snackKw := []string{"과자", "스낵", "빵", "케이크", "쿠키", "아이스크림", "사탕", "초콜릿", "과자류", "제과"}
	for _, k := range snackKw {
		if strings.Contains(name, k) || strings.Contains(group, k) {
			return domain.CategorySnack
		}
	}
	japaneseKw := []string{"스시", "초밥", "라멘", "우동", "소바", "돈카츠", "야키토리", "타코야키", "오니기리"}
	for _, k := range japaneseKw {
		if strings.Contains(name, k) {
			return domain.CategoryJapanese
		}
	}
	chineseKw := []string{"짜장", "짬뽕", "탕수육", "마파두부", "볶음밥", "딤섬", "춘권", "팔보채"}
	for _, k := range chineseKw {
		if strings.Contains(name, k) {
			return domain.CategoryChinese
		}
	}
	westernKw := []string{"파스타", "피자", "스테이크", "햄버거", "샌드위치", "리조또", "그라탕", "오믈렛"}
	for _, k := range westernKw {
		if strings.Contains(name, k) {
			return domain.CategoryWestern
		}
	}
	koreanGr := []string{"밥류", "면류", "국류", "찌개", "반찬", "구이", "김치", "한식"}
	for _, k := range koreanGr {
		if strings.Contains(group, k) || strings.Contains(name, k) {
			return domain.CategoryKorean
		}
	}
	return domain.CategoryOther
}

func usdaCategory(foodCategory, name string) domain.MenuCategory {
	cat := strings.ToLower(foodCategory)
	n := strings.ToLower(name)
	switch {
	case strings.Contains(cat, "coffee") || strings.Contains(cat, "beverage") ||
		strings.Contains(n, "coffee") || strings.Contains(n, "tea") || strings.Contains(n, "latte"):
		return domain.CategoryCafe
	case strings.Contains(cat, "snack") || strings.Contains(cat, "candy") ||
		strings.Contains(cat, "cake") || strings.Contains(cat, "cookie"):
		return domain.CategorySnack
	case strings.Contains(n, "sushi") || strings.Contains(n, "ramen") ||
		strings.Contains(n, "udon") || strings.Contains(n, "tempura"):
		return domain.CategoryJapanese
	case strings.Contains(n, "kimchi") || strings.Contains(n, "bibimbap") ||
		strings.Contains(n, "bulgogi") || strings.Contains(n, "gimbap"):
		return domain.CategoryKorean
	case strings.Contains(n, "pizza") || strings.Contains(n, "pasta") ||
		strings.Contains(n, "hamburger") || strings.Contains(n, "sandwich") || strings.Contains(n, "steak"):
		return domain.CategoryWestern
	case strings.Contains(n, "fried rice") || strings.Contains(n, "dim sum") || strings.Contains(n, "noodle"):
		return domain.CategoryChinese
	default:
		return domain.CategoryOther
	}
}

// ─────────────────────────────────────────
// 헬퍼
// ─────────────────────────────────────────

func filterInvalidMenus(menus []domain.Menu) []domain.Menu {
	seen := make(map[string]struct{})
	var valid []domain.Menu
	for _, m := range menus {
		m.Name = strings.TrimSpace(m.Name)
		if m.Name == "" {
			continue
		}
		key := string(m.Category) + ":" + m.Name
		if _, exists := seen[key]; exists {
			continue
		}
		seen[key] = struct{}{}
		if m.DefaultCalories <= 0 || m.DefaultCalories > 5000 {
			continue
		}
		if m.DefaultCarbs+m.DefaultProtein+m.DefaultFat > 500 {
			continue
		}
		valid = append(valid, m)
	}
	return valid
}

func httpGet(ctx context.Context, reqURL string) ([]byte, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, reqURL, nil)
	if err != nil {
		return nil, err
	}
	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("HTTP %d: %s", resp.StatusCode, reqURL)
	}
	buf := make([]byte, 0, 1<<20)
	tmp := make([]byte, 4096)
	for {
		n, readErr := resp.Body.Read(tmp)
		buf = append(buf, tmp[:n]...)
		if readErr != nil {
			break
		}
	}
	return buf, nil
}

func parseFloat(s string) float64 {
	s = strings.TrimSpace(s)
	if s == "" || s == "-" || s == "N/A" {
		return 0
	}
	var f float64
	fmt.Sscanf(s, "%f", &f)
	return math.Round(f*10) / 10
}

func usdaNutrientMap(nutrients []usdaNutrient) map[int]float64 {
	m := make(map[int]float64, len(nutrients))
	for _, n := range nutrients {
		m[n.NutrientID] = n.Value
	}
	return m
}

func calcVitaminScore(vitaminC float64) float64 {
	score := (vitaminC / 100.0) * 100.0
	if score > 100 {
		score = 100
	}
	return math.Round(score*10) / 10
}
