# 기술 스택

## Frontend (iOS / Android / Web)
| 항목 | 선택 | 이유 |
|------|------|------|
| 프레임워크 | Flutter 3.24 | 단일 코드베이스로 iOS/Android/Web 동시 개발 |
| 언어 | Dart 3.5 | Flutter 네이티브 언어, Null Safety 기본 지원 |
| 상태관리 | Riverpod | 컴파일 타임 안전성, 의존성 주입 통합 |
| 애니메이션 | Rive | 인터랙티브 벡터 애니메이션, 앱/웹 동일 품질 렌더링 |
| 라우팅 | GoRouter | 선언적 라우팅, 딥링크 지원 |
| HTTP | Dio | 인터셉터, 토큰 갱신 자동화 |

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
