package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log/slog"
	"math"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/config"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
	"github.com/joho/godotenv"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

func main() {
	source := flag.String("source", "all", "데이터 소스: mfds | usda | all")
	limit := flag.Int("limit", 5000, "최대 수집 건수")
	dryRun := flag.Bool("dry-run", false, "DB insert 없이 수집 결과만 출력")
	flag.Parse()

	// .env 파일 탐색 (실행 위치에 따라 경로가 달라질 수 있음)
	for _, path := range []string{".env", "../.env", "../../.env"} {
		if err := godotenv.Load(path); err == nil {
			slog.Info(".env 로드 성공", slog.String("path", path))
			break
		}
	}

	db := config.InitDB()
	ctx := context.Background()

	var menus []domain.Menu

	switch *source {
	case "mfds":
		menus = fetchMFDS(ctx, *limit)
	case "usda":
		menus = fetchUSDA(ctx, *limit)
	case "all":
		menus = append(menus, fetchMFDS(ctx, *limit)...)
		menus = append(menus, fetchUSDA(ctx, 500)...)
	default:
		slog.Error("알 수 없는 source", slog.String("source", *source))
		os.Exit(1)
	}

	menus = filterInvalidMenus(menus)
	slog.Info("수집 완료", slog.Int("total", len(menus)))

	if *dryRun {
		for _, m := range menus {
			fmt.Printf("[%s] %s cal=%.0f carbs=%.0f protein=%.0f fat=%.0f\n",
				m.Category, m.Name, m.DefaultCalories, m.DefaultCarbs, m.DefaultProtein, m.DefaultFat)
		}
		return
	}

	inserted, skipped := bulkUpsert(db, menus)
	slog.Info("시딩 완료", slog.Int("inserted", inserted), slog.Int("skipped", skipped))
}

// ─────────────────────────────────────────
// 식약처 (MFDS) I2790 식품영양성분
// ─────────────────────────────────────────

type mfdsResponse struct {
	I2790 struct {
		TotalCount string     `json:"total_count"`
		Row        []mfdsRow  `json:"row"`
		Result     mfdsResult `json:"RESULT"`
	} `json:"I2790"`
}

type mfdsRow struct {
	FoodName  string `json:"FOOD_NM_KR"` // 식품명
	FoodGroup string `json:"FOOD_GROUP"` // 식품군
	Calories  string `json:"AMT_NUM1"`   // 에너지(kcal)
	Carbs     string `json:"AMT_NUM7"`   // 탄수화물(g)
	Protein   string `json:"AMT_NUM3"`   // 단백질(g)
	Fat       string `json:"AMT_NUM4"`   // 지방(g)
	Fiber     string `json:"AMT_NUM22"`  // 식이섬유(g)
	VitaminC  string `json:"AMT_NUM15"`  // 비타민C(mg)
}

type mfdsResult struct {
	Code    string `json:"CODE"`
	Message string `json:"MSG"`
}

func fetchMFDS(ctx context.Context, limit int) []domain.Menu {
	apiKey := os.Getenv("MFDS_API_KEY")
	if apiKey == "" {
		slog.Error("MFDS_API_KEY 환경 변수가 없습니다")
		return nil
	}

	baseURL := "https://openapi.foodsafetykorea.go.kr/api"
	pageSize := 1000
	var allMenus []domain.Menu

	for start := 1; start <= limit; start += pageSize {
		end := start + pageSize - 1
		if end > limit {
			end = limit
		}

		reqURL := fmt.Sprintf("%s/%s/I2790/json/%d/%d", baseURL, apiKey, start, end)
		slog.Info("MFDS 요청", slog.String("url", reqURL), slog.Int("start", start), slog.Int("end", end))

		body, err := httpGet(ctx, reqURL)
		if err != nil {
			slog.Error("MFDS API 요청 실패", slog.Any("error", err))
			break
		}

		var resp mfdsResponse
		if err := json.Unmarshal(body, &resp); err != nil {
			slog.Error("MFDS 응답 파싱 실패", slog.Any("error", err))
			break
		}

		if resp.I2790.Result.Code != "INFO-000" {
			slog.Error("MFDS API 오류", slog.String("code", resp.I2790.Result.Code), slog.String("msg", resp.I2790.Result.Message))
			break
		}

		rows := resp.I2790.Row
		if len(rows) == 0 {
			break
		}

		for _, row := range rows {
			name := strings.TrimSpace(row.FoodName)
			if name == "" {
				continue
			}

			calories := parseFloat(row.Calories)
			carbs := parseFloat(row.Carbs)
			protein := parseFloat(row.Protein)
			fat := parseFloat(row.Fat)
			fiber := parseFloat(row.Fiber)
			vitaminScore := calcVitaminScore(parseFloat(row.VitaminC))

			category := mfdsCategory(row.FoodGroup, name)

			allMenus = append(allMenus, domain.Menu{
				Name:                name,
				Category:            category,
				Source:              domain.SourceMFDS,
				DefaultCalories:     calories,
				DefaultCarbs:        carbs,
				DefaultProtein:      protein,
				DefaultFat:          fat,
				DefaultFiber:        fiber,
				DefaultVitaminScore: vitaminScore,
			})
		}

		slog.Info("MFDS 수집 중", slog.Int("collected", len(allMenus)))
		time.Sleep(300 * time.Millisecond) // API 호출 간격
	}

	return allMenus
}

// ─────────────────────────────────────────
// USDA FoodData Central
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

// USDA nutrientId 기준
const (
	usdaEnergyID  = 1008 // Energy (kcal)
	usdaCarbsID   = 1005 // Carbohydrate
	usdaProteinID = 1003 // Protein
	usdaFatID     = 1004 // Total lipid (fat)
	usdaFiberID   = 1079 // Fiber
	usdaVitCID    = 1162 // Vitamin C
)

// 한국에서 많이 먹는 음식 검색 키워드
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
		slog.Error("USDA_API_KEY 환경 변수가 없습니다")
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
		slog.Info("USDA 요청", slog.String("keyword", keyword))

		body, err := httpGet(ctx, reqURL)
		if err != nil {
			slog.Error("USDA API 요청 실패", slog.String("keyword", keyword), slog.Any("error", err))
			continue
		}

		var resp usdaSearchResponse
		if err := json.Unmarshal(body, &resp); err != nil {
			slog.Error("USDA 응답 파싱 실패", slog.Any("error", err))
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
			category := usdaCategory(food.FoodCategory, name)

			allMenus = append(allMenus, domain.Menu{
				Name:                name,
				Category:            category,
				Source:              domain.SourceUSDA,
				DefaultCalories:     nutrients[usdaEnergyID],
				DefaultCarbs:        nutrients[usdaCarbsID],
				DefaultProtein:      nutrients[usdaProteinID],
				DefaultFat:          nutrients[usdaFatID],
				DefaultFiber:        nutrients[usdaFiberID],
				DefaultVitaminScore: calcVitaminScore(nutrients[usdaVitCID]),
			})
		}

		slog.Info("USDA 수집 중", slog.String("keyword", keyword), slog.Int("total", len(allMenus)))
		time.Sleep(200 * time.Millisecond)
	}

	return allMenus
}

// ─────────────────────────────────────────
// 카테고리 매핑
// ─────────────────────────────────────────

// mfdsCategory 식약처 식품군 → 앱 카테고리
func mfdsCategory(foodGroup, name string) domain.MenuCategory {
	name = strings.ToLower(name)
	group := strings.ToLower(foodGroup)

	// 음료/카페 계열
	cafeKeywords := []string{"커피", "라떼", "음료", "주스", "차", "tea", "coffee", "latte", "beverage"}
	for _, k := range cafeKeywords {
		if strings.Contains(name, k) || strings.Contains(group, k) {
			return domain.CategoryCafe
		}
	}

	// 스낵/과자 계열
	snackKeywords := []string{"과자", "스낵", "빵", "케이크", "쿠키", "아이스크림", "사탕", "초콜릿", "과자류", "제과"}
	for _, k := range snackKeywords {
		if strings.Contains(name, k) || strings.Contains(group, k) {
			return domain.CategorySnack
		}
	}

	// 일식
	japaneseKeywords := []string{"스시", "초밥", "라멘", "우동", "소바", "돈카츠", "야키토리", "타코야키", "오니기리"}
	for _, k := range japaneseKeywords {
		if strings.Contains(name, k) {
			return domain.CategoryJapanese
		}
	}

	// 중식
	chineseKeywords := []string{"짜장", "짬뽕", "탕수육", "마파두부", "볶음밥", "딤섬", "춘권", "팔보채"}
	for _, k := range chineseKeywords {
		if strings.Contains(name, k) {
			return domain.CategoryChinese
		}
	}

	// 양식
	westernKeywords := []string{"파스타", "피자", "스테이크", "햄버거", "샌드위치", "리조또", "그라탕", "오믈렛"}
	for _, k := range westernKeywords {
		if strings.Contains(name, k) {
			return domain.CategoryWestern
		}
	}

	// 한식 (식약처 데이터는 대부분 한식)
	koreanGroups := []string{"밥류", "면류", "국류", "찌개", "반찬", "구이", "김치", "한식"}
	for _, k := range koreanGroups {
		if strings.Contains(group, k) || strings.Contains(name, k) {
			return domain.CategoryKorean
		}
	}

	return domain.CategoryOther
}

// usdaCategory USDA 카테고리 → 앱 카테고리
func usdaCategory(foodCategory, name string) domain.MenuCategory {
	cat := strings.ToLower(foodCategory)
	n := strings.ToLower(name)

	switch {
	case strings.Contains(cat, "coffee") || strings.Contains(cat, "beverage") || strings.Contains(n, "coffee") || strings.Contains(n, "tea") || strings.Contains(n, "latte"):
		return domain.CategoryCafe
	case strings.Contains(cat, "snack") || strings.Contains(cat, "candy") || strings.Contains(cat, "cake") || strings.Contains(cat, "cookie"):
		return domain.CategorySnack
	case strings.Contains(n, "sushi") || strings.Contains(n, "ramen") || strings.Contains(n, "udon") || strings.Contains(n, "tempura"):
		return domain.CategoryJapanese
	case strings.Contains(n, "kimchi") || strings.Contains(n, "bibimbap") || strings.Contains(n, "bulgogi") || strings.Contains(n, "gimbap"):
		return domain.CategoryKorean
	case strings.Contains(n, "pizza") || strings.Contains(n, "pasta") || strings.Contains(n, "hamburger") || strings.Contains(n, "sandwich") || strings.Contains(n, "steak"):
		return domain.CategoryWestern
	case strings.Contains(n, "fried rice") || strings.Contains(n, "dim sum") || strings.Contains(n, "noodle"):
		return domain.CategoryChinese
	default:
		return domain.CategoryOther
	}
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

		// name + category 중복이면 영양소 업데이트 (source가 USER인 건 덮어쓰지 않음)
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
			Where: clause.Where{
				Exprs: []clause.Expression{
					gorm.Expr("menus.source != 'USER'"),
				},
			},
		}).CreateInBatches(batch, batchSize)

		if result.Error != nil {
			slog.Error("DB upsert 실패", slog.Any("error", result.Error))
			continue
		}
		inserted += int(result.RowsAffected)
		skipped += len(batch) - int(result.RowsAffected)
		slog.Info("batch upsert", slog.Int("batch_inserted", int(result.RowsAffected)), slog.Int("progress", end))
	}
	return
}

// ─────────────────────────────────────────
// 데이터 품질 검증
// ─────────────────────────────────────────

func filterInvalidMenus(menus []domain.Menu) []domain.Menu {
	seen := make(map[string]struct{})
	var valid []domain.Menu

	for _, m := range menus {
		// 이름 공백 정리
		m.Name = strings.TrimSpace(m.Name)
		if m.Name == "" {
			continue
		}

		// 중복 제거 (name+category)
		key := string(m.Category) + ":" + m.Name
		if _, exists := seen[key]; exists {
			continue
		}
		seen[key] = struct{}{}

		// 칼로리 0 또는 극단값 필터링
		if m.DefaultCalories <= 0 || m.DefaultCalories > 5000 {
			continue
		}
		// 탄수화물/단백질/지방 합이 너무 비정상적인 경우 (g 기준)
		macroSum := m.DefaultCarbs + m.DefaultProtein + m.DefaultFat
		if macroSum > 500 {
			continue
		}

		valid = append(valid, m)
	}

	slog.Info("품질 검증 완료",
		slog.Int("before", len(menus)),
		slog.Int("after", len(valid)),
		slog.Int("filtered", len(menus)-len(valid)),
	)
	return valid
}

// ─────────────────────────────────────────
// 헬퍼
// ─────────────────────────────────────────

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
		n, err := resp.Body.Read(tmp)
		buf = append(buf, tmp[:n]...)
		if err != nil {
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
	return math.Round(f*10) / 10 // 소수점 1자리
}

func usdaNutrientMap(nutrients []usdaNutrient) map[int]float64 {
	m := make(map[int]float64, len(nutrients))
	for _, n := range nutrients {
		m[n.NutrientID] = n.Value
	}
	return m
}

// calcVitaminScore 비타민C(mg) → 0~100 점수로 환산
// 비타민C 하루 권장량 100mg 기준
func calcVitaminScore(vitaminC float64) float64 {
	score := (vitaminC / 100.0) * 100.0
	if score > 100 {
		score = 100
	}
	return math.Round(score*10) / 10
}
