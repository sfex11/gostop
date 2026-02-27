# 고스톱 게임 설계 문서

## 오픈소스 리포 분석 및 활용 가이드

고스톱 오픈소스 리포를 분석한 결과, Python 콘솔 버전부터 Unity 버전까지 다양한 예시가 존재합니다. 이 리포들을 fork하거나 구조를 참고해 규칙 로직을 빠르게 구현할 수 있습니다.

### 주요 리포 추천

- **[reidlindsay/gostop](https://github.com/reidlindsay/gostop)** (Python, MIT 라이선스):
  간단한 콘솔 기반 고스톱 구현으로, 덱 셔플/배분/기본 규칙이 잘 짜여 있음. 초보자가 로직 이해하기 딱 좋고, 테스트 코드 없지만 확장 쉬움.

- **[JJANGCUTE/matgo](https://github.com/JJANGCUTE/matgo)** (Unity5/C#, 상업 이용 OK):
  2인 맞고(고스톱)로 컴퓨터 대전 모드 완성. 심플한 화투 이미지(숫자 표시 추가)와 UI 포함, 네트워크 대전 계획 중. 그래픽 자산 바로 쓸 수 있음.

- **[2Ju0/Go-stop-game](https://github.com/2Ju0/Go-stop-game)** (언어 미상, 한국어):
  플레이어/바닥패 정보 출력하며 승자 결정 로직 중심. 턴 기반 진행 예시가 유용.

- **[skarl86/gostop_c](https://github.com/skarl86/gostop_c)** (C 언어):
  고스톱 프로그래밍 학습용으로, 바닥 구현부터 팀 프로젝트 예시. 저수준 로직 참고.

### 리포 비교표

| 리포 이름 | 언어/엔진 | 강점 | 약점 |
|-----------|-----------|------|------|
| [reidlindsay/gostop](https://github.com/reidlindsay/gostop) | Python | 규칙 로직 순수 구현 | UI 없음 |
| [JJANGCUTE/matgo](https://github.com/JJANGCUTE/matgo) | Unity/C# | 그래픽+컴퓨터 대전 | 오래된 Unity5 |
| [2Ju0/Go-stop-game](https://github.com/2Ju0/Go-stop-game) | ? | 상태 출력/승자 로직 | 전체 코드 미확인 |
| [skarl86/gostop_c](https://github.com/skarl86/gostop_c) | C | 저수준 로직 학습용 | 학습 프로젝트 수준 |

### 활용 팁

1. **로직 추출**: Python 리포([reidlindsay/gostop](https://github.com/reidlindsay/gostop))에서 덱 클래스/턴 관리 복사해 시작. 족보 계산(광박, 멍따 등)은 함수화.

2. **자산 재사용**: [matgo](https://github.com/JJANGCUTE/matgo)의 화투 이미지 다운로드해 assets에 넣기. 숫자 표시 버전이라 UI 편함. 폰트는 무료(배달의민족 폰트).

3. **GitHub 활용**:
   - Fork → 자신의 리포에서 PR로 개선 추가.
   - Issue로 "이 리포 족보 로직 포팅" 새기기.
   - Actions로 테스트 자동화(예: Python pytest 추가).

4. **확장 아이디어**: [matgo](https://github.com/JJANGCUTE/matgo)처럼 AI 상대부터, Godot로 이식해 멀티플레이.

## P2P 멀티유저 네트워크 아키텍처

P2P 멀티유저 맞고/고스톱은 서버 비용 최소화하면서 실시간 턴 기반 플레이가 가능합니다. 클라이언트-호스트 모델(한 명이 호스트 역할)로 설계하면 동기화 쉽고, WebRTC나 Godot 내장 네트워킹으로 NAT 우회까지 커버할 수 있습니다.

### 핵심 아키텍처

P2P 맞고/고스톱은 턴 기반이니 완벽한 실시간 동기화보다 **입력 검증/상태 공유**가 핵심입니다.

- **모델**: 클라이언트-호스트 (Host가 게임 상태 관리, 클라이언트 입력 전송).
- **연결**: Signaling 서버(로비/방 코드) → WebRTC DataChannel or ENet/Steam P2P로 직접 연결.
- **동기화**: Lockstep(입력 순서 보장) + 주기적 상태 덤프(패 상태, 점수).
- **보안**: 입력 검증(치트 방지), 해시 기반 상태 확인.

| 구성 요소 | 역할 | 기술 예시 |
|-----------|------|-----------|
| Signaling | 로비/방 매칭, ICE 후보 교환 | Socket.io, Firebase, Noray HolePuncher |
| P2P 채널 | 입력/상태 전송 | WebRTC DataChannel, Godot MultiplayerPeer, Steam P2P |
| 동기화 | 패/턴/점수 일치 | RPC(턴 입력), Synchronizer(패 배열) |
| NAT 우회 | 방화벽 뚫기 | STUN/TURN 서버, Steam NAT |

### 네트워크 플로우

**1. 로비/매칭:**
- 플레이어1 호스트 생성 → 방 코드 생성 (Signaling 서버에 등록).
- 플레이어2 코드 입력 → 호스트 연결 시도 (P2P 핸드셰이크).

**2. 게임 초기화:**
- 호스트: 덱 셔플 → 초기 패 배분 (랜덤시드 공유로 재현성).
- 클라이언트: 호스트로부터 초기 상태 수신.

**3. 턴 진행 (턴 기반 핵심):**

```
클라이언트 입력: {type: "pick", cardId: "광1", target: "field"}
  → 호스트: 입력 검증
  → 상태 업데이트
  → 모든 피어에 브로드캐스트
  → 피어: 상태 적용
  → UI 업데이트
```

- 입력 지연: 100-200ms 타임아웃, 미동기화 시 호스트 재전송.

**4. 종료/재연결:**
- 승패 결정 → 점수 동기화.
- 연결 끊김: 호스트 대기 후 재연결 or 방 해체.

### Godot 구현 예시

Godot 4.x에서 P2P 가장 쉽습니다. Noray/Steam 플러그인으로 NAT Punchthrough 지원.

```gdscript
# NetworkManager.gd (자동 로드)
extends Node

var multiplayer_peer: ENetMultiplayerPeer # or WebRTCMultiplayerPeer

func host_game(port: int):
    multiplayer_peer = ENetMultiplayerPeer.new()
    multiplayer_peer.create_server(port, 2)  # 2인 플레이
    multiplayer.multiplayer_peer = multiplayer_peer
    rpc("sync_initial_state")  # 덱/패 동기

@rpc("any_peer", "call_local", "reliable")
func player_input(data: Dictionary):
    if multiplayer.is_server():
        process_input(data)  # 검증 후 상태 업데이트
        rpc("update_state", get_game_state())

func join_game(host_code: String):
    # Signaling으로 호스트 IP/코드 → 연결
    multiplayer_peer = ENetMultiplayerPeer.new()
    multiplayer_peer.create_client(host_ip, port)
    multiplayer.multiplayer_peer = multiplayer_peer
```

- **Synchronizer/Spawner**: 패 배열, UI 자동 동기.
- **Actions**: GitHub에서 빌드/테스트 자동화.

### WebRTC 구현 예시 (브라우저용)

React + Socket.io Signaling + WebRTC DataChannel.

**1. Signaling 서버 (Node.js):**

```js
io.on('join-room', (roomId, socketId) => {
  socket.join(roomId);
  // ICE 후보/SDP 교환
});
```

**2. 클라이언트:**

```js
const pc = new RTCPeerConnection();
pc.addEventListener('datachannel', e => {
  channel = e.channel;
  channel.onmessage = handleGameInput;  // 턴 입력 처리
});
// Offer/Answer 교환 후 채널로 {action: "go", score: 3} 전송
```

웹에서 빠르게 프로토타입 가능, 고스톱 규칙 로직은 기존 Python 리포 포팅.

### 주의점 & 최적화

- **치트 방지**: 호스트 검증 + 입력 재현(랜덤시드).
- **레이턴시**: 한국 내 50ms 이내, TURN 서버 백업.
- **스케일**: 2인 고스톱이니 P2P 완벽, 4인 되면 하이브리드 고려.
- **테스트**: Localhost + ngrok으로 P2P 시뮬.

## P2P 모바일 앱 개발 계획

맞고/고스톱 P2P 앱 개발의 핵심 4가지:
1. 게임 로직 재사용 (GitHub 오픈소스)
2. P2P 네트워크 연결
3. 모바일 UI
4. 부정행위 방지

아래는 GitHub 레포 최대 활용 전략 기반 개발 계획입니다.

### 1. 전체 시스템 아키텍처

```
모바일 앱 (Flutter / React Native)
        │
        │ WebRTC P2P 연결
        ▼
P2P Game Session
 ├ 플레이어1
 ├ 플레이어2
 └ 게임 상태 동기화

보조 서버 (Optional)
 ├ Matchmaking
 ├ NAT traversal (STUN/TURN)
 └ 부정행위 로그
```

**핵심 특징:**
- 게임 데이터는 P2P 직접 교환
- 서버는 매칭 + NAT 중계만
- 비용 거의 없음

### 2. 기술 스택 추천

**모바일 프레임워크:**

| 후보 | 추천 여부 | 이유 |
|------|-----------|------|
| Flutter | **추천** | P2P WebRTC 라이브러리 풍부, 2D 카드게임 구현 쉬움, 크로스플랫폼 |
| Unity (2D) | 대안 | 게임 특화, 에셋 풍부 |
| React Native | 대안 | 웹 개발자 친화적 |

**P2P 네트워크:**

| 후보 | 추천 여부 | 이유 |
|------|-----------|------|
| WebRTC | **추천** | 모바일 지원 좋음, NAT 문제 해결, Flutter plugin 존재 (flutter-webrtc) |
| libp2p | 대안 | 분산형 구조에 강점 |

### 3. GitHub 활용 전략

**고스톱 게임 로직 — GitHub에는 이미 여러 구현이 존재:**

| 리포 | 특징 | 활용 방법 |
|------|------|-----------|
| JavaScript 고스톱 (go-stop-js) | 카드 덱, 점수 계산, 룰 구현 | Dart로 포팅 |
| Python 고스톱 엔진 (py-gostop) | 룰 구현 완전, AI 포함 | 로직 참고 (모바일 직접 사용 어려움) |
| Unity 고스톱 (Unity-Gostop) | 카드 애니메이션, UI 참고 가능 | UI/UX 레퍼런스 |

### 4. 게임 엔진 구조

게임 핵심은 **State Machine**:

```
GameState:
  WAIT_PLAYER → DEAL → TURN → DRAW → CAPTURE → SCORE → END
```

**데이터 구조:**

```
GameState {
  players
  deck
  table_cards
  score
  turn
  events
}
```

### 5. P2P 동기화 구조

**방식 1: Event Sync**

```
Player1 → event 전송
  {
    type: "play_card",
    card: "3월"
  }
Player2 → 동일하게 적용
```

게임 상태는 각자 동일하게 계산.

**방식 2: Lockstep**

RTS 게임에서 많이 사용하는 방식:

```
frame 1: player1 action + player2 action
frame 2: ...
```

**장점:** 데이터 적음, 치트 방지에 유리.

### 6. P2P 연결 구조

**WebRTC 연결:**

```
Player A ──── Signaling Server ──── Player B
              (매칭/핸드셰이크)

연결 후:
Player A <──── P2P Direct ────> Player B
```

**필요 서버:**
- Matchmaking (방 매칭)
- Signaling (SDP/ICE 교환)
- STUN/TURN (NAT 우회)

무료 TURN 서버: **coturn** 활용 가능.

### 7. 게임 화면 구조

**기본 화면:**

```
-------------------------
     상대 카드

     테이블 카드

      내 카드
-------------------------
    [고]  [스톱]
```

**Flutter 위젯 구조:**

```
GamePage
 ├ OpponentHand
 ├ TableCards
 ├ MyHand
 ├ ActionButtons
 └ ScorePanel
```

### 8. 핵심 기능 목록

**기본 게임:**
- 카드 배포
- 카드 먹기 / 쌍피
- 고 / 스톱
- 점수 계산

**온라인:**
- 매칭
- P2P 연결
- Reconnect (재연결)

**UX:**
- 카드 애니메이션
- 효과음
- 점수 팝업

### 9. 치트 방지

P2P 게임에서 특히 중요한 부분.

**방법 1: Seed 기반 셔플**

```
seed = hash(playerA + playerB + time)
shuffle(seed)
```

둘 다 동일한 deck 생성.

**방법 2: Action 검증**

```
if illegal_move:
    reject
```

### 10. 개발 단계

| Phase | 내용 | 기간 | 주요 기능 |
|-------|------|------|-----------|
| Phase 1 | 오프라인 맞고 | 2주 | 카드, 룰, 점수 |
| Phase 2 | AI 대전 | 1주 | AI 상대 구현 |
| Phase 3 | P2P 온라인 | 2주 | WebRTC 연결, 이벤트 동기화 |
| Phase 4 | 매칭 서버 | 1주 | 로비, 방 매칭 |

**1인 개발 MVP: 약 4~6주**

### 11. 예상 문제 & 해결

| 문제 | 설명 | 해결 방법 |
|------|------|-----------|
| NAT 문제 | 모바일에서 자주 발생 | TURN 서버 (coturn) |
| 룰 차이 | 맞고 룰 지역마다 다름 | 설정 옵션 제공 |
| 싱크 오류 | P2P 게임에서 발생 가능 | State hash 검증 |

### 12. 수익 모델

- **광고**: AdMob
- **스킨**: 카드 디자인 판매
- **토큰**: 블록체인 카드 NFT (선택)

### 13. 추천 GitHub 리포 구성

```
gostop-p2p/
 ├ client/       # Flutter 앱
 ├ engine/       # 고스톱 규칙 엔진
 ├ network/      # WebRTC P2P 모듈
 └ server/       # Matchmaking 서버
```

## 복붙 수준 레포 조합 — 빠른 MVP 전략

핵심 전략: **3개 레포만 조합**하면 70% 완성.

```
1. 게임 엔진 (고스톱 룰)
2. 카드게임 UI
3. P2P 네트워크
```

### 1. 가장 쉬운 레포 조합 (추천)

```
flutter-cardgame  → 카드 UI
flutter-webrtc    → P2P 연결
gostop-js         → 게임 룰
```

**카드게임 UI — flutter-cardgame:**

이미 구현된 기능:
- 카드 이동 / 카드 애니메이션 / 드래그

```
deck → card → hand → table → animation
```

활용법: Solitaire → 맞고로 변환하면 됨.

**P2P 네트워크 — flutter-webrtc:**

```
Player A <------> Player B
         DataChannel
```

```dart
send(json)    // 이벤트 전송
receive(json) // 이벤트 수신
```

WebRTC는 Flutter에서 바로 사용 가능한 plugin. 샘플 프로젝트 **flutter-webrtc-demo**에 이미 방 생성, P2P 연결, 데이터 채널 구현됨.

활용법: 채팅 → 게임 이벤트로 바꾸면 됨.

**고스톱 게임 룰:**

GitHub에 이미 존재하는 구조:

```
deck → table → player → score → rules
```

대부분 JS로 구현. 고스톱 룰 코드는 500~800줄 수준이라 **JS → Dart 변환** 포팅이 어렵지 않음.

### 2. 실제 합치는 방법

**Step 1: 카드 UI Clone**

```bash
git clone flutter-cardgame
```

```
lib/
  card/
  deck/
  game/
  ui/
```

**Step 2: 게임 룰 추가**

```
lib/gostop/
  gostop_rules.dart
  gostop_score.dart
  gostop_deck.dart
```

**Step 3: WebRTC 추가**

```bash
flutter pub add flutter_webrtc
```

연결 코드:

```dart
RTCDataChannel.send({
  type: "play_card",
  card: "3월"
})
```

**Step 4: 게임 이벤트 구조**

모든 게임 행동을 JSON으로 전송:

```json
{ "action": "play_card", "card": 5 }
```

```json
{ "action": "go" }
```

### 3. 완성된 프로젝트 구조

```
gostop-p2p/
 lib/
  engine/
   gostop_rules.dart
   gostop_score.dart
  ui/
   card_widget.dart
   table_widget.dart
  network/
   webrtc_service.dart
  game/
   game_controller.dart
```

### 4. 실제 개발 시간

이 조합으로 이미 해결되는 비율:

| 영역 | 해결 비율 |
|------|-----------|
| UI | 40% |
| 네트워크 | 30% |
| 룰 | 30% |

**MVP: 2~3주** (기존 4~6주에서 단축)

### 5. 추가하면 좋은 레포

| 레포 | 용도 |
|------|------|
| flutter_card_animation | 카드 애니메이션 |
| riverpod | 상태 관리 |
| flame engine | 게임 엔진 |

### 6. 개발 순서 (중요)

카드게임 개발에서 **UI 먼저 만들면 실패**합니다.

올바른 순서:

```
1. 룰 엔진
2. 콘솔 시뮬레이션
3. UI 연결
4. P2P 연결
```

### 7. 최강 레포 조합 (최종 추천)

```
flutter-cardgame + flutter-webrtc-demo + gostop rules
```

이 조합이면 **코드 70% 이미 존재**.

### 8. 프로 개발 구조

실제 카드게임 회사가 사용하는 구조:

```
game-engine/   # 룰 엔진 (독립 모듈)
game-ui/       # UI 레이어
network/       # 통신 레이어
ai/            # AI 플레이어
```

각 레이어를 독립 모듈로 분리해 테스트/재사용성 극대화.

## AI 앱 팩토리 — 하루에 고스톱 앱 하나씩 만드는 구조

앱 생성 파이프라인 + 템플릿 기반 코드 생성 + 자동 퍼블리싱을 결합한 **App Factory** 형태.
핵심: **90%를 템플릿화하고 AI는 10%만 바꾸게 하는 것**.

### 1. 전체 구조 (App Factory)

```
Idea Generator (AI)
        │
        ▼
Variant Generator (룰 / UI / 테마 / 수익모델 조합)
        │
        ▼
Code Generator (template + AI patch)
        │
        ▼
Build System (Flutter build)
        │
        ▼
Publish Bot (Google Play 업로드)
```

하루에 하나씩 가능한 이유 — 바꾸는 건 이것뿐:
- UI 스킨
- 룰 변형
- 테마
- AI 난이도

### 2. 핵심 전략

앱을 **"제품"이 아니라 "파생상품"**으로 만든다:

```
고스톱 클래식
고스톱 프로
고스톱 빠른게임
고스톱 AI대전
고스톱 애니 스타일
고스톱 레트로
```

실제 코드 차이는 **UI theme / AI difficulty / rule config** 뿐.

### 3. 핵심 템플릿 구조

```
gostop-template/
 engine/     # 고스톱 룰
 ai/         # AI 플레이어
 ui/         # 카드 UI
 network/    # P2P (optional)
 skins/
  theme1/
  theme2/
  theme3/
```

AI는 여기서 **skin, rule, difficulty**만 변경.

### 4. AI 생성 프로세스

**Step 1: 아이디어 생성 (LLM)**

```
오늘의 앱 아이디어:
 "애니메이션 스타일 맞고"
 특징:
  - 빠른 게임
  - 귀여운 카드
  - 초보용 AI
```

**Step 2: Config 생성**

```json
{
  "theme": "anime",
  "ai_level": 1,
  "rule_variant": "fast",
  "ads": true
}
```

**Step 3: 코드 생성**

AI는 템플릿에 patch 적용:

```
generate_app(config) → apps/gostop_anime/
```

### 5. 코드 생성 방식

| 방법 | 설명 | 추천 |
|------|------|------|
| 템플릿 복사 | `cp template new_app` → AI가 수정 | 간단하지만 관리 어려움 |
| Config 기반 | `app = generate_app(config)` | **추천** — 일관성 유지 |

### 6. Config 예시

```yaml
app_name: gostop_anime
theme: anime
card_style: cute
ai: easy
speed: fast
ads: admob
```

### 7. 코드 생성 예

AI가 config에 따라 생성:

```dart
ThemeData theme = AnimeTheme();
```

```dart
AIPlayer(level: 1)
```

### 8. 자동 빌드 시스템

GitHub Actions 파이프라인:

```
generate app → build apk → upload store
```

### 9. 자동화 파이프라인

```
scheduler (daily)
  ↓
AI generate config
  ↓
code generator
  ↓
flutter build
  ↓
upload playstore
```

### 10. 핵심 AI 역할

AI는 새로운 앱을 만들지 않음. 대신:
- Config 생성
- 테마 생성
- 아이콘 생성
- 스토어 설명 생성

### 11. UI 자동 생성

이미지 생성 AI 활용 (OpenAI 이미지 모델, Stability AI):

```
card art → icon → screenshot
```

### 12. AI 생성 앱 일정 예시

| 일차 | 앱 |
|------|-----|
| Day 1 | 고스톱 클래식 |
| Day 2 | 고스톱 애니 |
| Day 3 | 고스톱 빠른게임 |
| Day 4 | 고스톱 AI 챌린지 |

### 13. 수익 구조

```
100개 앱 × $50/month = $5,000/month
```

### 14. 카드게임이 적합한 이유

카드게임은 **로직 동일 + UI 동일**이라 파생앱 생산이 매우 쉬움.

### 15. 고급 구조 (AI 멀티 에이전트)

```
Idea Agent
  ↓
Design Agent
  ↓
Code Agent
  ↓
Test Agent
  ↓
Publish Agent
```

GitHub + OpenAI 기반으로 구축 가능.

### 16. 현실적인 결과

```
1달: 30 앱
1년: 300 앱
```

AI 앱 공장(App Factory) 구조는 현재 AI 시대에서 가장 강력한 1인 개발 전략 중 하나.

## 고스톱 앱 100개 자동 생성 시스템 아키텍처

LLM + GitHub + 자동 퍼블리싱으로 "고스톱 앱 100개 자동 생성"하는 App Factory 아키텍처.
핵심: **템플릿 기반 + config 생성 + 자동 빌드 + 자동 스토어 업로드**.

### 1. 전체 시스템 아키텍처

```
Scheduler (Daily / CI)
        │
        ▼
Idea Agent (LLM)
        │
        ▼
Config Generator
        │
        ▼
Code Generator (template + patch)
        │
        ▼
Git Repository Creator
        │
        ▼
Build Pipeline (CI/CD)
        │
        ▼
Store Publisher
        │
        ▼
Analytics Collector
```

| 컴포넌트 | 설명 |
|----------|------|
| Idea Agent | 오늘 만들 앱 컨셉 생성 |
| Config Generator | 앱 설정 생성 |
| Code Generator | 템플릿 기반 코드 생성 |
| Build Pipeline | Flutter APK/AAB 빌드 |
| Publisher | Google Play 업로드 |

### 2. 핵심 개념: Template + Variant

앱을 새로 만드는 게 아니라 **template + variant**:

```
template: 고스톱 기본 게임
variant:  UI 테마 / AI 난이도 / 룰 변형 / 속도
```

### 3. Repository 구조

```
gostop-app-factory/
 template/
  engine/        # 고스톱 룰
  ai/            # AI 플레이어
  ui/            # 카드 UI
  network/       # P2P (optional)
 variants/
  themes/
  rules/
  ai_levels/
 generator/
  generate_app.py
 apps/
  generated_apps/
 publisher/
  playstore_upload.py
```

### 4. Config 기반 생성

AI는 코드를 직접 쓰지 않고 **config만 생성**:

```yaml
app_name: gostop_fast_anime
theme: anime
ai_level: easy
rule_variant: fast
ads: admob
icon_style: cartoon
```

### 5. 코드 생성 방식

```python
generate_app(config)
```

동작 순서:
1. Template 복사
2. Config 적용
3. Assets 생성
4. Metadata 생성

### 6. 생성된 앱 구조

```
apps/
 gostop_fast_anime/
  lib/
  assets/
  pubspec.yaml
  config.yaml
```

### 7. LLM 역할

LLM은 **앱 아이디어 + config 생성**:

```json
{
  "app_name": "GOSTOP ANIME SPEED",
  "theme": "anime",
  "ai": "easy",
  "speed": "fast"
}
```

LLM 후보: OpenAI 모델, Anthropic 모델.

### 8. GitHub 자동 리포 생성

GitHub API 사용:

```python
create_repo(app_name)
push_code()
```

### 9. CI/CD 빌드 시스템

GitHub Actions 파이프라인:

```yaml
name: build
steps:
  - checkout
  - setup flutter
  - flutter pub get
  - flutter build appbundle
```

### 10. 자동 퍼블리싱

Google Play Developer API 사용:

```python
upload_aab()
```

필요: Service Account JSON Key.

### 11. 앱 아이콘 / 이미지 자동 생성

이미지 생성 AI 활용 (OpenAI 이미지 모델, Stability AI):

```
icon → card design → screenshot
```

### 12. 앱 설명 자동 생성

스토어 텍스트도 LLM 생성:

```
Play the fastest GoStop game ever!
Cute anime cards and smart AI opponents.
```

### 13. Analytics 수집

Firebase Analytics 추천:

```
DAU → retention → ads revenue
```

### 14. 자동 개선 루프

Analytics → AI 분석 → 다음 variant:

```
analytics
  ↓
LLM 분석
  ↓
next variant
```

예: 애니 테마 앱 수익 좋음 → 비슷한 테마 5개 생성.

### 15. 멀티 에이전트 구조

```
Idea Agent
  ↓
Design Agent
  ↓
Code Agent
  ↓
Build Agent
  ↓
Publish Agent
  ↓
Analytics Agent
```

각 에이전트는 LLM 사용.

### 16. 하루 자동 생성 파이프라인

```
00:00 scheduler
  ↓ AI idea
  ↓ config 생성
  ↓ code generate
  ↓ repo push
  ↓ CI build
  ↓ store upload
```

### 17. 100개 앱 운영 구조

```
apps/
 ├ gostop_fast
 ├ gostop_anime
 ├ gostop_retro
 ├ gostop_ai_pro
 ├ gostop_minimal
```

실제 코드는 **90% 동일**.

### 18. 서버 비용

거의 없음. 필요한 것:
- CI build
- AI API

**월 $20~50**

### 19. 예상 수익 구조

```
100 앱 × $30/month = $3,000/month
```

### 20. 현실적인 성공 전략

100개 앱을 무작정 만드는 게 아니라:

```
20개 생성
  ↓
상위 5개 선택
  ↓
그 변형 80개 생성
```

데이터 기반으로 성공 패턴을 찾아 집중 생산.
