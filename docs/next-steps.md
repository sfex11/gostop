# 다음 단계 — Phase 2 완료 + Phase 3 계획

> 현재 상태: 룰 엔진 완성 + 버그 수정, HeuristicAgent, Flutter 앱 (텍스트 기반)
> 목표: **카드 에셋 + 애니메이션 + P2P 온라인 대전**

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
| 게임 컨트롤러 | ✅ 완료 | GameNotifier + GameResult 통합 |
| 카드 위젯 | ✅ 완료 | 텍스트 플레이스홀더 |
| 게임 화면 | ✅ 완료 | GamePage (전체 레이아웃) |
| 게임 루프 | ✅ 완료 | 플레이→캡처→고스톱→결과 |
| 결과 화면 | ✅ 완료 | 배수 + 고보너스 + 최종점수 표시 |
| 로비 | ✅ 완료 | 난이도 선택 포함 |
| 단위 테스트 | ✅ 완료 | 107+ tests |

---

## 이번에 수정된 엔진 버그

| 버그 | 수정 내용 |
|------|-----------|
| resolveCapture 트리플매치 | `_matchedTableCard` → `_playMatchedCards` (리스트)로 변경, 3장 모두 정상 획득 |
| calculateJunk 컵 임계값 | `>= 9` → `totalJunk + 2 >= 10` (8피 + 컵 = 10피 가능) |
| sweep 미구현 | 테이블 빈 상태 감지 + 피뺏기 구현 |
| GameConfig 플래그 무시 | Multiplier/Scoring에 config 전달, 각 플래그 분기 |
| 최종 점수 정산 없음 | GameResult.fromState()로 (기본점수+고보너스)×배수 계산 |

---

## 다음 단계 (Phase 3)

### Step 8: 화투 카드 이미지 에셋
- 오픈소스 화투 이미지 확보 (48장)
- `HwatooCardWidget`에 이미지 렌더링
- 카드 뒷면 디자인

### Step 9: 카드 애니메이션
- 카드 이동 애니메이션 (손패→바닥, 바닥→획득)
- 덱 뒤집기 애니메이션
- 쓸(sweep) 시각 효과
- 고/스톱 텍스트 애니메이션

### Step 10: 설정 화면
- GameConfig 규칙 변경 UI (토글 스위치)
- 점수 기준 슬라이더 (3점 / 7점)
- 설정 SharedPreferences 저장

### Step 11: 전적 저장
- SharedPreferences로 승/패/무 기록
- 로비에 전적 표시
- 연승 기록

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
| 카드 에셋 | 오픈소스 우선, 없으면 텍스트 플레이스홀더 (현재 텍스트) |
| 앱 구조 | engine/ (순수 Dart) + app/ (Flutter) 분리 |
| AI 턴 딜레이 | 700ms (현재 적용) |
| AI 난이도 | easy/normal/hard (HeuristicAgent) |
| 최소 타겟 | Android API 23, iOS 12 |

---

## 즉시 착수 가능한 작업

1. **화투 이미지 에셋** 확보 및 카드 위젯에 적용
2. **카드 이동 애니메이션** 구현
3. **설정 화면** 및 전적 저장
