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
