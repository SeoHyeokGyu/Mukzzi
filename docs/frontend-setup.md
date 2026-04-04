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

### 웹 빌드 시 자동으로 트리 쉐이킹되는 아이콘
Material Design 아이콘 중 사용하지 않는 것들은 자동으로 제거되어 용량이 줄어듭니다.
필요시 `--no-tree-shake-icons` 플래그를 사용할 수 있습니다.

## 패키지 호환성

### 웹에서 미지원하는 패키지
다음 패키지들은 웹 플랫폼에서 작동하지 않으므로 사용할 수 없습니다:
- `flutter_secure_storage` - 웹에서 지원 안 함
- `rive` - 웹 호환성 문제

## 빌드 전 체크리스트

1. ✅ `flutter pub get` 실행하여 의존성 최신화
2. ✅ 로컬 빌드 테스트 성공
3. ✅ 프로덕션 빌드 테스트 성공 (`flutter build web --release`)
4. ✅ Git 커밋

## CI/CD

GitHub Actions를 통해 자동 배포됩니다:
- `frontend/**` 경로 변경 시 자동 트리거
- Docker 이미지 빌드 및 Docker Registry에 푸시
- Oracle Cloud에 자동 배포
- 배포 성공/실패 모두 Discord 알림

자세한 정보는 `.github/workflows/frontend-deploy.yml` 참고
