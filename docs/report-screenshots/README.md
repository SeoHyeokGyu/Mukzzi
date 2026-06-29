# 보고용 화면 스크린샷

캡쳐 환경: Flutter Web (canvaskit) `http://localhost` · 뷰포트 390×844 (모바일) · 2x · 계정 `admin`

| 파일 | 화면 | 기능 |
|------|------|------|
| 01-home.png | 홈 | 먹찌, 오늘의 영양, 연속 기록, 메뉴결정 진입 |
| 01a-home-nutrition.png | 홈 · 오늘의 영양 | 칼로리 도넛 + 탄·단·지 매크로 |
| 01b-home-weekly-trend.png | 홈 · 주간 영양 트렌드 | 7일 매크로 바 + 칼로리 라인 차트 |
| 01c-home-menu-decision.png | 홈 · 메뉴 결정 | 룰렛/상황별 필터/취향 추천 + 오늘 먹은 것 |
| 01d-home-ai-recommend.png | 홈 · AI 기능 | Gemini AI 영양 코칭 + 식단 추천 |
| 02-home-quests.png | 퀘스트 | 일일/주간 퀘스트 |
| 03-meal-record.png | 식사 기록 | 끼니 기록 입력/조회 |
| 04-meal-calendar.png | 먹부림 캘린더 | 월별 기록 + 요약 (기록일/총끼니/평균) |
| 05-meal-masteries.png | 식사 숙련도 | 음식 카테고리 숙련 |
| 06-character.png | 먹찌 캐릭터 | 상태, 영양 달성, 장착 파츠 |
| 07-character-collection.png | 도감 | 파츠/먹찌 컬렉션 |
| 08-character-equipment.png | 장비 관리 | 칭호/배경/얼굴 장착 |
| 09-character-rewards.png | 캐릭터 보상 | 성장 보상 |
| 10-social.png | 소셜 | 친구 피드 |
| 11-social-friends.png | 친구 목록 | 친구 관리 |
| 12-social-other-profile.png | 친구 프로필 | 타 유저 먹찌 상태 |
| 13-social-guestbook.png | 방명록 | 친구 방명록 |
| 14-social-friend-room.png | 친구 방 | 친구 먹찌 방 방문 |
| 15-profile.png | 프로필 | 내 정보 |
| 16-profile-badges.png | 배지 | 획득 배지 |
| 17-profile-titles.png | 칭호 | 획득 칭호 |
| 18-profile-rewards.png | 프로필 보상 | 리워드 |
| 19-profile-edit.png | 프로필 편집 | 닉네임/이미지 수정 |
| 20-profile-settings.png | 설정 | 환경설정 |
| 21-settings-privacy.png | 개인정보 처리방침 | 약관 |
| 22-settings-terms.png | 이용약관 | 약관 |
| 23-settings-admin.png | 관리자 | 영양소 수집/스케줄(cron) 관리 |
| 24-notifications.png | 알림 | 알림 목록 |

캡쳐 방법: 백엔드 `/auth/login`으로 JWT 발급 → `localStorage["flutter.access_token/refresh_token"]` 주입 → go_router 해시 라우트(`/#/...`) deep-link → Playwright 스크린샷.
