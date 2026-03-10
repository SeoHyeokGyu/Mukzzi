# Infrastructure

## Local Development

### Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Go | 1.23+ | https://go.dev/dl |
| Flutter | 3.24+ | https://docs.flutter.dev/get-started/install |
| Docker Desktop | latest | https://www.docker.com/products/docker-desktop |

### 1. DB / Redis 만 Docker로 실행

로컬 개발 시 백엔드와 프론트엔드는 직접 실행하고, DB와 Redis만 Docker로 띄웁니다.

```bash
docker compose up postgres redis -d
```

### 2. Backend 실행

```bash
cd backend
cp ../.env.example ../.env   # 최초 1회
go mod download
go run ./cmd/server
```

백엔드는 `http://localhost:8080` 에서 실행됩니다.

### 3. Frontend 실행

```bash
cd frontend
flutter pub get

flutter run -d chrome        # 웹 (백엔드 http://localhost:8080 직접 통신)
flutter run -d android       # Android 에뮬레이터
flutter run -d ios           # iOS 시뮬레이터
```

Android 에뮬레이터에서 로컬 백엔드 접근 시 `localhost` 대신 `10.0.2.2` 를 사용합니다.

### 로컬 환경 구성 요약

```
[Flutter (로컬)]  -->  http://localhost:8080/api/*  -->  [Go (로컬)]
                                                               |
                                                    [postgres :5432 (Docker)]
                                                    [redis    :6379 (Docker)]
```

---

## Overview

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

## Services

| Service | Image | Port | Role |
|---------|-------|------|------|
| nginx | nginx:alpine | 80 | Reverse proxy + Flutter Web static serving |
| backend | ./backend (Go 1.23) | 8080 | REST API + WebSocket |
| postgres | postgres:15-alpine | 5432 | Main database |
| redis | redis:7-alpine | 6379 | Cache + session |

## Directory Structure

```
Mukzzi/
  backend/
    Dockerfile          # Multi-stage build (golang:1.23-alpine -> alpine)
  frontend/
    Dockerfile          # Flutter web build -> nginx image
  nginx/
    nginx.conf          # Proxy rules
  docker-compose.yml
  .env.example
```

## Docker Compose Profiles

| Profile | Services Started |
|---------|-----------------|
| (default) | nginx, backend, postgres, redis |
| web | + frontend (Flutter web build) |

```bash
# Backend + DB only (mobile dev)
docker compose up --build

# Full stack including Flutter web
docker compose --profile web up --build
```

## Build Flow

### Backend
```
golang:1.23-alpine  ->  go mod download  ->  go build  ->  alpine (final image)
```

### Frontend (Web)
```
flutter:3.24.0  ->  flutter pub get  ->  flutter build web  ->  nginx (final image)
```
Built output is stored in the `flutter_web` named volume, which nginx mounts as read-only.

## nginx Routing

```nginx
/         ->  /usr/share/nginx/html  (Flutter Web, SPA fallback: try_files -> index.html)
/api/     ->  http://backend:8080
/ws/      ->  http://backend:8080  (WebSocket upgrade)
```

## Environment Variables

Copy `.env.example` to `.env` and fill in values before running.

| Variable | Description |
|----------|-------------|
| SERVER_PORT | Go server port (default: 8080) |
| DATABASE_URL | PostgreSQL connection string |
| REDIS_URL | Redis connection string |
| JWT_SECRET | JWT signing secret |
| ENVIRONMENT | development / production |
| KAKAO_CLIENT_ID | Kakao OAuth |
| GOOGLE_CLIENT_ID | Google OAuth |
| APPLE_TEAM_ID | Apple Sign In |
| FCM_SERVER_KEY | Firebase Cloud Messaging |
| GOOGLE_VISION_API_KEY | Food photo recognition (Tier 2) |
| NAVER_CLOVA_CLIENT_ID/SECRET | Receipt OCR (Tier 2) |
| OPENAI_API_KEY | Menu recommendation AI (Tier 2) |
| FOOD_SAFETY_API_KEY | Korea Food Safety DB |
| USDA_API_KEY | USDA nutrition DB |
| ORACLE_OBJECT_STORAGE_* | Object storage for images |

## Server

- Provider: Oracle Cloud (ARM Ampere A1)
- Spec: 4 OCPU / 24GB RAM (free tier)
- Runtime: Docker + Docker Compose

## CI/CD

GitHub Actions pipeline: build -> push image -> deploy to server.
See `.github/workflows/` for workflow definitions.
