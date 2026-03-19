# API 명세

> 상태: 설계 예정

백엔드 REST API 엔드포인트 명세입니다. 기획 문서([planning.md](planning.md))의 기능 정의와 ERD([erd.md](erd.md))를 기반으로 작성합니다.

---

## 공통 규칙

- Base URL: `/api/v1`
- 인증: Bearer JWT (Access Token)
- 응답 형식: JSON
- 에러 응답 구조:
  ```json
  {
    "error": {
      "code": "ERROR_CODE",
      "message": "사람이 읽을 수 있는 메시지"
    }
  }
  ```

---

## 인증 (Auth)

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/api/v1/auth/signup` | 회원가입 |
| POST | `/api/v1/auth/login` | 로그인 |
| POST | `/api/v1/auth/refresh` | 토큰 갱신 |
| POST | `/api/v1/auth/oauth/{provider}` | 소셜 로그인 (kakao/google/apple) |

---

## 사용자 (User)

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/api/v1/users/me` | 내 프로필 조회 |
| PATCH | `/api/v1/users/me` | 프로필 수정 |
| GET | `/api/v1/users/{id}/profile` | 타인 프로필 조회 |

---

## 캐릭터 (Character)

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/api/v1/characters` | 먹찌 생성 |
| GET | `/api/v1/characters/me` | 내 먹찌 조회 |
| PATCH | `/api/v1/characters/me/appearance` | 외형 변경 (도감 내 이전 외형) |

---

## 식사 기록 (Meal Record)

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/api/v1/meals` | 식사 기록 등록 |
| GET | `/api/v1/meals` | 식사 기록 목록 조회 (날짜 필터) |
| GET | `/api/v1/meals/{id}` | 식사 기록 상세 조회 |
| DELETE | `/api/v1/meals/{id}` | 식사 기록 삭제 |

---

## 메뉴 (Menu)

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/api/v1/menus/search` | 메뉴 검색 (영양소 DB 연동) |
| GET | `/api/v1/menus/roulette` | 랜덤 룰렛 메뉴 추천 |
| GET | `/api/v1/menus/recommend` | 선호도 기반 추천 |
| GET | `/api/v1/menus/filter` | 상황별 필터 추천 |
| POST | `/api/v1/menus/favorites` | 즐겨찾기 추가 |
| DELETE | `/api/v1/menus/favorites/{menuId}` | 즐겨찾기 삭제 |
| POST | `/api/v1/menus/{id}/preference` | 좋아요/싫어요 입력 |

---

## 퀘스트 (Quest)

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/api/v1/quests/daily` | 일일 퀘스트 목록 |
| GET | `/api/v1/quests/weekly` | 주간 퀘스트 목록 |
| GET | `/api/v1/quests/achievements` | 업적 퀘스트 목록 |
| POST | `/api/v1/quests/{id}/claim` | 퀘스트 보상 수령 |

---

## 영양 (Nutrition)

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/api/v1/nutrition/summary` | 영양소 섭취 요약 (기간별) |
| GET | `/api/v1/nutrition/balance` | 영양 밸런스 피드백 |

---

## 도감 (Collection)

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/api/v1/collections/character` | 먹찌 도감 (외형 컬렉션) |
| GET | `/api/v1/collections/mastery` | 먹부림 도감 (메뉴 마스터리) |
| GET | `/api/v1/collections/mastery/{menuId}` | 특정 메뉴 마스터리 상세 |
| GET | `/api/v1/collections/badges` | 뱃지 목록 |
| GET | `/api/v1/collections/titles` | 칭호 목록 |
| PATCH | `/api/v1/collections/titles/equip` | 칭호 장착 |

---

## 캘린더 (Calendar)

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/api/v1/calendar/{year}/{month}` | 월간 캘린더 조회 |
| GET | `/api/v1/calendar/{year}/{month}/{day}` | 일간 상세 조회 |

---

## 소셜 (Social)

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/api/v1/friends` | 친구 목록 |
| GET | `/api/v1/friends/search` | 친구 검색 |
| GET | `/api/v1/friends/recommendations` | 추천 사용자 목록 |
| POST | `/api/v1/friends/requests` | 친구 요청 전송 |
| POST | `/api/v1/friends/requests/{id}/accept` | 친구 요청 수락 |
| DELETE | `/api/v1/friends/{id}` | 친구 삭제 |
| POST | `/api/v1/friends/{id}/nudge` | 응원하기 (Nudge) |
| GET | `/api/v1/users/{id}/guestbook` | 방명록 조회 |
| POST | `/api/v1/users/{id}/guestbook` | 방명록 작성 |
| POST | `/api/v1/users/{id}/block` | 차단 |
| POST | `/api/v1/users/{id}/report` | 신고 |

---

## 알림 (Notification)

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/api/v1/notifications` | 알림 목록 조회 |
| PATCH | `/api/v1/notifications/{id}/read` | 알림 읽음 처리 |
| PATCH | `/api/v1/notifications/settings` | 알림 설정 변경 |

---

## 요청/응답 DTO 상세

<!-- TODO: 각 엔드포인트별 Request Body, Response Body, Query Parameter 상세 정의 -->

엔드포인트별 DTO 상세는 ERD 확정 후 작성합니다.
