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
| 언어 | Go 1.26 | 네이티브 컴파일, 경량 바이너리, goroutine 동시성 |
| 프레임워크 | Gin | 경량 HTTP 라우터, 미들웨어 체인, 높은 처리량 |
| ORM | GORM | Go 표준 ORM, 마이그레이션 지원 |
| 스케줄러 | robfig/cron | 패널티 시스템, 푸시 알림 배치 |
| 실시간 | gorilla/websocket | Tier 3 그룹 챌린지·배틀 실시간 처리 |

### Infra

| 항목 | 선택 | 이유 |
|------|------|------|
| 웹 서버 | nginx (frontend 이미지 내장) | Flutter Web 정적 파일 서빙 + 백엔드 API 리버스 프록시를 단일 컨테이너로 통합 |
| 컨테이너 | Docker + Docker Compose | 단일 명령으로 전체 서비스 관리, 환경 일관성 보장 |
| 서버 | Oracle Cloud ARM (A1) | 4 OCPU / 24GB RAM 무료 티어 |
| CI/CD | GitHub Actions | GitHub 저장소 통합, 무료 러너 제공 |
| 푸시 알림 | FCM | iOS/Android 크로스 플랫폼 푸시 지원 |

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

### 소프트웨어 설계 원칙 (Clean Architecture)

도메인 주도 설계(DDD)의 전략적 설계를 통해 비즈니스 경계를 정의하고, 클린 아키텍처의 전술적 설계를 통해 계층 간 책임을 분리합니다. 외부 기술(HTTP, DB)이 핵심 비즈니스 로직에 영향을 주지 않도록 설계하며, Go의 `internal` 패키지 특성을 활용하여 캡슐화를 강화합니다.

#### 프로젝트 구조 가이드 (Layered Clean Architecture)

**Backend (Go)**
- **cmd**: 애플리케이션의 진입점 (main.go)
- **internal**: 외부 모듈에서 임포트가 불가능한 비공개 애플리케이션 레이어 (캡슐화)
  - **domain**: 핵심 데이터 구조(Struct) 및 리포지토리 인터페이스 정의 (의존성 없음)
  - **usecase**: 애플리케이션 비즈니스 규칙 구현 및 흐름 제어 (스프링의 Service 계층)
  - **delivery**: 외부 요청 처리 및 응답 반환 (스프링의 Controller 계층)
  - **repository**: 데이터 저장소 구현체 및 인프라 연동 (스프링의 Repository Impl 계층)

```
backend/
├── cmd/
│   └── api/
│       └── main.go          # 애플리케이션 진입점 (의존성 주입 및 서버 실행)
└── internal/                # 캡슐화된 애플리케이션 레이어
    ├── domain/              # 1. 엔티티 (Entities) 계층
    │   ├── user.go          # 데이터 구조 및 인터페이스 정의
    │   ├── meal.go
    │   ├── character.go
    │   └── error.go         # 도메인 공통 에러 정의
    ├── usecase/             # 2. 유스케이스 (Usecase) 계층
    │   ├── user_usecase.go      # 비즈니스 로직 구현
    │   ├── meal_usecase.go
    │   └── character_usecase.go
    ├── delivery/            # 3. 인터페이스 어댑터 (Delivery) 계층
    │   ├── http/
    │   │   ├── handler/         # HTTP 핸들러 (Controller)
    │   │   ├── middleware/      # 인증 및 공통 미들웨어
    │   │   ├── route/           # 라우팅 설정
    │   │   └── dto/             # Request/Response DTO
    │   └── ws/                # (필요 시 확장)
    └── repository/          # 4. 인프라스트럭처 (Repository) 계층
        ├── postgres/
        │   ├── user_repo.go     # DB 연동 구현체 (GORM)
        │   └── meal_repo.go
        └── redis/
            └── cache_repo.go    # 캐시 연동 구현체
```

**Frontend (Flutter)**
- `lib/src/features/[feature]/` 구조를 사용하여 기능 단위로 코드를 관리합니다.
```
frontend/
  ├── lib/
  │     ├── main.dart
  │     ├── src/
  │     │    ├── features/
  │     │    │    ├── character/    # 캐릭터 관련 UI 및 로직
  │     │    │    │     ├── domain/
  │     │    │    │     ├── data/
  │     │    │    │     └── presentation/
  │     │    │    ├── meal_record/  # 식사 기록 관련
  │     │    │    └── social/       # 소셜 기능 관련
  │     │    ├── core/              # 공통 위젯, 테마, 유틸리티
  │     │    └── router/            # GoRouter 설정
  └── assets/                       # Rive 파일 및 이미지
```

---

## 로컬 개발

### Prerequisites

| Tool | Version |
|------|---------|
| Go | 1.26+ |
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
   frontend (nginx) :80
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
| frontend | ghcr.io/.../frontend:latest | 80 | Flutter Web 정적 서빙 + Reverse proxy |
| backend | ghcr.io/.../backend:latest | 8080 | REST API + WebSocket |
| postgres | postgres:15-alpine | 5432 | Main database |
| redis | redis:7-alpine | 6379 | Cache + session |

### 빌드 플로우

```
Backend:  golang:1.26-alpine -> go build -> alpine
Frontend: flutter:3.24.0 -> flutter build web -> nginx:alpine (정적 파일 + nginx 설정 내장)
```

### nginx 라우팅 (frontend 컨테이너 내장)

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

## 테스트 전략

프로젝트의 안정성과 유지보수성을 위해 계층별 테스트를 수행하며, 모든 테스트는 CI 파이프라인에서 자동 실행됩니다.

### Backend (Go)

| 수준 | 대상 | 도구 | 설명 |
|------|------|------|------|
| 단위 테스트 | domain, usecase | testing, testify | 비즈니스 로직 및 도메인 모델 검증 (Mock 사용) |
| 통합 테스트 | repository | testcontainers-go | 실제 DB(PostgreSQL/Redis) 연동 및 쿼리 검증 |
| API 테스트 | delivery/http | httptest | 엔드포인트 입력 유효성 및 응답 스펙 검증 |

- Mocking: vektra/mockery를 사용하여 인터페이스 기반의 목 객체 자동 생성
- Coverage: 핵심 비즈니스 로직(usecase)에 대해 커버리지 80% 이상 유지 권장

### Frontend (Flutter)

| 수준 | 대상 | 도구 | 설명 |
|------|------|------|------|
| 단위 테스트 | domain, provider | flutter_test | 상태 관리 로직 및 데이터 모델 변환 검증 |
| 위젯 테스트 | widgets | flutter_test | 개별 UI 컴포넌트의 렌더링 및 인터랙션 검증 |
| 통합 테스트 | 전체 앱 시나리오 | integration_test | 실제 기기/에뮬레이터에서 사용자 플로우(E2E) 검증 |

- Golden Tests: golden_toolkit을 사용하여 UI 회귀 테스트 수행
- Mocking: mocktail을 사용하여 외부 API 및 의존성 격리

---

## CI/CD

GitHub Actions + GHCR(GitHub Container Registry) 기반 자동 배포.

워크플로우 파일: `.github/workflows/`

### 전체 플로우

```
push to main
  |
  |-- [항상 실행] discord-notify.yml
  |     Discord 웹훅으로 커밋 알림 전송
  |
  |-- [backend/** 변경 시] backend-deploy.yml
  |     GHCR 이미지 빌드/푸시 -> SSH -> 컨테이너 교체
  |     실패 시 Discord 알림 전송
  |
  |-- [frontend/** 변경 시] frontend-deploy.yml
        GHCR 이미지 빌드/푸시 -> SSH -> 컨테이너 교체
        실패 시 Discord 알림 전송
```

- backend/frontend 워크플로우에 concurrency 설정 적용 (동시 배포 방지, 새 배포 시 이전 배포 취소)

### 워크플로우 상세

#### 1. backend-deploy.yml

- 트리거: main push + `backend/**` 변경
- concurrency: `backend-deploy` (cancel-in-progress)
- 플로우:

```
1. GHCR 로그인
2. Docker 이미지 빌드 (태그: latest + 커밋SHA)
3. GHCR에 이미지 푸시
4. SSH로 서버 접속
5. docker compose pull backend
6. docker compose up -d backend (컨테이너 교체)
7. docker image prune -f (미사용 이미지 정리)
* 실패 시: Discord 알림 전송 (Actions 실행 페이지 링크 포함)
```

#### 2. frontend-deploy.yml

- 트리거: main push + `frontend/**` 변경
- concurrency: `frontend-deploy` (cancel-in-progress)
- 플로우:

```
1. GHCR 로그인
2. Docker 이미지 빌드 (태그: latest + 커밋SHA)
3. GHCR에 이미지 푸시
4. SSH로 서버 접속
5. docker compose pull frontend
6. docker compose up -d frontend (컨테이너 교체)
7. docker image prune -f (미사용 이미지 정리)
* 실패 시: Discord 알림 전송 (Actions 실행 페이지 링크 포함)
```

#### 3. discord-notify.yml

- 트리거: main push (모든 파일)
- 동작: 커밋 메시지, 작성자, 브랜치 정보를 Discord embed로 전송

### 필요 Secrets

| Secret | 용도 |
|--------|------|
| `GITHUB_TOKEN` | GHCR 로그인 (자동 제공) |
| `SSH_HOST` | 배포 서버 IP |
| `SSH_USERNAME` | SSH 접속 유저 |
| `SSH_PRIVATE_KEY` | SSH 인증 키 |
| `DISCORD_WEBHOOK_URL` | Discord 알림 웹훅 URL |

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
