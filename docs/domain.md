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

## 공통 도메인 설계 (Base Domain)

모든 도메인 엔티티는 분산 환경에서의 고유 ID 생성을 위해 sonyflake를 활용하는 BaseDomain을 상속(Embedding)받아 사용합니다. PostgreSQL의 BIGINT 타입과 호환되도록 int64 형식을 사용합니다.

### BaseDomain 구조

```go
type BaseDomain struct {
    ID        int64          `gorm:"primaryKey;autoIncrement:false;type:bigint"`
    CreatedAt time.Time      `gorm:"autoCreateTime;not null"`
    UpdatedAt time.Time      `gorm:"autoUpdateTime;not null"`
    DeletedAt gorm.DeletedAt `gorm:"index"`
}
```

### ID 생성 전략 (Sonyflake)
- 방식: 64비트 정수형 ID 생성 (Sonyflake 기반)
- 장점: 시간 순서 보장, 분산 환경에서 충돌 방지, 고성능, PostgreSQL BIGINT 최적화
- 설정: Machine ID는 서버 기동 시 환경 변수(NODE_ID) 또는 K8S Pod ID를 활용하여 할당하며, GORM의 BeforeCreate Hook을 통해 자동으로 할당(ID 캐스팅 처리)됩니다.

---

## 컨텍스트별 책임 및 핵심 엔티티 상세

### Auth (인증)
- 책임: 회원가입, 로그인, 토큰 관리, 소셜 로그인 연동
- 핵심 엔티티: Credential, Token
- 비즈니스 규칙:
  - JWT 토큰은 짧은 주기의 Access Token과 긴 주기의 Refresh Token으로 이원화하여 관리함.

### User (사용자)
- 책임: 프로필 관리, 닉네임, 칭호, 재화 관리, 개인별 영양 목표 설정 및 온보딩
- 핵심 엔티티: User, Profile
- 비즈니스 규칙:
  - 닉네임은 2~12자 사이여야 하며, 특수문자를 제한함.
  - 신규 가입자는 온보딩 과정을 통해 키, 몸무게, 활동량 및 다이어트/유지/벌크업 목표를 설정하여 일일 권장 섭취량을 산출함.
  - 보유 포인트(방울)는 캐릭터 성장 보상이나 퀘스트 완료 시 지급됨.

### Character (캐릭터/성장)
- 책임: 먹찌 생성, 파츠 조합, 진화 단계 관리, 영양 성분에 따른 외형 변화
- 핵심 엔티티: Character, Appearance, Parts
- 비즈니스 규칙:
  - 설정된 권장 섭취량 목표 대비 실제 섭취 비율(7일 평균)에 따라 캐릭터의 외형 상태가 결정됨.
  - 외형 상태 태그: 정상, 과체중(에너지 과잉), 근육질(단백질 위주), 저체중(에너지 부족) 등으로 구분되어 시각화됨.
  - 특정 레벨 도달 시 캐릭터 외형의 진화 단계가 전환됨.

### Meal (식사 기록)
- 책임: 식사 등록/수정/삭제, 메뉴 검색, 즐겨찾기, 영수증 연동, 식사 타임라인 및 캘린더 관리, AI 캐릭터 피드백 생성
- 핵심 엔티티: MealRecord, Menu, Favorite
- 비즈니스 규칙:
  - 식사 기록 시 사진과 시간 정보를 필수로 포함하며, 영수증 OCR을 통한 정보 보정을 지원함.
  - AI 분석이 실패하거나 부정확할 경우 사용자가 직접 메뉴명과 영양 정보를 수동으로 입력하거나 수정할 수 있음.
  - 식사 기록 완료 시 현재 영양 상태와 캐릭터 성격을 반영한 AI 캐릭터의 한 줄 코멘트가 생성됨.
  - 사용자는 주간/월간 단위의 캘린더 뷰를 통해 과거 식사 기록과 영양 요약 정보를 조회할 수 있음.

### Nutrition (영양소)
- 책임: 영양소 DB 연동, 섭취 비율 계산, 밸런스 피드백
- 핵심 엔티티: NutritionInfo, DailyIntake
- 비즈니스 규칙:
  - 일일 섭취량 통계는 매일 00시에 초기화되나, 캐릭터 성장을 위한 누적 통계는 별도로 관리함.

### Quest (퀘스트)
- 책임: 일일/주간/업적 퀘스트 관리, 보상 지급
- 핵심 엔티티: Quest, QuestProgress, Reward
- 비즈니스 규칙:
  - 퀘스트 완료 후 보상 수령 버튼을 눌러야만 실제 재화 및 경험치가 지급됨.

### Collection (도감/뱃지)
- 책임: 먹찌 도감, 메뉴 마스터리, 뱃지, 칭호 관리
- 핵심 엔티티: CharacterCollection, MasteryCard, Badge, Title
- 비즈니스 규칙:
  - 특정 메뉴를 일정 횟수 이상 섭취 시 해당 메뉴에 대한 마스터리 레벨이 상승함.

### Social (소셜)
- 책임: 친구 관리, 추천 사용자, 응원하기(Nudge), 방명록, 차단/신고
- 핵심 엔티티: Friendship, Nudge, GuestbookEntry, Report
- 비즈니스 규칙:
  - 친구 요청은 수신자가 수락해야만 정식 친구 상태가 되며, 차단 시 상대방의 모든 상호작용이 차단됨.

---

## 비즈니스 불변식 (Invariants) 및 공통 규칙

1. 모든 경험치 수치는 0 이하로 떨어지지 않으며, 최대치를 초과하면 즉시 레벨업 처리를 수행함.
2. 식사 기록이 삭제되더라도 이미 지급된 경험치와 보상은 소급 적용하여 회수하지 않음.
3. 캐릭터의 외형 변화는 최근 일주일의 평균 데이터를 따르며, 일시적인 과식으로 급격하게 변하지 않도록 보정함.

---

## 주요 도메인 서비스 및 비동기 이벤트

### 도메인 서비스
- AppearanceCalculator: 영양소 통계를 분석하여 캐릭터의 현재 파츠와 외형 수치를 계산함.
- RewardDistributor: 퀘스트 완료 또는 이벤트 발생 시 포인트 및 아이템 보상을 통합 관리함.

### 주요 도메인 이벤트 (Goroutine 비동기 처리)
- MealCreated: 식사 기록 생성 시 (영수증 OCR 분석, 이미지 리사이징, 마스터리 및 퀘스트 갱신 연동)
- NudgeSent: 응원하기 메시지 전송 시 (FCM 기반 실시간 푸시 알림 전송)
- GuestbookWritten: 방명록 작성 완료 시 (방명록 수신자 대상 푸시 알림 전송)
- LevelUp: 캐릭터/마스터리 레벨 상승 시 (레벨업 축하 알림 및 시스템 보상 지급 처리)

### 스케줄링 작업 (Cron 기반 예약 실행)
- DailyReset: 매일 특정 시각에 수행되는 데이터 초기화 작업 (퀘스트 등)
- InactivityPenalty: 미접속 사용자에 대한 자동 패널티 부여

---

## 컨텍스트 간 관계 및 통신

| 관계 | 상류 (Upstream) | 하류 (Downstream) | 통신 방식 |
|------|----------------|-------------------|----------|
| 식사 기록 -> 퀘스트 갱신 | Meal | Quest | 함수 호출 (동기) |
| 퀘스트 완료 -> 캐릭터 보상 | Quest | Character | 함수 호출 (동기) |
| 식사 기록 -> AI 영양 분석 | Meal | Nutrition | **Goroutine (비동기)** |
| 영양소 변화 -> 파츠 재계산 | Nutrition | Character | 함수 호출 (동기) |
| 퀘스트 완료 -> 도감 등록 | Quest | Collection | 함수 호출 (동기) |
| 소셜 응원 -> 푸시 알림 | Social | Notification | **Goroutine (비동기)** |

---

## Go 패키지 매핑 및 설계 원칙

```
internal/
├── domain/              # 순수 Go 구조체와 인터페이스 (외부 의존성 없음)
│   ├── base.go
│   ├── user.go
│   ├── character.go
│   ├── meal.go
│   ├── nutrition.go
│   ├── quest.go
│   ├── collection.go
│   ├── social.go
│   └── error.go
├── usecase/             # 애플리케이션 비즈니스 로직
├── delivery/http/       # Interface Adapter (API 핸들러)
└── repository/         # Infrastructure (GORM 구현체)
```

1. usecase는 domain 인터페이스에만 의존하며, repository 구현체를 직접 참조하지 않음.
2. delivery는 usecase만 호출하며, domain 객체를 직접 조작하지 않음.
3. 모든 엔티티 상태 변경은 루트 엔티티의 메서드를 통해서만 이루어지도록 캡슐화함.
