# Flutter 카드게임 UI 참고 리포

## 핵심 참고 (우선순위순)

### 1. flutter/games — 공식 카드게임 템플릿
- **URL**: https://github.com/flutter/games (`templates/card/`)
- **Stars**: ~765
- **License**: BSD-3-Clause
- **활용**: 프로젝트 구조, 드래그&드롭, 네비게이션, 테마, 사운드
- **핵심 파일**:
  - `templates/card/lib/play_session/` — 게임 플레이 영역
  - `templates/card/lib/game_internals/` — 게임 로직
  - `templates/card/lib/style/` — 테마/스타일

### 2. flutter/io_flip — Google I/O 2023 카드게임
- **URL**: https://github.com/flutter/io_flip
- **Stars**: ~694
- **License**: BSD-3-Clause
- **활용**: 프로덕션급 카드 렌더링, 애니메이션, Firebase 연동, 매치메이킹
- **핵심 파일**:
  - `lib/game/` — 코어 게임 로직
  - `lib/match_making/` — 매칭 플로우
  - `packages/` — 재사용 패키지

### 3. AadumKhor/Solitaire_Flutter — 순수 Flutter 솔리테어
- **URL**: https://github.com/AadumKhor/Solitaire_Flutter
- **Stars**: ~40
- **License**: MIT
- **활용**: 카드 스택, 드래그&드롭, 카드 정렬 로직 (게임 엔진 없이 순수 Flutter)
- **핵심**: `Draggable`/`DragTarget` 위젯 활용

### 4. xajik/thedeck — 멀티플레이어 카드게임 엔진
- **URL**: https://github.com/xajik/thedeck
- **Stars**: ~743
- **License**: MIT
- **활용**: 클라이언트-서버 분리 아키텍처, Socket.IO 실시간 동기화, 모듈러 패키지 구조
- **핵심 파일**:
  - `thedeck_client/` — 클라이언트 네트워킹
  - `thedeck_common/` — 공유 모델
  - `thedeck_server/` — 백엔드

### 5. tylersavery/flutter-cardgame — AI 봇 카드게임
- **URL**: https://github.com/tylersavery/flutter-cardgame
- **Stars**: ~35
- **License**: MIT
- **활용**: Provider 상태관리, AI 봇 플레이어, 다형성 게임타입

### 6. BrunoJurkovic/flip_card — 카드 뒤집기 애니메이션
- **URL**: https://github.com/BrunoJurkovic/flip_card
- **Stars**: ~352
- **License**: BSD-3-Clause
- **활용**: 카드 플립 애니메이션 위젯 (드롭인 솔루션)

## 우리 프로젝트에 적용할 것

| 관심사 | 1순위 참고 | 2순위 참고 |
|--------|-----------|-----------|
| 프로젝트 구조 | flutter/games 카드 템플릿 | flutter/io_flip |
| 카드 위젯/렌더링 | AadumKhor/Solitaire_Flutter | akshatapp/flutter-playing-cards |
| 카드 플립 애니메이션 | BrunoJurkovic/flip_card | 커스텀 구현 |
| 드래그 & 드롭 | flutter/games 카드 템플릿 | AadumKhor/Solitaire_Flutter |
| 멀티플레이어 아키텍처 | xajik/thedeck | tylersavery/flutter-cardgame (AI) |
