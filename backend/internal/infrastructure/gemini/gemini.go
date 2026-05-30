package gemini

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"sync"
	"time"

	"google.golang.org/genai"
)

var ErrQuotaExhausted = errors.New("Gemini API의 모든 모델 한도가 초과되었습니다. 잠시 후 다시 시도해주세요.")

type Client struct {
	client             *genai.Client
	model              string
	mu                 sync.RWMutex
	lastQuotaExhausted time.Time
	cooldownDuration   time.Duration
}

func NewClient(apiKey string) (*Client, error) {
	if apiKey == "" {
		return nil, fmt.Errorf("GEMINI_API_KEY is required")
	}

	ctx := context.Background()
	client, err := genai.NewClient(ctx, &genai.ClientConfig{
		APIKey: apiKey,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create gemini client: %w", err)
	}

	return &Client{
		client:           client,
		model:            "gemini-3.5-flash",
		cooldownDuration: 3 * time.Minute, // 3분 동안 쿨다운 적용
	}, nil
}

func (c *Client) generateWithFallback(ctx context.Context, prompt string, isImage bool, imageURL string, req *genai.GenerateContentConfig) (*genai.GenerateContentResponse, error) {
	c.mu.RLock()
	isCoolingDown := !c.lastQuotaExhausted.IsZero() && time.Since(c.lastQuotaExhausted) < c.cooldownDuration
	c.mu.RUnlock()

	if isCoolingDown {
		return nil, ErrQuotaExhausted
	}

	modelsToTry := []string{
		c.model,
		"gemini-3.5-flash",
		"gemini-2.5-flash",
		"gemini-2.0-flash",
	}

	// 중복 모델 제거
	var uniqueModels []string
	seen := make(map[string]bool)
	for _, m := range modelsToTry {
		if !seen[m] {
			seen[m] = true
			uniqueModels = append(uniqueModels, m)
		}
	}

	var lastErr error
	var hasQuotaExhausted bool = true // 모든 시도 모델이 429 한도 초과이면 true 유지

	for _, m := range uniqueModels {
		var res *genai.GenerateContentResponse
		var err error

		if isImage {
			fullPrompt := fmt.Sprintf("이미지 URL: %s\n\n%s", imageURL, prompt)
			res, err = c.client.Models.GenerateContent(ctx, m, genai.Text(fullPrompt), req)
		} else {
			res, err = c.client.Models.GenerateContent(ctx, m, genai.Text(prompt), req)
		}

		if err == nil {
			if m != c.model {
				slog.Info("Gemini API 요청 성공 (하위 모델 사용됨)", slog.String("model", m))
			}
			return res, nil
		}

		errStr := strings.ToLower(err.Error())
		if strings.Contains(errStr, "429") || strings.Contains(errStr, "quota") || strings.Contains(errStr, "exhausted") {
			slog.Warn("Gemini API 한도 초과. 다음 하위 모델로 우회합니다.", slog.String("failed_model", m), slog.Any("error", err))
			lastErr = err
			continue // 다음 모델 시도
		}

		// 한도 초과가 아닌 다른 에러는 즉시 반환 (이때는 쿨다운을 유발하지 않음)
		hasQuotaExhausted = false
		return nil, err
	}

	// 모든 모델이 429 한도 초과로 실패한 경우 쿨다운 상태로 진입
	if hasQuotaExhausted {
		c.mu.Lock()
		c.lastQuotaExhausted = time.Now()
		c.mu.Unlock()
		slog.Error("Gemini API의 모든 모델 한도가 초과되어 쿨다운에 진입합니다.", slog.Duration("cooldown", c.cooldownDuration))
		return nil, ErrQuotaExhausted
	}

	return nil, fmt.Errorf("모든 하위 모델이 실패했습니다: %w", lastErr)
}

func (c *Client) GenerateJSON(ctx context.Context, prompt string) (string, error) {
	ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	req := &genai.GenerateContentConfig{
		ResponseMIMEType: "application/json",
	}

	res, err := c.generateWithFallback(ctx, prompt, false, "", req)
	if err != nil {
		slog.Error("Gemini API GenerateJSON 오류", slog.Any("error", err))
		return "", err
	}

	result := res.Text()
	if result == "" {
		return "", fmt.Errorf("응답 결과가 없습니다")
	}
	return cleanJSONMarkdown(result), nil
}

func cleanJSONMarkdown(jsonStr string) string {
	// 마크다운 json 블록을 제거합니다
	if len(jsonStr) > 7 && jsonStr[:7] == "```json" {
		jsonStr = jsonStr[7:]
	} else if len(jsonStr) > 3 && jsonStr[:3] == "```" {
		jsonStr = jsonStr[3:]
	}
	if len(jsonStr) > 3 && jsonStr[len(jsonStr)-3:] == "```" {
		jsonStr = jsonStr[:len(jsonStr)-3]
	}
	// 양끝 공백 및 줄바꿈 제거
	for len(jsonStr) > 0 && (jsonStr[0] == '\n' || jsonStr[0] == '\r' || jsonStr[0] == ' ') {
		jsonStr = jsonStr[1:]
	}
	for len(jsonStr) > 0 && (jsonStr[len(jsonStr)-1] == '\n' || jsonStr[len(jsonStr)-1] == '\r' || jsonStr[len(jsonStr)-1] == ' ') {
		jsonStr = jsonStr[:len(jsonStr)-1]
	}
	return jsonStr
}

func (c *Client) AnalyzeImageJSON(ctx context.Context, imageURL string, prompt string) (string, error) {
	ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	req := &genai.GenerateContentConfig{
		ResponseMIMEType: "application/json",
	}

	res, err := c.generateWithFallback(ctx, prompt, true, imageURL, req)
	if err != nil {
		slog.Error("Gemini API AnalyzeImage 오류", slog.Any("error", err))
		return "", err
	}

	result := res.Text()
	if result == "" {
		return "", fmt.Errorf("응답 결과가 없습니다")
	}
	return cleanJSONMarkdown(result), nil
}
