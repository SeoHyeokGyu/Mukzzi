# 기술 스택

## Mobile (Frontend)
| 항목 | 선택 | 이유 |
|------|------|------|
| 프레임워크 | React Native | iOS/Android 동시 개발, Kakao SDK 지원 |
| 상태관리 | Zustand | 가볍고 직관적 |
| 애니메이션 | Reanimated 3 | 먹찌 변신 연출에 적합 |

## Backend
| 항목 | 선택 | 이유 |
|------|------|------|
| 프레임워크 | Spring Boot (Kotlin) | JVM 기반, IntelliJ 환경, 한국 개발 생태계 |
| 실시간 | WebSocket (STOMP) | Tier 3 그룹 챌린지·배틀 실시간 처리 |
| 스케줄러 | Spring Scheduler | 패널티 시스템, 푸시 알림 배치 |

## Database
| 항목 | 선택 | 이유 |
|------|------|------|
| 메인 DB | PostgreSQL | 복잡한 영양소·캐릭터 관계 데이터 |
| 캐싱 | Redis | 자주 검색되는 음식 캐싱, 세션 관리 |
| 파일 저장 | AWS S3 | 음식 사진, 캐릭터 이미지 |

## AI / 외부 API
| 항목 | 선택 | 이유 |
|------|------|------|
| 음식 사진 인식 | Google Vision API | 정확도 높은 음식 분류 |
| 영수증 OCR | Naver Clova OCR | 한국 영수증 인식 최적화 |
| 메뉴 추천 AI | OpenAI GPT API | 대화형 영양 상담, 자연어 추천 |
| 음식 영양소 DB | 식약처 API + USDA | 국내외 음식 영양 정보 |

## 인증
| 항목 | 선택 |
|------|------|
| 토큰 | JWT (Access + Refresh) |
| 소셜 | Kakao OAuth 2.0 / Google OAuth / Apple Sign In |

## 알림 / 인프라
| 항목 | 선택 |
|------|------|
| 푸시 알림 | FCM (Firebase Cloud Messaging) |
| 서버 | AWS EC2 + RDS |
| 컨테이너 | Docker + GitHub Actions (CI/CD) |
