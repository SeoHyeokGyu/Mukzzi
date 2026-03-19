# DDD 도메인 설계

> 상태: 설계 예정

기획 문서([planning.md](planning.md))의 기능 정의를 기반으로 바운디드 컨텍스트를 정의하고, 도메인 간 관계를 설계합니다.

---

## 바운디드 컨텍스트 (Bounded Context)

### 컨텍스트 맵 개요

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│     Auth     │────>│     User     │<────│    Social    │
│   (인증)     │     │   (사용자)    │     │   (소셜)     │
└──────────────┘     └──────┬───────┘     └──────────────┘
                            │
                    ┌───────┴───────┐
                    │               │
              ┌─────▼──────┐  ┌────▼───────┐
              │  Character  │  │    Meal    │
              │ (캐릭터/성장)│  │  (식사기록) │
              └─────┬──────┘  └────┬───────┘
                    │               │
              ┌─────▼──────┐  ┌────▼───────┐
              │   Quest    │  │  Nutrition  │
              │  (퀘스트)   │  │  (영양소)   │
              └────────────┘  └────────────┘
                    │
              ┌─────▼──────┐
              │ Collection  │
              │  (도감/뱃지) │
              └────────────┘
```

---

## 컨텍스트별 책임

### Auth (인증)
- 회원가입, 로그인, 토큰 관리
- 소셜 로그인 (Kakao, Google, Apple)
- 핵심 엔티티: `Credential`, `Token`

### User (사용자)
- 프로필 관리, 닉네임, 칭호
- 핵심 엔티티: `User`, `Profile`

### Character (캐릭터/성장)
- 먹찌 생성, 파츠 조합, 진화 단계 관리
- 영양소 비율에 따른 외형 결정
- 핵심 엔티티: `Character`, `Appearance`, `Parts`

### Meal (식사 기록)
- 식사 등록, 수정, 삭제
- 메뉴 검색, 즐겨찾기
- 핵심 엔티티: `MealRecord`, `Menu`, `Favorite`

### Nutrition (영양소)
- 영양소 DB 연동 (USDA, 식약처)
- 섭취 비율 계산, 밸런스 피드백
- 핵심 엔티티: `NutritionInfo`, `DailyIntake`

### Quest (퀘스트)
- 일일/주간/업적 퀘스트 관리
- 보상 지급 (진화, 동작, 배경, 이펙트, 칭호, 악세서리)
- 핵심 엔티티: `Quest`, `QuestProgress`, `Reward`

### Collection (도감/뱃지)
- 먹찌 도감 (외형 컬렉션)
- 먹부림 도감 (메뉴 마스터리)
- 뱃지, 칭호 관리
- 핵심 엔티티: `CharacterCollection`, `MasteryCard`, `Badge`, `Title`

### Social (소셜)
- 친구 검색/추가/삭제
- 추천 사용자
- 응원하기 (Nudge), 방명록 (Guestbook)
- 차단/신고
- 핵심 엔티티: `Friendship`, `Nudge`, `GuestbookEntry`, `Report`

---

## 컨텍스트 간 관계

| 관계 | 상류 (Upstream) | 하류 (Downstream) | 통신 방식 |
|------|----------------|-------------------|----------|
| 식사 기록 -> 퀘스트 갱신 | Meal | Quest | 함수 호출 (동기) |
| 퀘스트 완료 -> 캐릭터 보상 | Quest | Character | 함수 호출 (동기) |
| 식사 기록 -> 영양소 재계산 | Meal | Nutrition | 함수 호출 (동기) |
| 영양소 변화 -> 파츠 재계산 | Nutrition | Character | 함수 호출 (동기) |
| 퀘스트 완료 -> 도감 등록 | Quest | Collection | 함수 호출 (동기) |
| 소셜 응원 -> 알림 | Social | Notification | 함수 호출 (동기) |

> MVP에서는 동기 함수 호출로 구현하고, 고도화 단계에서 도메인 이벤트 기반 비동기 처리로 전환을 검토합니다.

---

## Go 패키지 매핑

```
internal/
├── domain/
│   ├── user.go          # User, Profile
│   ├── character.go     # Character, Appearance, Parts
│   ├── meal.go          # MealRecord, Menu, Favorite
│   ├── nutrition.go     # NutritionInfo, DailyIntake
│   ├── quest.go         # Quest, QuestProgress, Reward
│   ├── collection.go    # CharacterCollection, MasteryCard, Badge, Title
│   ├── social.go        # Friendship, Nudge, GuestbookEntry
│   └── error.go         # 도메인 공통 에러
├── usecase/
│   ├── auth_usecase.go
│   ├── user_usecase.go
│   ├── character_usecase.go
│   ├── meal_usecase.go
│   ├── nutrition_usecase.go
│   ├── quest_usecase.go
│   ├── collection_usecase.go
│   └── social_usecase.go
├── delivery/http/
│   ├── handler/
│   ├── dto/
│   ├── middleware/
│   └── route/
└── repository/
    ├── postgres/
    └── redis/
```

---

## 설계 원칙

1. **domain 패키지는 외부 의존성 없음**: 순수 Go 구조체와 인터페이스만 정의
2. **usecase는 domain 인터페이스에만 의존**: repository 구현체를 직접 참조하지 않음
3. **delivery는 usecase만 호출**: domain을 직접 조작하지 않음
4. **repository는 domain 인터페이스를 구현**: GORM/Redis 구현 상세는 이 계층에 격리
