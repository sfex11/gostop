# 다음 단계 — Phase 3 진행 중

> 현재 상태: 룰 엔진 완성 + HeuristicAgent + Flutter 앱 (비주얼 카드 + 애니메이션 + 설정 + 전적)
> 목표: **P2P 온라인 대전 + 효과음 + 마감**

---

## 완료 현황

| 항목 | 상태 | 비고 |
|------|------|------|
| 설계 문서 | ✅ 완료 | game-design-final.md |
| 카드/덱 정의 | ✅ 완료 | card.dart, deck.dart |
| 매칭 엔진 | ✅ 완료 | matching.dart |
| 점수 계산 | ✅ 완료 | scoring.dart + GameConfig 연동 |
| 게임 상태 머신 | ✅ 완료 | game_state.dart (트리플매치 버그 수정) |
| 배수 계산 | ✅ 완료 | multiplier.dart (GameConfig 플래그 연동) |
| 쓸(sweep) 감지 | ✅ 완료 | game_state.dart + 피뺏기 |
| 최종 점수 정산 | ✅ 완료 | game_result.dart (배수×(기본점+고보너스)) |
| 기본 AI | ✅ 완료 | RandomAgent |
| 전략 AI | ✅ 완료 | HeuristicAgent (easy/normal/hard) |
| Flutter 프로젝트 | ✅ 완료 | app/ (Riverpod) |
| 게임 컨트롤러 | ✅ 완료 | GameNotifier + GameResult + GameConfig 통합 |
| 카드 비주얼 렌더링 | ✅ 완료 | CustomPainter (HwatooCardPainter, CardBackPainter) |
| 카드 애니메이션 | ✅ 완료 | FlipCard, SweepEffectOverlay, GoStopBanner |
| 게임 화면 | ✅ 완료 | GamePage (애니메이션 오버레이 통합) |
| 게임 루프 | ✅ 완료 | 플레이→캡처→고스톱→결과 |
| 결과 화면 | ✅ 완료 | 배수 + 고보너스 + 최종점수 + 전적 표시 |
| 로비 | ✅ 완료 | 난이도 선택 + 전적 표시 + 설정 진입 |
| 규칙 설정 화면 | ✅ 완료 | GameConfig 13개 토글/슬라이더, SharedPreferences 저장 |
| 전적 저장 | ✅ 완료 | 승/패/무 + 연승/연패 + 최고연승, SharedPreferences |
| 단위 테스트 | ✅ 완료 | 107+ tests |

---

## Phase 3에서 수정/추가된 사항

### Step 8: 카드 비주얼 렌더링
- `HwatooCardPainter` — CustomPainter로 화투 카드 앞면 렌더링
  - 월별 테마 색상 (소나무~버들)
  - 한자 심볼 + 월 번호 + 유형 뱃지 + 카드 이름
  - 광 카드 코너 장식
- `CardBackPainter` — 카드 뒷면 (다이아몬드 패턴 + 花 마크)
- `HwatooCardWidget` — 그림자 + 하이라이트 효과 통합

### Step 9: 카드 애니메이션
- `FlipCard` — 카드 뒤집기 애니메이션 (3D 원근감)
- `SweepEffectOverlay` — 쓸 시각 효과 (확대+페이드)
- `GoStopBanner` — 고/스톱 결정 텍스트 (탄성 슬라이드+페이드)
- `GameEvent` enum — 이벤트 기반 애니메이션 트리거
- GamePage에 Stack 오버레이 통합

### Step 10: 규칙 설정 화면
- `SettingsPage` — 13개 GameConfig 옵션
  - 점수 기준 슬라이더 (1~10점)
  - 특수 규칙 토글 (쌍피, 폭탄, 흔들기, 총통, 피뺏기, 쓸, 고도리)
  - 배수 규칙 토글 (광박, 피박, 고박, 멍따)
  - 초기화 버튼 (표준룰 복원)
- `SettingsService` — SharedPreferences 저장/로드
- `GameNotifier` — setConfig() 메서드, 새 게임에 config 적용
- 로비에 설정 버튼 추가

### Step 11: 전적 저장
- `GameStats` — 승/패/무/연승/연패/최고연승 데이터
- `StatsService` — SharedPreferences 기반 전적 CRUD
- `ResultDialog` — 게임 결과에 전적 자동 기록 + 표시
- `LobbyPage` — 전적 요약 표시 (게임 복귀 시 자동 갱신)

---

## 다음 단계 (Phase 3 나머지)

### Step 12: P2P 온라인 대전 (Phase 3 핵심)
- WebRTC 기반 P2P 연결
- 방 코드 시스템
- 랜덤 매칭 (시그널링 서버)
- 게임 상태 동기화 프로토콜

### Step 13: 마감 & 배포
- 효과음 추가
- 다크/라이트 테마
- 앱 아이콘/스플래시
- Google Play / App Store 제출 준비

---

## 기술 결정 사항

| 항목 | 결정 |
|------|------|
| 상태 관리 | Riverpod (확정) |
| 카드 렌더링 | CustomPainter (이미지 에셋 불필요) |
| 앱 구조 | engine/ (순수 Dart) + app/ (Flutter) 분리 |
| AI 턴 딜레이 | 700ms (현재 적용) |
| AI 난이도 | easy/normal/hard (HeuristicAgent) |
| 설정 저장 | SharedPreferences |
| 전적 저장 | SharedPreferences |
| 최소 타겟 | Android API 23, iOS 12 |

---

## 즉시 착수 가능한 작업

1. **P2P 온라인 대전** — WebRTC + 시그널링 서버
2. **효과음 추가** — audioplayers 패키지
3. **앱 아이콘/스플래시** — flutter_launcher_icons
