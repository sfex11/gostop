# 다음 단계 — Phase 1 나머지 + Phase 2 진입

> 현재 상태: 룰 엔진 완성 (107 tests), Flutter UI 미착수
> 목표: **AI 대전이 가능한 플레이 가능한 앱** 완성

---

## 현재 완료 현황

| 항목 | 상태 | 비고 |
|------|------|------|
| 설계 문서 | ✅ 완료 | game-design-final.md |
| 카드/덱 정의 | ✅ 완료 | card.dart, deck.dart |
| 매칭 엔진 | ✅ 완료 | matching.dart |
| 점수 계산 | ✅ 완료 | scoring.dart (광/띠/동물/피/고도리/홍단/청단/초단) |
| 게임 상태 머신 | ✅ 완료 | game_state.dart (play→capture→goStop→end) |
| 배수 계산 | ✅ 완료 | multiplier.dart (피박/광박/고박/흔들기/멍따) |
| 손패 검사 | ✅ 완료 | hand_checker.dart (총통/흔들기) |
| 게임 설정 | ✅ 완료 | game_config.dart (모든 규칙 Config화) |
| 기본 AI | ✅ 완료 | agent.dart (RandomAgent — 70% 매칭 우선) |
| 단위 테스트 | ✅ 완료 | 107 tests pass |

---

## 다음 단계 (우선순위 순)

### Step 1: Flutter 프로젝트 초기화
- `flutter create` 로 메인 앱 프로젝트 생성 (`app/` 디렉토리)
- 기존 `engine/`을 path dependency로 연결
- Riverpod 등 핵심 패키지 추가
- 디렉토리 구조:
  ```
  gostop/
    engine/          # 기존 룰 엔진 (순수 Dart)
    app/             # Flutter 앱 (신규)
      lib/
        game/        # 게임 컨트롤러 (Riverpod)
        ui/          # 위젯들
        main.dart
  ```

### Step 2: 게임 컨트롤러 (Riverpod)
- `GameNotifier` — 엔진의 `GameState`를 래핑
- 턴 진행 메서드: `playCard()`, `resolveCapture()`, `chooseGo()`, `chooseStop()`
- AI 턴 자동 실행 로직
- 게임 시작/리셋 기능

### Step 3: 카드 위젯 & 에셋
- 화투 카드 이미지 에셋 확보 (오픈소스 또는 플레이스홀더)
- `HwatooCardWidget` — 카드 1장 표시 (앞면/뒷면)
- 카드 탭/드래그 인터랙션
- 매칭 하이라이트 표시

### Step 4: 게임 화면 레이아웃
- `GamePage` 메인 화면 구성:
  - `OpponentHand` — 상대 패 (뒷면)
  - `ScorePanel` — 점수/턴 정보
  - `TableCards` — 바닥 카드
  - `MyHand` — 내 패 (터치 가능)
  - `ActionButtons` — 고/스톱 버튼 (goStop 페이즈에서만 노출)
- 획득한 카드 영역 (광/띠/동물/피 분류 표시)

### Step 5: 게임 루프 연결
- 플레이어 카드 선택 → 엔진 `playCard()` 호출
- 덱 카드 뒤집기 → `resolveCapture()` 호출
- 점수 도달 시 고/스톱 UI 표시
- AI 턴 자동 진행 (짧은 딜레이 후)
- 게임 종료 시 결과 화면 (점수 + 배수 + 최종 점수)

### Step 6: AI 강화 (Phase 2 진입)
- `HeuristicAgent` 구현:
  - 광 우선 수집 전략
  - 띠 조합 인식 (홍단/청단/초단 추적)
  - 고도리 기회 감지
  - 피 카운팅
  - 고/스톱 판단 고도화 (남은 덱, 상대 점수 고려)
- 난이도 레벨 (easy/normal/hard)

### Step 7: 마감 & 폴리시
- 게임 시작 화면 (로비)
- 설정 화면 (룰 Config 변경)
- 기본 효과음 (선택적)
- 카드 이동 애니메이션
- 전적 저장 (SharedPreferences)

---

## 기술 결정 사항

| 항목 | 결정 |
|------|------|
| 상태 관리 | Riverpod (설계 문서 확정) |
| 카드 에셋 | 오픈소스 우선, 없으면 텍스트 플레이스홀더 |
| 앱 구조 | engine/ (순수 Dart) + app/ (Flutter) 분리 |
| AI 턴 딜레이 | 500ms~1000ms (자연스러운 느낌) |
| 최소 타겟 | Android API 23, iOS 12 |

---

## 즉시 착수 가능한 작업

1. **Flutter 프로젝트 생성** + engine 연결
2. **Riverpod GameNotifier** 구현
3. **텍스트 기반 프로토타입** (이미지 없이 카드 번호/월로 표시)

> 텍스트 기반 프로토타입으로 빠르게 게임 루프를 검증한 뒤,
> 카드 이미지와 애니메이션을 입히는 순서가 가장 효율적이다.
