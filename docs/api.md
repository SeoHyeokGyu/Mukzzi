# API 명세

> 상태: 설계 중

백엔드 REST API 엔드포인트 명세입니다. 기획 문서([planning.md](planning.md))와 ERD([erd.md](erd.md))를 기반으로 작성합니다. 상세한 Request/Response 스펙은 Swagger를 참조하세요.

---

## 공통 규칙

- Base URL: /api/v1
- 인증: Bearer JWT (Access Token)
- 응답 형식: JSON (모든 응답은 공통 래퍼로 감싸져 반환됩니다.)
- 요청 형식: JSON (Content-Type: application/json)
- ID 타입: Sonyflake 기반 64비트 정수형 ID를 사용하며, 프론트엔드에서의 정밀도 손실 방지를 위해 JSON 응답 시 문자열(String)로 반환합니다.

### 공통 응답 구조

모든 API 응답은 아래의 공통 래퍼(Wrapper) 구조로 반환됩니다.

#### 1. 공통 응답 필드
- `success` (bool): 요청 처리 성공 여부
- `data` (interface): 성공 시 반환되는 실제 데이터 (객체 또는 리스트)
- `error` (object): 실패 시 반환되는 에러 정보 (성공 시 null 또는 생략)
- `pagination` (object): 목록 조회 시 포함되는 페이징 정보 (단일 조회 시 생략)

#### 2. 성공 응답 예시 (단일 객체)
```json
{
  "success": true,
  "data": {
    "id": "1234567890",
    "nickname": "먹찌"
  }
}
```

#### 3. 성공 응답 예시 (목록/페이징)
```json
{
  "success": true,
  "data": [ ... ],
  "pagination": {
    "total_count": 100,
    "page": 1,
    "limit": 20,
    "has_next": true
  }
}
```

#### 4. 에러 응답 예시
```json
{
  "success": false,
  "error": {
    "code": "USER_NOT_FOUND",
    "message": "해당 사용자를 찾을 수 없습니다.",
    "details": null
  }
}
```

---

## API 엔드포인트 목록

### 1. 인증 및 사용자 (Auth & User)

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | /auth/login/{provider} | 소셜 로그인 및 토큰 발급 |
| POST | /auth/refresh | 토큰 갱신 |
| GET | /users/me | 내 프로필 정보 조회 |
| PATCH | /users/me | 내 프로필 정보 수정 |
| GET | /users/{id}/profile | 타인 프로필 정보 조회 |

### 2. 캐릭터 및 성장 (Character & Mastery)

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | /characters/me | 내 캐릭터 상태 및 외형 조회 |
| GET | /collections/mastery | 메뉴 마스터리 목록 조회 |
| GET | /collections/mastery/{menuId} | 특정 메뉴 마스터리 상세 |

### 3. 식사 기록 및 영양 (Meal & Nutrition)

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | /meals | 식사 기록 등록 (이미지 업로드 및 AI 분석) |
| GET | /meals | 식사 기록 목록 조회 (주간/월간 캘린더 및 리스트 뷰) |
| GET | /meals/{id} | 식사 기록 상세 및 AI 캐릭터 피드백 조회 |
| PATCH | /meals/{id} | 식사 기록 정보 수정 (수동 입력/보정) |
| DELETE | /meals/{id} | 식사 기록 삭제 |
| GET | /nutrition/today | 오늘 섭취 영양 성분 요약 |

### 4. 소셜 및 상호작용 (Social)

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | /friends | 친구 목록 조회 |
| POST | /friends/request | 친구 요청 |
| POST | /friends/requests/{id}/accept | 친구 요청 수락 |
| DELETE | /friends/{id} | 친구 삭제/거절 |
| POST | /users/{id}/nudge | 응원하기 (넛지) |
| GET | /users/{id}/guestbook | 방명록 조회 |
| POST | /users/{id}/guestbook | 방명록 작성 |

### 5. 퀘스트 및 게임 (Quest & Content)

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | /quests | 진행 중인 퀘스트 목록 조회 |
| POST | /quests/{id}/claim | 퀘스트 보상 수령 |
| POST | /games/roulette | 룰렛 결과 기록 |
| POST | /games/worldcup | 월드컵 최종 결과 기록 |

---

## Swagger (자동화)

- 엔드포인트: /swagger/index.html
- 생성 명령: swag init -g cmd/server/main.go -o docs/swagger
