# Infrastructure

## 기술 스택

### Frontend (iOS / Android / Web)

| 항목 | 선택 | 이유 |
|------|------|------|
| 프레임워크 | Flutter 3.24 | 단일 코드베이스로 iOS/Android/Web 동시 개발 |
| 언어 | Dart 3.5 | Flutter 네이티브 언어, Null Safety 기본 지원 |
| 상태관리 | Riverpod | 컴파일 타임 안전성, 의존성 주입 통합 |
| 애니메이션 | Rive | 인터랙티브 벡터 애니메이션, 앱/웹 동일 품질 렌더링 |
| 라우팅 | GoRouter | 선언적 라우팅, 딥링크 지원 |
| HTTP | Dio | 인터셉터, 토큰 갱신 자동화 |
| 반응형 | LayoutBuilder | 모바일/데스크톱 레이아웃 분기, 공통 로직 공유 |

### Backend

| 항목 | 선택 | 이유 |
|------|------|------|
| 언어 | Go 1.23 | 네이티브 컴파일, 경량 바이너리, goroutine 동시성 |
| 프레임워크 | Gin | 경량 HTTP 라우터, 미들웨어 체인, 높은 처리량 |
| ORM | GORM | Go 표준 ORM, 마이그레이션 지원 |
| 스케줄러 | robfig/cron | 패널티 시스템, 푸시 알림 배치 |
| 실시간 | gorilla/websocket | Tier 3 그룹 챌린지·배틀 실시간 처리 |

### Database

| 항목 | 선택 | 이유 |
|------|------|------|
| 메인 DB | PostgreSQL 15+ | 복잡한 영양소·캐릭터 관계 데이터 |
| 캐싱 | Redis 7+ | 자주 검색되는 음식 캐싱, 세션 관리 |
| 파일 저장 | Oracle Object Storage | 음식 사진, 캐릭터 이미지 (무료 티어 포함) |

### AI / 외부 API

| 항목 | 선택 | 티어 |
|------|------|------|
| 음식 사진 인식 | Google Vision API | Tier 2 |
| 영수증 OCR | Naver Clova OCR | Tier 2 |
| 메뉴 추천 AI | OpenAI GPT API | Tier 2 |
| 음식 영양소 DB | 식약처 API + USDA | Tier 1 |

### 인증

| 항목 | 선택 |
|------|------|
| 토큰 | JWT (Access + Refresh) |
| 소셜 | Kakao OAuth 2.0 / Google OAuth / Apple Sign In |

---

## 로컬 개발

### Prerequisites

| Tool | Version |
|------|---------|
| Go | 1.23+ |
| Flutter | 3.24+ |
| Docker Desktop | latest |

### 실행 순서

```bash
# 1. DB / Redis만 Docker로 실행
docker compose up postgres redis -d

# 2. Backend 실행
cd backend
cp ../.env.example ../.env   # 최초 1회
go mod download
go run ./cmd/server

# 3. Frontend 실행
cd frontend
flutter pub get
flutter run -d chrome        # 웹
flutter run -d android       # Android 에뮬레이터
flutter run -d ios           # iOS 시뮬레이터
```

Android 에뮬레이터에서 로컬 백엔드 접근 시 `localhost` 대신 `10.0.2.2` 를 사용합니다.

### 로컬 구성

```
[Flutter (로컬)]  -->  http://localhost:8080/api/*  -->  [Go (로컬)]
                                                               |
                                                    [postgres :5432 (Docker)]
                                                    [redis    :6379 (Docker)]
```

---

## 프로덕션 아키텍처

### 트래픽 흐름

```
Client (Mobile / Browser)
        |
        v
   nginx :80
   /api/*  -->  backend (Go) :8080
   /ws/*   -->  backend (Go) :8080  (WebSocket)
   /       -->  Flutter Web (static)
        |
        v
   PostgreSQL :5432
   Redis      :6379
```

### 서비스 목록

| Service | Image | Port | Role |
|---------|-------|------|------|
| nginx | nginx:alpine | 80 | Reverse proxy + Flutter Web 정적 서빙 |
| backend | ./backend | 8080 | REST API + WebSocket |
| postgres | postgres:15-alpine | 5432 | Main database |
| redis | redis:7-alpine | 6379 | Cache + session |

### Docker Compose 프로파일

| Profile | 실행 서비스 |
|---------|-----------|
| (default) | nginx, backend, postgres, redis |
| web | + frontend (Flutter web 빌드) |

```bash
# 모바일 개발 (기본)
docker compose up --build

# Flutter Web 포함 전체
docker compose --profile web up --build
```

### 빌드 플로우

```
Backend:  golang:1.23-alpine -> go build -> alpine
Frontend: flutter:3.24.0 -> flutter build web -> nginx
```

### nginx 라우팅

```
/       ->  Flutter Web (SPA, index.html fallback)
/api/   ->  backend:8080
/ws/    ->  backend:8080 (WebSocket upgrade)
```

### 서버

- Provider: Oracle Cloud (ARM Ampere A1)
- Spec: 4 OCPU / 24GB RAM (free tier)

---

## 환경 변수

`.env.example` 을 `.env` 로 복사 후 값 입력.

| Variable | Description |
|----------|-------------|
| SERVER_PORT | Go 서버 포트 (default: 8080) |
| DATABASE_URL | PostgreSQL 연결 문자열 |
| REDIS_URL | Redis 연결 문자열 |
| JWT_SECRET | JWT 서명 시크릿 |
| ENVIRONMENT | development / production |
| KAKAO_CLIENT_ID | Kakao OAuth |
| GOOGLE_CLIENT_ID | Google OAuth |
| APPLE_TEAM_ID | Apple Sign In |
| FCM_SERVER_KEY | Firebase Cloud Messaging |
| GOOGLE_VISION_API_KEY | 음식 사진 인식 (Tier 2) |
| NAVER_CLOVA_CLIENT_ID/SECRET | 영수증 OCR (Tier 2) |
| OPENAI_API_KEY | AI 메뉴 추천 (Tier 2) |
| FOOD_SAFETY_API_KEY | 식약처 영양소 DB |
| USDA_API_KEY | USDA 영양소 DB |
| ORACLE_OBJECT_STORAGE_* | 이미지 파일 저장소 |

---

## CI/CD

GitHub Actions — `backend/**` 또는 `frontend/**` 변경 시 자동 배포.

```
push to main
  |
  +-- backend/** 변경 --> 이미지 빌드/푸시 --> SSH --> docker compose up backend
  +-- frontend/** 변경 --> 이미지 빌드/푸시 --> SSH --> docker compose up frontend
```

워크플로우 파일: `.github/workflows/`

---

## 유틸리티

모든 유틸리티는 SSH 터널로만 접근 가능합니다.

```bash
ssh -L 3001:localhost:3001 \
    -L 8888:localhost:8888 \
    -L 8889:localhost:8889 \
    ubuntu@<서버IP>
```

| 서비스 | URL | 용도 |
|--------|-----|------|
| Uptime Kuma | http://localhost:3001 | 서비스 헬스체크 + 장애 알림 |
| Dozzle | http://localhost:8888 | 컨테이너 로그 실시간 조회 |
| Bytebase | http://localhost:8889 | PostgreSQL 관리 + 마이그레이션 |

### Bytebase DB 연결 정보

| 항목 | 값 |
|------|-----|
| Host | `postgres` |
| Port | `5432` |
| Database | `mukzzi` |
| Username | `mukzzi` |
| Password | `mukzzi` |

### Oracle Cloud 유휴 자원 회수 방지

stress-ng 컨테이너가 1코어 x 50% 부하를 상시 유지합니다 (전체 4코어 기준 12.5%).
오라클 회수 기준(CPU 10%)을 초과하여 인스턴스 회수를 방지합니다.
