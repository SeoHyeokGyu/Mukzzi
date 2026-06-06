# 에셋 제작 체크리스트 (SVG 기반 캐릭터)

먹찌 캐릭터 및 장착 장비 에셋의 작업 단위별 체크리스트입니다.
Lottie 의존성을 제거하고 SVG 기반의 단일 레이어드 렌더러로 통일됨에 따라, 본 가이드를 준수하여 에셋을 제작하고 추가합니다.

---

## 1. 에셋 규격 및 좌표 시스템

모든 에셋은 동일한 가상 캔버스 위에서 틀어짐 없이 정밀하게 겹쳐져야 합니다.

- **캔버스 크기**: **1024 × 1024 px** (상대 좌표 계산의 기본 해상도)
- **배경**: **투명 필수** (여러 레이어를 위로 쌓아 합성하기 위함)
- **앵커 정렬**: 모든 에셋은 동일한 `viewBox="0 0 1024 1024"`를 가지며, 레이어를 겹쳐서 올렸을 때 별도의 오프셋 보정 없이 중앙 정렬이 맞아떨어져야 합니다.
- **포맷**: 표준 벡터 **SVG (XML)** 형식

---

## 2. 에셋 분류 및 파일명 규칙

에셋은 `frontend/assets/svg/` 경로에 저장하며, 아래의 네이밍 규칙을 준수합니다.

### 2.1. 캐릭터 기본 바디 파트 (`body`)
* 상태별 5가지 바디 이미지가 필요합니다.
* 파일명: `mukzzi2_{state}_body.svg`
  - 예) `mukzzi2_idle_body.svg`
  - 예) `mukzzi2_happy_body.svg`
  - 예) `mukzzi2_hungry_body.svg`
  - 예) `mukzzi2_sleeping_body.svg`
  - 예) `mukzzi2_starving_body.svg`

### 2.2. 캐릭터 표정 파트 (`face` - 선택사항)
* 바디 위로 겹쳐 렌더링할 표정 리소스입니다.
* 파일명: `mukzzi2_{state}_face.svg` (선택적 존재)

### 2.3. 장착형 장비 파트 (`equipment`)
* 칭호 외에 캐릭터에게 직접 착용할 수 있는 수집형 코스메틱 에셋입니다.
* 파일명: `mukzzi2_{asset_url}.svg`
  - 예) `mukzzi2_cap.svg` (HEAD 슬롯용 모자)
  - 예) `mukzzi2_glasses.svg` (FACE 슬롯용 안경)
  - 예) `mukzzi2_bag.svg` (BACK 슬롯용 가방)

---

## 3. Flutter 연동 및 렌더링 메커니즘

- **사용 위젯**: [mukzzi_character.dart](file:///Users/seohyeokgyu/IdeaProjects/Mukzzi/frontend/lib/src/core/widgets/mukzzi_character.dart) 내의 `_SvgLayeredCharacter` 위젯이 조합을 처리합니다.
- **렌더링 순서 (z-index)**:
  1. `z_index < 0`인 장비 장착 (예: BACKGROUND 등)
  2. 캐릭터 `body` 레이어 렌더링 (`z_index = 0`)
  3. `z_index >= 0`인 장비 장착 (HEAD, FACE, BODY, HAND 등 순서에 따라 정렬됨)
  4. 선택적 `face` 레이어 렌더링 (`z_index = 50`)

---

## 4. 에셋 추가 및 검증 체크리스트

신규 외형 파츠 또는 장착 장비를 추가할 때는 다음 체크리스트를 준수합니다.

- [ ] **SVG 규격 확인**: `viewBox` 속성이 `0 0 1024 1024`로 통일되어 있는지 검증합니다.
- [ ] **XML 유효성 검증**: SVG 내부 태그가 손상되지 않고 브라우저 및 기기에서 단독 렌더링 가능한지 확인합니다.
- [ ] **pubspec.yaml 자산 등록**: `frontend/pubspec.yaml`의 `assets:` 항목에 올바르게 포함되어 있는지 점검합니다. (이미 `assets/svg/` 디렉토리가 통째로 매핑되어 있으므로 누락되었는지 확인만 합니다.)
- [ ] **장착 장비 지원 목록 등록**: 신규 장비 코드를 추가하는 경우, [mukzzi_character.dart](file:///Users/seohyeokgyu/IdeaProjects/Mukzzi/frontend/lib/src/core/widgets/mukzzi_character.dart#L106-L113)의 `_supportedEquipmentAssets` 집합에 `assetUrl` 명칭을 등록해야 정상 렌더링이 이루어집니다.
