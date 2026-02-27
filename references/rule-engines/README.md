# 고스톱 룰 엔진 참고 코드

> GitHub에서 수집한 고스톱/화투 룰 엔진 오픈소스 조사 결과.
> Dart 포팅 시 핵심 참고 자료로 활용한다.

## 추천 순위

### 1순위: reidlindsay/gostop (Python) — Dart 포팅 최적 ★★★
- **URL**: https://github.com/reidlindsay/gostop
- **License**: **MIT** (상업적 사용 자유)
- **Language**: Python 100%
- **적합도**: **최고**. 깔끔한 OOP 구조, 상태 머신 패턴, 테스트 스위트 포함
- **특징**:
  - 48장 화투 덱, 카드/월/그룹 enum 기반 정의
  - 불변 상태 머신 (Play → Capture → GoStop → End)
  - 점수 계산 엔진 (광/동물/띠/피)
  - AI용 `copy_and_randomise` (MCTS 지원)
  - 단위 테스트 포함

### 2순위: skarl86/gostop_c (C) — 한국 규칙 상세 ★★
- **URL**: https://github.com/skarl86/gostop_c
- **License**: 없음 (대학 프로젝트, 코드 재사용 불가 — 규칙/로직만 참고)
- **Language**: C 100%
- **적합도**: 높음. Python에 없는 한국식 고스톱 규칙 보완용
- **특징**:
  - 3인 플레이 지원
  - 배수 시스템 (피박/광박/고박/흔들기/멍따)
  - 쌍피(ssangpi) 처리
  - 총통(4장 즉시 승리) / 흔들기(3장 배율)
  - 돈/베팅 시스템
  - 피 뺏기(steal_pi) 로직

### 참고: JavaScript 구현체 (코이코이/일본 변형)

| 리포 | License | 활용 |
|------|---------|------|
| [teradaian/hanafuda](https://github.com/teradaian/hanafuda) | 없음 | 카드 매칭 로직 패턴 참고 |
| [massimilianodelliubaldini/hanafuda-react](https://github.com/massimilianodelliubaldini/hanafuda-react) | 없음 | 카드 데이터 모델링, Yaku 정의 참고 |

> **주의**: Dart/Flutter 고스톱 구현체는 GitHub에 존재하지 않음. 첫 Dart 포팅이 됨.

---

## 핵심 데이터 구조 (Python 기준)

### 카드 정의

```python
class Card:
    name: str       # 카드 이름 (예: 'Pine and Crane')
    month: int      # 월 (1~12)
    group: int      # 유형 (BRIGHT=1, ANIMAL=2, RIBBON=3, JUNK=4, JUNK_2=5)

class Month:
    JAN=1, FEB=2, MAR=3, APR=4, MAY=5, JUN=6,
    JUL=7, AUG=8, SEP=9, OCT=10, NOV=11, DEC=12

class Group:
    BRIGHT=1, ANIMAL=2, RIBBON=3, JUNK=4, JUNK_2=5
```

### 48장 화투 덱 구성

| 월 | 꽃 | 광(Bright) | 동물(Animal) | 띠(Ribbon) | 피(Junk) | 비고 |
|----|-----|-----------|-------------|-----------|---------|------|
| 1월 | 소나무 | 학(CRANE) | — | 홍단(RED_POEM) | 피×2 | |
| 2월 | 매화 | — | 꾀꼬리(BUSH_WARBLER) | 홍단(RED_POEM) | 피×2 | 고도리 |
| 3월 | 벚꽃 | 막(CURTAIN) | — | 홍단(RED_POEM) | 피×2 | |
| 4월 | 등나무 | — | 두견새(CUCKOO) | 초단(RED) | 피×2 | 고도리 |
| 5월 | 난초 | — | 다리(BRIDGE) | 초단(RED) | 피×2 | |
| 6월 | 모란 | — | 나비(BUTTERFLY) | 청단(BLUE_POEM) | 피×2 | |
| 7월 | 싸리 | — | 멧돼지(BOAR) | 초단(RED) | 피×2 | |
| 8월 | 억새 | 달(MOON) | 기러기(GEESE) | — | 피×2 | 고도리 |
| 9월 | 국화 | — | 국진(CUP)* | 청단(BLUE_POEM) | 피×2 | *쌍피 겸용 |
| 10월 | 단풍 | — | 사슴(DEER) | 청단(BLUE_POEM) | 피×2 | |
| 11월 | 오동 | 봉황(PHOENIX) | — | — | 피×1, 쌍피×1 | |
| 12월 | 버들 | 비(RAIN) | 제비(SWALLOW) | 띠(RED) | 쌍피×1 | |

**총**: 광 5장, 동물 9장, 띠 10장, 피 24장 = **48장**

> **특수 카드**:
> - 국진(CUP, 9월): 동물이면서 피 10장 이상이면 쌍피로 전환 가능
> - 쌍피(JUNK_2): 피 2장으로 계산 (11월 오동, 12월 버들, 9월 국진)

---

## 상태 머신 (Game State Machine)

```
GameStatePlay → GameStateCapture → GameStateGoStop → GameStateEnd
     │                │                  │
     │                │                  ├─ Go → GameStatePlay (다음 턴)
     │                │                  └─ Stop → GameStateEnd (승리)
     │                │
     │                └─ 덱에서 카드 뒤집기 → 테이블 매칭
     │
     └─ 손패에서 카드 내기 → 테이블 매칭
```

### 4가지 게임 상태

| 상태 | 설명 | 가능한 액션 |
|------|------|------------|
| **Play** | 플레이어가 손패에서 카드 선택 | PlayCard(card, paired_card?) |
| **Capture** | 덱에서 뒤집은 카드로 테이블 매칭 | PlayCard(top_card, paired_card?) |
| **GoStop** | 점수 도달 시 계속/종료 선택 | Go / Stop |
| **End** | 게임 종료 | 없음 |

### 턴 진행 흐름

```
1. [Play] 플레이어 손패 → 테이블 매칭
   - 매칭 0장: 카드를 테이블에 놓음
   - 매칭 1장: 쌍으로 지정
   - 매칭 2장: 플레이어가 하나 선택
   - 매칭 3장: 전부 획득 (뻑)

2. [Capture] 덱 탑 카드 → 테이블 매칭 (같은 규칙)
   - Play에서 지정한 쌍 + Capture에서 매칭된 쌍 → 획득 영역에 추가

3. [점수 체크] 총점 >= 기준점(3~5점)이면 GoStop 상태로
   - Go: 게임 계속 (다음 플레이어 턴)
   - Stop: 현재 플레이어 승리

4. [다음 턴] 다음 플레이어로 전환
```

### 초기 배분 (2인)

```
2라운드 × (5장/플레이어 + 4장/테이블)
= 플레이어당 10장, 테이블 8장, 덱 22장
```

---

## 점수 계산 규칙

### 광 (Bright)

| 조건 | 점수 |
|------|------|
| 5광 (전부) | **15점** |
| 4광 | **4점** |
| 3광 (비 없이) | **3점** |
| 3광 (비 포함) | **2점** |

### 동물 (Animal/십)

| 조건 | 점수 |
|------|------|
| 5장 이상 | **(장수 - 4)점** |
| 고도리 (꾀꼬리 + 두견새 + 기러기) | **+5점** |

### 띠 (Ribbon/오)

| 조건 | 점수 |
|------|------|
| 5장 이상 | **(장수 - 4)점** |
| 홍단 (1,2,3월 빨간 시 글씨) | **+3점** |
| 청단 (6,9,10월 파란 시 글씨) | **+3점** |
| 초단 (4,5,7월 빨간 무지) | **+3점** |

### 피 (Junk/피)

| 조건 | 점수 |
|------|------|
| 10피 이상 | **(피 수 - 9)점** |
| 쌍피 카드 | 2피로 계산 |
| 국진 전환 | 피 10장 이상이면 동물→쌍피로 이동 |

### 승리 기준

- **Python (reidlindsay)**: 총점 >= **5점** → Go/Stop 선택
- **C (skarl86)**: 총점 >= **3점** → Go/Stop 선택
- **우리 프로젝트**: Config 설정 가능 (기본 3점)

---

## 배수(벌칙) 시스템 (C 구현 기준)

Python 구현에는 없고 C 구현에만 있는 한국식 배수 규칙:

| 배수 | 조건 | 효과 |
|------|------|------|
| **피박** | 진 쪽 피 ≤ 5장 | 점수 **×2** |
| **광박** | 진 쪽 광 0장 | 점수 **×2** |
| **고박** | 진 쪽이 '고' 선언한 적 있음 | 점수 **×2** |
| **흔들기** | 이긴 쪽 손패에 같은 월 3장 | 점수 **×2** |
| **멍따** | 이긴 쪽 동물 ≥ 7장 | 점수 **×2** |

> 배수는 비트마스크로 중첩 가능: `GO_BAK=0x2, PI_BAK=0x4, GWANG_BAK=0x8, SWING=0x10, MUNG_BAK=0x20`

### 고(Go) 점수 계산 (C 구현)

```
go_count < 3: total_score + go_count
go_count >= 3: total_score << ((go_count/3) + (go_count%3))
```

### 특수 규칙 (C 구현)

| 규칙 | 설명 |
|------|------|
| **총통** | 손패에 같은 월 4장 → 즉시 승리 (10점) |
| **흔들기(Swing)** | 손패에 같은 월 3장 → 선언하면 배수 2배 |
| **쌍피** | 인덱스 32(국진), 41(오동), 47(버들) → 피 2장으로 계산 |
| **피 뺏기** | 한 턴에 4장 이상 획득 → 상대에게서 피 1장 빼앗음 |

---

## 카드 매칭 로직

### 테이블 매칭 (Python: `TableCards.get_paired_cards`)

```python
def get_paired_cards(self, card):
    """같은 월의 카드를 테이블에서 찾아 반환"""
    paired_cards = []
    for match_card in self.cards:
        if match_card.month == card.month:
            paired_cards.append(match_card)
    return paired_cards
```

### C 구현 매칭 로직 (play.c: `matchPae`)

```
1. 플레이어 카드 → 테이블 매칭
   - 0장 매칭: 테이블에 추가
   - 1장 매칭: 쌍 획득
   - 2장 매칭: 플레이어 선택
   - 3장 매칭: 전부 획득 (뻑/폭탄)

2. 덱 카드 뒤집기 → 같은 매칭 규칙

3. 특수 케이스:
   - 플레이어 카드 + 덱 카드가 같은 월 → "따닥" (연속 획득)
   - 한 턴에 4장 이상 획득 → 상대에게서 피 1장 빼앗음
```

---

## 고스톱 vs 코이코이 규칙 차이

| 항목 | 고스톱 (한국) | 코이코이 (일본) |
|------|-------------|--------------|
| 플레이어 | 2~3인 | 2인 전용 |
| 손패 | 10장(2인) / 7장(3인) | 8장 |
| 테이블 | 8장 | 8장 |
| 승리 기준 | 3~5점 이상 → Go/Stop | 족보 완성 → Koi-Koi/Stop |
| 광 점수 | 5=15, 4=4, 3(비X)=3, 3(비O)=2 | 5=15, 4=8, 4(비)=7, 3=6 |
| 고도리 | 꾀꼬리+두견새+기러기 = 5점 | 없음 |
| 이노시카초 | 없음 | 멧돼지+사슴+나비 = 5점 |
| 배수 | 피박/광박/고박/흔들기/멍따 | 코이코이 2배, 7점+ 2배 |
| 쌍피 | 3장 (2피 계산) | 없음 |
| 돈 시스템 | 있음 (100원/점) | 없음 |

---

## Dart 포팅 전략

### 권장 접근법

1. **reidlindsay/gostop (Python, MIT)** 구조를 Dart로 직접 포팅
   - `Card` → Dart class with `month`, `group` enums
   - `Deck` → `List<Card>` with shuffle
   - `Hand`, `TakenCards`, `TableCards` → Dart collections
   - `GameState*` → sealed class 또는 enum 기반 상태 머신
   - `Agent` → abstract class for AI

2. **skarl86/gostop_c** 에서 한국식 규칙 추가 구현 (코드 참고만, 직접 복사 불가)
   - 배수 시스템 (피박/광박/고박/흔들기/멍따)
   - 쌍피 처리
   - 총통/흔들기 특수 규칙
   - 피 뺏기

3. **Config 기반 설계** — 모든 규칙을 설정 가능하게 (game-design-final.md 참조)

### Dart 포팅 시 핵심 매핑

| Python | Dart |
|--------|------|
| `class Card` | `class HwatooCard` |
| `class Month` (constants) | `enum Month` |
| `class Group` (constants) | `enum CardType { bright, animal, ribbon, junk, doubleJunk }` |
| `class Deck(list)` | `class Deck extends Iterable<HwatooCard>` |
| `class CardList` | `mixin CardCollection on List<HwatooCard>` |
| `class Hand(CardList)` | `class Hand with CardCollection` |
| `class TakenCards(CardList)` | `class CapturedCards with CardCollection` |
| `class GameState` | `sealed class GameState` |
| `GameStatePlay` | `class PlayState extends GameState` |
| `GameStateCapture` | `class CaptureState extends GameState` |
| `GameStateGoStop` | `class GoStopState extends GameState` |
| `GameStateEnd` | `class EndState extends GameState` |
| `class Agent` | `abstract class Agent` |
| `generate_successor()` | `GameState nextState(GameAction action)` |

---

## 라이선스 요약

| 리포 | 라이선스 | 코드 재사용 | 규칙 참고 |
|------|---------|-----------|----------|
| reidlindsay/gostop (Python) | **MIT** | **가능** (저작권 표기) | 가능 |
| skarl86/gostop_c (C) | 없음 | **불가** | 가능 (규칙은 저작권 없음) |
| teradaian/hanafuda (JS) | 없음 | **불가** | 가능 |
| hanafuda-react (JS) | 없음 | **불가** | 가능 |
| ALee1303/Hwatu (C#) | **MIT** | **가능** | 가능 |

---

## 테스트 케이스 참고 (Python)

포팅 후 검증에 활용할 핵심 테스트:

```python
# 광 점수
TakenCards(CRANE, CURTAIN, MOON, PHOENIX, RAIN).score == [('Five brights', 15)]
TakenCards(CRANE, CURTAIN, MOON, PHOENIX).score == [('Four brights', 4)]
TakenCards(CRANE, CURTAIN, MOON).score == [('Three brights without rain', 3)]
TakenCards(CRANE, CURTAIN, RAIN).score == [('Three brights with rain', 2)]

# 고도리
TakenCards(BUSH_WARBLER, CUCKOO, GEESE).score == [('Godori', 5)]

# 띠
TakenCards(PINE_RED_POEM, PLUM_RED_POEM, CHERRY_RED_POEM).score == [('Three red ribbons with poem', 3)]
TakenCards(PEONY_BLUE_POEM, CHRYSANTHEMUM_BLUE_POEM, MAPLE_BLUE_POEM).score == [('Three blue ribbons with poem', 3)]
```
