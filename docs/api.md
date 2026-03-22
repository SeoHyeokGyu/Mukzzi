# API 명세

> 상태: 설계 완료

백엔드 REST API 엔드포인트 명세입니다. 기획 문서([planning.md](planning.md))와 ERD([erd.md](erd.md))를 기반으로 작성합니다. 상세한 Request/Response 스펙은 Swagger를 참조하세요.

---

## 공통 규칙

- Base URL: /api/v1
- 인증: Bearer JWT (Access Token)
- 응답 형식: JSON (모든 응답은 공통 래퍼로 감싸져 반환됩니다.)
- 요청 형식: JSON (Content-Type: application/json)
- ID 타입: Sonyflake 기반 64비트 정수형 ID를 사용하며, 프론트엔드에서의 정밀도 손실 방지를 위해 JSON 응답 시 문자열(String)로 반환합니다.
- 페이지네이션: 목록 API는 cursor 기반 페이지네이션을 기본으로 사용합니다.

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
    "next_cursor": "1234567890",
    "has_next": true,
    "limit": 20
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

### 1. 인증 (Auth)

| Method | Endpoint | 인증 | 설명 |
|--------|----------|------|------|
| POST | /auth/login/{provider} | X | 소셜 로그인 및 토큰 발급 |
| POST | /auth/refresh | X | Access Token 갱신 |
| POST | /auth/logout | O | 로그아웃 (Refresh Token 무효화) |

### 2. 온보딩 (Onboarding)

| Method | Endpoint | 인증 | 설명 |
|--------|----------|------|------|
| POST | /onboarding | O | 온보딩 완료 (신체 정보 + 영양 목표 + 캐릭터 생성을 일괄 처리) |

### 3. 사용자 (User)

| Method | Endpoint | 인증 | 설명 |
|--------|----------|------|------|
| GET | /users/me | O | 내 프로필 정보 조회 |
| PATCH | /users/me | O | 내 프로필 정보 수정 (닉네임, 이미지 등) |
| PATCH | /users/me/body | O | 신체 정보 수정 (키, 몸무게, 활동량) |
| PATCH | /users/me/nutrition-goal | O | 영양 목표 재설정 (목표 변경 + 권장 섭취량 재계산) |
| PATCH | /users/me/settings | O | 설정 변경 (알림 on/off, 프라이버시 레벨) |
| DELETE | /users/me | O | 회원 탈퇴 |
| GET | /users/{id}/profile | O | 타인 프로필 정보 조회 |
| GET | /users/search | O | 사용자 검색 (query: 닉네임 또는 고유 ID) |
| GET | /users/recommendations | O | 추천 사용자 목록 (비슷한 식습관/먹찌/인기) |

### 4. 캐릭터 (Character)

| Method | Endpoint | 인증 | 설명 |
|--------|----------|------|------|
| GET | /characters/me | O | 내 캐릭터 상태 및 외형 조회 |
| PATCH | /characters/me/appearance | O | 외형 변경 (도감에서 이전 외형 적용) |
| PATCH | /characters/me/equipment | O | 배경/악세서리 장착 변경 |

### 5. 메뉴 (Menu)

| Method | Endpoint | 인증 | 설명 |
|--------|----------|------|------|
| GET | /menus/search | O | 메뉴 검색 (query: 메뉴명, category 필터) |
| POST | /menus/roulette | O | 룰렛 실행 및 결과 반환 (추천 메뉴 선정) |
| GET | /menus/recommendations | O | 선호도 기반 추천 목록 |
| GET | /menus/filter | O | 상황별 필터 추천 (weather, mood 파라미터) |
| GET | /menus/favorites | O | 즐겨찾기 목록 조회 |
| POST | /menus/{id}/favorite | O | 즐겨찾기 추가 |
| DELETE | /menus/{id}/favorite | O | 즐겨찾기 제거 |
| POST | /menus/{id}/preference | O | 좋아요/싫어요 설정 |

### 6. 식사 기록 및 영양 (Meal & Nutrition)

| Method | Endpoint | 인증 | 설명 |
|--------|----------|------|------|
| POST | /meals | O | 식사 기록 등록 (친구 태그 포함 가능) |
| GET | /meals | O | 식사 기록 목록 조회 (주간/월간 캘린더 및 리스트 뷰) |
| GET | /meals/{id} | O | 식사 기록 상세 조회 |
| PATCH | /meals/{id} | O | 식사 기록 정보 수정 |
| DELETE | /meals/{id} | O | 식사 기록 삭제 |
| POST | /meals/{id}/tags/{tagId}/accept | O | 식사 친구 태그 수락 |
| GET | /nutrition/today | O | 오늘 섭취 영양 성분 요약 |
| GET | /nutrition/weekly | O | 주간 영양 성분 요약 및 트렌드 |

#### POST /meals 응답 상세

식사 기록 등록 성공 시, 후속 처리 결과를 `side_effects` 필드로 함께 반환하여 프론트엔드에서 즉각적인 피드백 UI를 구성할 수 있도록 합니다. 후속 처리는 동기로 수행되며, 비동기 작업(영양소 재계산, 알림)의 결과는 포함하지 않습니다.

```json
{
  "success": true,
  "data": {
    "meal": { "id": "123", "menu_name": "김치찌개", ... },
    "side_effects": {
      "quests_progressed": [
        { "quest_type": "DAILY_MEAL", "progress": 1, "target": 1, "completed": true }
      ],
      "mastery_updated": {
        "menu_name": "김치찌개",
        "eat_count": 5,
        "grade": "MANIA",
        "grade_changed": true
      },
      "exp_gained": 10,
      "level_up": null
    }
  }
}
```

#### GET /nutrition/today 응답 상세

영양소 재계산이 비동기로 처리되므로, 마지막 계산 시각을 포함하여 프론트엔드에서 "계산 중" 상태를 판단할 수 있도록 합니다.

```json
{
  "success": true,
  "data": {
    "date": "2026-03-23",
    "total_calories": 1200.0,
    "total_carbs": 150.0,
    "...": "...",
    "meal_count": 2,
    "last_calculated_at": "2026-03-23T12:30:00+09:00"
  }
}
```

### 7. 퀘스트 (Quest)

| Method | Endpoint | 인증 | 설명 |
|--------|----------|------|------|
| GET | /quests | O | 진행 중인 퀘스트 목록 조회 (period 필터: DAILY/WEEKLY/ACHIEVEMENT) |
| POST | /quests/{id}/claim | O | 퀘스트 보상 수령 |

### 8. 컬렉션 (Collection)

| Method | Endpoint | 인증 | 설명 |
|--------|----------|------|------|
| GET | /collections/characters | O | 먹찌 도감 (달성한 외형 컬렉션) |
| GET | /collections/mastery | O | 먹부림 도감 (메뉴 마스터리 목록) |
| GET | /collections/mastery/{menuId} | O | 특정 메뉴 마스터리 상세 |
| GET | /collections/badges | O | 뱃지 목록 (획득/미획득 포함) |
| GET | /collections/titles | O | 칭호 목록 (획득/미획득 포함) |
| PATCH | /collections/titles/equip | O | 칭호 장착/해제 |
| GET | /collections/rewards | O | 보상 아이템 목록 (배경/이펙트/동작/악세서리) |

### 9. 소셜 - 친구 (Friend)

| Method | Endpoint | 인증 | 설명 |
|--------|----------|------|------|
| GET | /friends | O | 친구 목록 조회 |
| GET | /friends/requests | O | 받은 친구 요청 목록 |
| POST | /friends/requests | O | 친구 요청 전송 |
| POST | /friends/requests/{id}/accept | O | 친구 요청 수락 |
| POST | /friends/requests/{id}/reject | O | 친구 요청 거절 |
| DELETE | /friends/{id} | O | 친구 삭제 |

### 10. 소셜 - 상호작용 (Social Interaction)

| Method | Endpoint | 인증 | 설명 |
|--------|----------|------|------|
| POST | /users/{id}/nudge | O | 응원하기 (1일 1회 제한) |
| GET | /users/{id}/guestbook | O | 방명록 조회 |
| POST | /users/{id}/guestbook | O | 방명록 작성 |
| POST | /users/{id}/block | O | 사용자 차단 |
| DELETE | /users/{id}/block | O | 차단 해제 |
| POST | /users/{id}/report | O | 사용자 신고 |

### 11. 알림 (Notification)

| Method | Endpoint | 인증 | 설명 |
|--------|----------|------|------|
| GET | /notifications | O | 알림 목록 조회 (cursor 기반 페이지네이션) |
| PATCH | /notifications/{id}/read | O | 알림 읽음 처리 |
| POST | /notifications/read-all | O | 전체 알림 읽음 처리 |

---

## Rate Limiting

| 대상 | 제한 | 비고 |
|------|------|------|
| 일반 API | 60 req/min | 사용자별 |
| 인증 API (login/refresh) | 10 req/min | IP별 |
| 친구 요청 | 20 req/day | 사용자별 |
| 응원하기 | 같은 친구에게 1회/일 | 사용자별 |
| 신고 | 같은 대상 1회/일 | 사용자별 |

---

## Swagger (자동화)

- 엔드포인트: /swagger/index.html
- 생성 명령: `swag init -g cmd/api/main.go -o docs/swagger`
