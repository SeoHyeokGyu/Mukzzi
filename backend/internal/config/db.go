package config

import (
	"fmt"
	"log"
	"os"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
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
		log.Fatalf("데이터베이스 연결 실패: %v\n사용한 DSN: %s", err, dsn)
	}

	log.Printf("데이터베이스 연결 성공! (Host: %s, DB: %s)", host, dbName)

	// 오토 마이그레이션
	err = db.AutoMigrate(&domain.User{})
	if err != nil {
		log.Fatalf("마이그레이션 실패: %v", err)
	}

	return db
}
