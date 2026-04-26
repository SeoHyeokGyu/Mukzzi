package config

import (
	"context"
	"log/slog"
	"os"
	"time"

	"github.com/redis/go-redis/v9"
)

// InitRedis 는 Redis 연결을 초기화하고 redis.Client 객체를 반환합니다.
func InitRedis() *redis.Client {
	redisURL := os.Getenv("REDIS_URL")

	opt, err := redis.ParseURL(redisURL)
	if err != nil {
		slog.Error("Redis URL 파싱 실패", slog.Any("error", err), slog.String("url", redisURL))
		os.Exit(1)
	}

	rdb := redis.NewClient(opt)

	// 연결 확인
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err = rdb.Ping(ctx).Result()
	if err != nil {
		slog.Error("Redis 연결 실패", slog.Any("error", err), slog.String("url", redisURL))
		os.Exit(1)
	}

	slog.Info("Redis 연결 성공", slog.String("url", redisURL))
	return rdb
}
