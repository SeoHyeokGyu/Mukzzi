# Lottie 제거 및 먹찌2(SVG) 단일 렌더러 통일 설계

## Goal

`CharacterVariant` 이중 렌더러(v1 Lottie / v2 SVG)를 폐기하고, SVG 기반 먹찌2(`_SvgLayeredCharacter`)만 남긴다. Lottie 의존성, 에셋, 관련 코드를 전부 제거한다.

## Architecture

`MukzziCharacter` 위젯은 단일 렌더러(`_SvgLayeredCharacter`)만 사용한다. `variant` 파라미터가 사라지므로 호출부 변경 없이 기존 코드가 동작한다 (현재 home/social은 이미 variant 없이 호출 중).

```
Before:
  MukzziCharacter(state, size, variant?)
    ├── v1 → _LottieCharacter → mukzzi_baby_*.json
    └── v2 → _SvgLayeredCharacter → mukzzi2_baby_*_{body,accessory}.svg

After:
  MukzziCharacter(state, size)
    └── _SvgLayeredCharacter → mukzzi2_baby_*_{body,accessory}.svg
```

SVG 렌더러는 상태별 애니메이션(`AnimationController` translate/scale), 레이어 비동기 해소(body 필수, face·accessory 선택적), `idle` 폴백을 이미 구현하고 있다.

## 제거 목록

### 파일 삭제
- `frontend/assets/animations/mukzzi_baby_{idle,happy,hungry,starving,sleeping}.json` (5개)
- `frontend/assets/animations/mukzzi_teen_{idle,happy,hungry,starving,sleeping}.json` (5개)
- `frontend/assets/animations/mukzzi_adult_{idle,happy,hungry,starving,sleeping}.json` (5개)
- `frontend/assets/animations/.gitkeep`
- `frontend/lib/src/core/widgets/lottie_web_player_stub.dart`
- `frontend/lib/src/core/widgets/lottie_web_player_web.dart`

### pubspec.yaml
- `dependencies`: `lottie: ^3.3.1` 제거
- `flutter.assets`: `- assets/animations/` 항목 제거

### mukzzi_character.dart
- `import 'package:lottie/lottie.dart'` 제거
- `import 'lottie_web_player_stub.dart' if (dart.library.js_interop) 'lottie_web_player_web.dart'` 제거
- `enum CharacterVariant { v1, v2 }` 및 `CharacterVariantLabel` extension 제거
- `MukzziCharacter.variant` 필드 및 파라미터 제거
- `MukzziCharacter.build` — switch 제거, 항상 `_SvgLayeredCharacter` 반환
- `_LottieCharacter` 클래스 전체 제거

### character_provider.dart
- `CharacterVariantNotifier` 클래스 전체 제거
- `characterVariantProvider` 제거
- `SharedPreferences` import (variant 저장용) 제거 (다른 용도 없을 경우)

### character_page.dart
- `ref.watch(characterVariantProvider)` 및 `variant` 변수 제거
- `MukzziCharacter`의 `variant: variant` 파라미터 제거
- variant picker FilterChip Row 전체 제거

## 영향 없는 파일

- `home_page.dart` — 이미 `MukzziCharacter(state: state, size: 160)` 형태, 변경 불필요
- `social_page.dart` — 이미 variant 없이 호출 중, 변경 불필요
- SVG 에셋 (`assets/svg/mukzzi2_*.svg`) — 유지

## 검증

- `flutter pub get` 성공 (lottie 패키지 제거 반영)
- `dart analyze lib/` 에러 없음
- `character_page.dart` — variant picker 없이 캐릭터 표시 정상 확인
