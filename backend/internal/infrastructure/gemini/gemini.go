package gemini

import (
	"context"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"google.golang.org/genai"
)

type Client struct {
	client *genai.Client
	model  string
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
		client: client,
		model:  "gemini-3.5-flash",
	}, nil
}

func (c *Client) generateWithFallback(ctx context.Context, prompt string, isImage bool, imageURL string, req *genai.GenerateContentConfig) (*genai.GenerateContentResponse, error) {
	modelsToTry := []string{
		c.model,
		"gemini-3.5-flash",
		"gemini-2.5-flash",
		"gemini-2.0-flash",
		"gemini-1.5-flash",
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

		// 한도 초과가 아닌 다른 에러는 즉시 반환
		return nil, err
	}

	return nil, fmt.Errorf("모든 하위 모델이 한도 초과로 실패했습니다: %w", lastErr)
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
