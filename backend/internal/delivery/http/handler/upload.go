package handler

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

type UploadHandler struct{}

func NewUploadHandler() *UploadHandler {
	return &UploadHandler{}
}

// UploadImage godoc
// @Summary      이미지 업로드
// @Description  이미지 파일을 서버 로컬 디렉토리에 업로드하고 접근 가능한 URL을 반환합니다.
// @Tags         Upload
// @Accept       multipart/form-data
// @Produce      json
// @Param        file formData file true "업로드할 이미지 파일"
// @Success      200 {object} Response{data=string}
// @Failure      400 {object} Response
// @Failure      500 {object} Response
// @Security     BearerAuth
// @Router       /api/upload/image [post]
func (h *UploadHandler) UploadImage(c *gin.Context) {
	file, err := c.FormFile("file")
	if err != nil {
		BadRequest(c, "INVALID_FILE", "파일을 찾을 수 없습니다.", err.Error())
		return
	}

	// 저장할 디렉토리 설정 (기본적으로 프로젝트 루트의 uploads 폴더)
	uploadDir := "uploads"
	if err := os.MkdirAll(uploadDir, os.ModePerm); err != nil {
		InternalError(c, "서버 오류로 디렉토리를 생성할 수 없습니다.", err.Error())
		return
	}

	// 유니크한 파일명 생성
	ext := filepath.Ext(file.Filename)
	filename := fmt.Sprintf("%d_%s%s", time.Now().UnixNano(), "image", ext)
	dst := filepath.Join(uploadDir, filename)

	if err := c.SaveUploadedFile(file, dst); err != nil {
		InternalError(c, "파일 저장에 실패했습니다.", err.Error())
		return
	}

	// 개발 환경 로컬 URL 생성 (호스트 동적 구성)
	// 실제 환경에서는 S3 URL이나 도메인이 들어가야 함.
	scheme := "http"
	if c.Request.TLS != nil || c.GetHeader("X-Forwarded-Proto") == "https" {
		scheme = "https"
	}
	host := c.Request.Host
	if strings.Contains(host, "localhost") {
		// 로컬 모바일 에뮬레이터에서 접근 가능하게 하려면 호스트 설정이 필요할 수 있음.
		// 일단 기본 host 사용
	}

	imageURL := fmt.Sprintf("%s://%s/uploads/%s", scheme, host, filename)

	Success(c, imageURL)
}
