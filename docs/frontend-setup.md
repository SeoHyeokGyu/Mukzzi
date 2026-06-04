# Frontend 개발 환경 설정 및 빌드

## 개발 환경 요구사항

- **Flutter**: 3.24.0 이상
- **Dart**: 3.5 이상
- **Node.js**: 18 이상 (웹 빌드 시)
- **macOS/Linux/Windows**

## 설치

### 1. Flutter 설치

#### macOS (Homebrew)
```bash
brew install flutter
```

#### 기타 플랫폼
[Flutter 공식 설치 가이드](https://flutter.dev/docs/get-started/install) 참고

### 2. 의존성 확인
```bash
flutter doctor
```

## 로컬 빌드

### 의존성 설치
```bash
cd frontend
flutter pub get
```

### 웹 빌드

#### 개발 빌드
```bash
flutter run -d chrome
```

#### 프로덕션 빌드 (테스트)
```bash
flutter build web --release
```

이 명령어는 `build/web/` 디렉토리에 빌드 결과물을 생성합니다.

## 디자인 시스템

### 디자인 시스템 및 테마 토큰 (Theme Tokens)

이 프로젝트는 라이트 모드 및 다크 모드(하이브리드 테마) 대응을 위해 정적 `AppColors` 외에 다이나믹 테마 토큰인 `AppColorTokens` 객체를 사용합니다.

#### 1. 테마 독립적 고정 색상 (`AppColors`)
로그인 버튼 브랜드 색상이나 테마와 무관한 공통 고정 색상은 `AppColors` 클래스를 참조합니다.
```dart
import 'package:mukzzi/src/core/theme/app_theme.dart';

color: AppColors.orange         // #FF6B35 (강조 색상)
color: AppColors.kakaoYellow    // #FEE500 (브랜드 색상)
```

#### 2. 테마 가변 토큰 (`AppColorTokens`)
배경, 카드, 텍스트, 그라데이션 등 테마 모드(라이트/다크)에 따라 자동으로 전환되어야 하는 디자인 값은 `Theme.of(context).extension<AppColorTokens>()!`를 활용해 참조합니다.
```dart
import 'package:mukzzi/src/core/theme/app_theme.dart';

final tokens = Theme.of(context).extension<AppColorTokens>()!;

// 테마에 맞는 색상 및 그라데이션 적용
color: tokens.bg                    // 현재 테마의 전체 배경색
color: tokens.textPrimary           // 현재 테마의 주 텍스트 색상
gradient: tokens.cardHeroGrad       // 프리미엄 히어로 카드용 다이내믹 그라데이션
borderRadius: BorderRadius.circular(tokens.rCard)  // 공통 카드 둥글기 값
```

### 그라데이션
* 정적 그라데이션: `AppColors.primaryGradient` (오렌지→피치 고정)
* 테마형 그라데이션: `tokens.bgGrad` (배경 전체), `tokens.cardHeroGrad` (캐릭터 프리뷰 카드)


## 공용 위젯

### GradientScaffold
그라데이션 배경이 적용된 Scaffold 래퍼. 모든 페이지는 이를 사용합니다:

```dart
GradientScaffold(
  appBar: AppBar(...),
  body: SingleChildScrollView(...),
  bottomNavigationBar: NavigationBar(...),
)
```

### BentoCard
Bento Grid 레이아웃 카드. Soft 그림자와 선택적 그라데이션:

```dart
BentoCard(
  child: Text('content'),
  height: 220,
  gradient: AppColors.primaryGradient,  // 선택사항
)
```

### GradientProgressBar
그라데이션이 적용된 프로그레스 바 (LinearProgressIndicator 대체):

```dart
GradientProgressBar(
  value: 0.75,  // 0.0 ~ 1.0
  height: 8,
)
```

### AppGradientButton
그라데이션 배경 버튼:

```dart
AppGradientButton(
  label: '저장',
  onPressed: () {},
)
```

## 주의사항

### ProviderScope 필수
`MukzziApp`은 `ConsumerWidget`을 사용하므로, 반드시 `ProviderScope`로 감싸야 합니다:

```dart
void main() {
  runApp(
    const ProviderScope(
      child: MukzziApp(),
    ),
  );
}
```

`ProviderScope` 없이 프로덕션 빌드 시 빈 화면만 표시되고 에러 메시지가 나타나지 않습니다.

### 색상 하드코딩 금지
`Colors.orange` 같은 하드코딩 대신 항상 `AppColors` 토큰 사용:

```dart
// ❌ 잘못됨
color: Colors.orange

// ✅ 올바름
color: AppColors.orange
```

### Google Fonts (Noto Sans KR)
한국어 폰트는 자동으로 Google Fonts에서 로드됩니다. 오프라인 환경에서는 로드 실패 가능성 있음.

### 웹 빌드 시 자동으로 트리 쉐이킹되는 아이콘
Material Design 아이콘 중 사용하지 않는 것들은 자동으로 제거되어 용량이 줄어듭니다.
필요시 `--no-tree-shake-icons` 플래그를 사용할 수 있습니다.

### 패키지 호환성

#### 웹에서 미지원하는 패키지
다음 패키지들은 웹 플랫폼에서 작동하지 않으므로 사용할 수 없습니다:
- `flutter_secure_storage` - 웹에서 지원 안 함
- 기타 플랫폼 특화 패키지들

#### 현재 사용 중인 주요 패키지
- `flutter_riverpod`: 상태 관리
- `go_router`: 라우팅
- `dio`: HTTP 클라이언트
- `flutter_animate`: 페이드인/슬라이드 애니메이션
- `google_fonts`: Noto Sans KR 한국어 폰트

## 애니메이션

`flutter_animate` 패키지를 사용하여 간단한 애니메이션 적용:

```dart
BentoCard(child: ...)
  .animate()
  .fadeIn(duration: 300.ms)
  .slideY(begin: 0.1, end: 0, duration: 300.ms)
```

**사용 예:**
- 페이드인: `.fadeIn(duration: 300.ms)`
- 슬라이드: `.slideY(begin: 0.1, end: 0)`
- 스케일: `.scale(begin: Offset(0.8, 0.8))`
- 순차 등장: `.animate(delay: (index * 100).ms)`

## 빌드 전 체크리스트

1. ✅ `flutter pub get` 실행하여 의존성 최신화
2. ✅ 로컬 빌드 테스트 성공: `flutter build web --release`
3. ✅ 색상은 AppColors 토큰 사용 (하드코딩 금지)
4. ✅ 모든 페이지는 GradientScaffold 사용
5. ✅ Git 커밋 (커밋 전 테스트 필수)

## CI/CD

GitHub Actions를 통해 자동 배포됩니다:
- `frontend/**` 경로 변경 시 자동 트리거
- Docker 이미지 빌드 및 Docker Registry에 푸시
- Oracle Cloud에 자동 배포
- 배포 성공/실패 모두 Discord 알림

자세한 정보는 `.github/workflows/frontend-deploy.yml` 참고
