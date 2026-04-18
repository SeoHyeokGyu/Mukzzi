package config

import (
	"fmt"
	"log/slog"
	"os"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// InitDB 는 데이터베이스 연결을 초기화하고 GORM DB 객체를 반환합니다.
func InitDB() *gorm.DB {
	user := os.Getenv("POSTGRES_USER")
	password := os.Getenv("POSTGRES_PASSWORD")
	dbName := os.Getenv("POSTGRES_DB")
	host := os.Getenv("POSTGRES_HOST")
	port := os.Getenv("POSTGRES_PORT")

	// GORM DSN 구성
	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable TimeZone=Asia/Seoul",
		host, user, password, dbName, port)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		slog.Error("데이터베이스 연결 실패", slog.Any("error", err), slog.String("dsn", dsn))
		os.Exit(1)
	}

	slog.Info("데이터베이스 연결 성공", slog.String("host", host), slog.String("db", dbName))

	//// 오토 마이그레이션
	//err = db.AutoMigrate(
	//	&domain.User{},
	//	&domain.Badge{},
	//	&domain.UserBadge{},
	//	&domain.Menu{},
	//)
	//if err != nil {
	//	slog.Error("마이그레이션 실패", slog.Any("error", err))
	//	os.Exit(1)
	//}

	return db
}
