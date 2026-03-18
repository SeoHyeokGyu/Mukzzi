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

### 소프트웨어 설계 원칙 (DDD)

도메인 주도 설계(DDD)를 적용하여 비즈니스 로직을 바운디드 컨텍스트(Bounded Context) 단위로 분리합니다.

| 분류 | 컨텍스트 | 설명 | 주요 엔티티/VO |
|------|----------|------|----------------|
| Core | 캐릭터 (Character) | 먹찌 성장 및 상태 관리 | 먹찌, 파츠, 진화단계, 패널티상태 |
| Core | 식사 기록 (Meal Record) | 식사 기록 및 영양 분석 | 식사기록, 영양소정보, 섭취량 |
| Supporting | 메뉴 결정 (Recommendation) | 메뉴 결정 전략 및 엔진 | 추천전략, 필터조건, 메뉴풀 |
| Supporting | 게이미피케이션 (Gamification) | 퀘스트 및 보상 시스템 | 퀘스트, 업적, 보상, 뱃지 |
| Supporting | 소셜 (Social) | 사용자 간 소셜 상호작용 | 친구, 응원, 방명록 |
| Generic | 인증 (Identity) | 인증 및 계정 관리 | 사용자, 계정, 토큰 |

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
