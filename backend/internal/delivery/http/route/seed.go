package route

import (
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/handler"
	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/delivery/http/middleware"
	"github.com/gin-gonic/gin"
)

// SeedRoute 관리자 전용 라우트 등록
// 모든 엔드포인트는 JWT 인증 + 관리자 권한 미들웨어로 보호됩니다.
func SeedRoute(rg *gin.RouterGroup, seedHandler *handler.SeedHandler) {
	admin := rg.Group("/admin")
	{
		admin.Use(middleware.AuthMiddleware())
		admin.Use(middleware.AdminOnlyMiddleware())

		// 메뉴 영양소 데이터 수집
		admin.POST("/menus/seed", seedHandler.SeedMenus)
		admin.GET("/menus/seed/status", seedHandler.GetSeedStatus)

		// Redis 자동완성 동기화
		admin.POST("/menus/sync-redis", seedHandler.SyncMenusToRedis)

		// 스케줄 관리
		admin.GET("/schedules", seedHandler.ListSchedules)
		admin.PATCH("/schedules/:key/toggle", seedHandler.ToggleSchedule)
		admin.POST("/schedules/:key/run", seedHandler.RunScheduleNow)
	}
}
