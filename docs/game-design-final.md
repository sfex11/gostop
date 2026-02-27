# 고스톱 P2P 모바일 게임 — 확정 설계 문서

> 이 문서는 기존 탐색/리서치 문서(`game-design.md`)의 내용을 종합하여
> **확정된 기술 스택, 아키텍처, 개발 계획**을 정리한 최종 사양서입니다.

---

## 1. 프로젝트 개요

| 항목 | 확정 사양 |
|------|-----------|
| 프로젝트명 | 고스톱 P2P |
| 게임 종류 | 2인 맞고 (고스톱) |
| 플랫폼 | Android / iOS (크로스플랫폼) |
| 네트워크 | P2P (서버리스 게임 세션) |
| 개발 인원 | 1인 개발 기준 |
| MVP 목표 기간 | 4~6주 |

---

## 2. 확정 기술 스택

| 레이어 | 확정 기술 | 선정 이유 |
|--------|-----------|-----------|
| 프레임워크 | **Flutter** | WebRTC 라이브러리 풍부, 2D 카드게임 최적, 크로스플랫폼 |
| 언어 | **Dart** | Flutter 네이티브, JS 고스톱 로직 포팅 용이 (500~800줄 수준) |
| P2P 통신 | **WebRTC DataChannel** | 모바일 지원 우수, NAT 해결, `flutter_webrtc` 플러그인 |
| 상태 관리 | **Riverpod** | Flutter 생태계 표준, 게임 상태 관리에 적합 |
| Signaling | **Socket.io** | 로비/방 매칭, ICE 후보 교환용 경량 서버 |
| NAT 우회 | **coturn (STUN/TURN)** | 오픈소스, 무료, 모바일 NAT 문제 해결 |
| 광고 SDK | **AdMob** | 모바일 광고 표준 |
| Analytics | **Firebase Analytics** | DAU, retention, 광고 수익 추적 |
| CI/CD | **GitHub Actions** | 자동 빌드(APK/AAB) + 자동 테스트 |
| 스토어 배포 | **Google Play Developer API** | 자동 퍼블리싱 파이프라인 |

---

## 3. 시스템 아키텍처

### 3.1 전체 구조

```
┌─────────────────────────────────────────────┐
│              모바일 앱 (Flutter)               │
│  ┌──────────┐ ┌──────────┐ ┌──────────────┐ │
│  │ Game UI  │ │ Engine   │ │ Network      │ │
│  │ (카드/턴)│ │ (룰/점수)│ │ (WebRTC P2P) │ │
│  └──────────┘ └──────────┘ └──────────────┘ │
└──────────────────┬──────────────────────────┘
                   │ WebRTC DataChannel
                   ▼
          ┌─────────────────┐
          │  P2P Game Session │
          │  ├ 플레이어1 (Host) │
          │  └ 플레이어2 (Client)│
          └─────────────────┘

┌──────────────────────────────┐
│  보조 서버 (최소 비용)         │
│  ├ Signaling (Socket.io)     │
│  ├ STUN/TURN (coturn)        │
│  └ Analytics (Firebase)      │
└──────────────────────────────┘
```

### 3.2 네트워크 모델: 클라이언트-호스트

| 역할 | 책임 |
|------|------|
| Host (플레이어1) | 게임 상태 관리, 입력 검증, 덱 셔플, 상태 브로드캐스트 |
| Client (플레이어2) | 입력 전송, 상태 수신 및 적용, UI 렌더링 |

**게임 데이터는 P2P 직접 교환. 서버는 매칭 + NAT 중계만 담당.**

---

## 4. 게임 엔진 설계

### 4.1 State Machine

```
WAIT_PLAYER → DEAL → TURN → DRAW → CAPTURE → SCORE → END
                      ↑                        │
                      └────────────────────────┘
                           (고 선택 시 반복)
```

### 4.2 핵심 데이터 구조

```dart
class GameState {
  List<Player> players;    // 플레이어 2명
  List<Card> deck;         // 남은 덱
  List<Card> tableCards;   // 바닥패
  Map<String, int> score;  // 점수
  int currentTurn;         // 현재 턴
  List<GameEvent> events;  // 이벤트 로그
}
```

### 4.3 핵심 게임 규칙 (구현 대상)

| 기능 | 설명 |
|------|------|
| 카드 배포 | 48장 화투, 각 10장 + 바닥 8장 |
| 카드 매칭 | 같은 월 카드 매칭 → 획득 |
| 쌍피 / 따닥 | 특수 획득 규칙 |
| 폭탄 (뻑) | 바닥에 같은 월 3장 + 손패 1장 |
| 고 / 스톱 | 점수 도달 시 계속 or 종료 선택 |
| 점수 계산 | 광, 띠, 피, 동물 조합별 점수 |
| 족보 | 광박, 멍따, 고박, 비박, 피박 등 배율 |

---

## 5. P2P 네트워크 설계

### 5.1 연결 플로우

```
1. 로비/매칭
   Player1 → 방 생성 → Signaling 서버에 방 코드 등록
   Player2 → 코드 입력 → P2P 핸드셰이크

2. 게임 초기화
   Host → 덱 셔플 (랜덤시드 공유) → 초기 패 배분
   Client → 초기 상태 수신

3. 턴 진행
   Client → {type: "play_card", cardId: "광1"} → Host
   Host → 입력 검증 → 상태 업데이트 → 브로드캐스트
   Client → 상태 적용 → UI 업데이트

4. 종료/재연결
   승패 → 점수 동기화
   끊김 → 30초 대기 후 재연결 or 방 해체
```

### 5.2 동기화 방식: Event Sync (확정)

```dart
// 게임 이벤트 JSON 구조
{
  "action": "play_card",  // play_card | draw | go | stop | capture
  "card": 5,
  "turn": 12,
  "timestamp": 1709000000
}
```

- 턴 기반이므로 Lockstep까지 불필요, **Event Sync**로 충분
- 주기적 **State Hash 검증**으로 동기화 오류 감지
- 입력 지연 타임아웃: **200ms**, 미응답 시 Host 재전송

### 5.3 보안/치트 방지

| 방법 | 설명 |
|------|------|
| Seed 기반 셔플 | `seed = hash(playerA + playerB + timestamp)` → 양쪽 동일 덱 |
| Host 입력 검증 | 불법 수(없는 카드 내기 등) 즉시 reject |
| State Hash | 턴마다 `hash(gameState)` 비교, 불일치 시 Host 상태 강제 동기 |

---

## 6. 프로젝트 구조

```
gostop-p2p/
 lib/
  engine/                  # 게임 엔진 (독립 모듈)
   gostop_rules.dart       # 룰 엔진
   gostop_score.dart       # 점수 계산
   gostop_deck.dart        # 덱/카드 정의
  ai/                      # AI 플레이어
   ai_player.dart          # AI 로직
  ui/                      # UI 레이어
   card_widget.dart        # 카드 위젯
   table_widget.dart       # 테이블 위젯
   opponent_hand.dart      # 상대 카드
   score_panel.dart        # 점수판
   action_buttons.dart     # 고/스톱 버튼
  network/                 # 통신 레이어
   webrtc_service.dart     # WebRTC P2P
   signaling_service.dart  # Signaling 연결
  game/                    # 게임 컨트롤러
   game_controller.dart    # 상태 관리 (Riverpod)
   game_state.dart         # 상태 정의
 assets/                   # 화투 이미지, 효과음
 server/                   # Signaling 서버 (Node.js)
  signaling.js
 test/                     # 테스트
```

---

## 7. UI 설계

### 7.1 게임 화면 레이아웃

```
┌─────────────────────────┐
│     상대 카드 (뒷면)      │
│    ░░ ░░ ░░ ░░ ░░       │
├─────────────────────────┤
│      점수판 / 정보        │
├─────────────────────────┤
│     바닥 카드 (테이블)     │
│   🎴 🎴 🎴 🎴 🎴 🎴     │
├─────────────────────────┤
│      내 카드 (앞면)       │
│   🎴 🎴 🎴 🎴 🎴 🎴     │
├─────────────────────────┤
│     [고]     [스톱]      │
└─────────────────────────┘
```

### 7.2 Flutter 위젯 트리

```
GamePage
 ├ OpponentHand       # 상대 패 (뒷면)
 ├ ScorePanel         # 점수/턴 정보
 ├ TableCards         # 바닥 카드
 ├ MyHand             # 내 패 (터치/드래그)
 └ ActionButtons      # 고/스톱 버튼
```

### 7.3 핵심 UX 기능

- 카드 드래그 & 드롭
- 매칭 시 카드 이동 애니메이션
- 점수 획득 팝업
- 효과음 (카드 내기, 먹기, 고/스톱)

---

## 8. 개발 로드맵

### 8.1 개발 순서 (확정)

> 원칙: **룰 먼저, UI 나중. UI 먼저 만들면 실패한다.**

```
1. 룰 엔진 → 2. 콘솔 시뮬레이션 → 3. UI 연결 → 4. P2P 연결
```

### 8.2 Phase별 계획

| Phase | 내용 | 기간 | 산출물 |
|-------|------|------|--------|
| **Phase 1** | 오프라인 맞고 | 2주 | 룰 엔진 + 기본 UI + 로컬 2인 플레이 |
| **Phase 2** | AI 대전 | 1주 | AI 플레이어 (기본 전략) |
| **Phase 3** | P2P 온라인 | 2주 | WebRTC 연결 + 이벤트 동기화 + 재연결 |
| **Phase 4** | 매칭 서버 + 마감 | 1주 | Signaling 서버 + 로비 UI + 스토어 배포 |

**총 MVP: 6주**

### 8.3 오픈소스 활용 (레포 조합 전략)

기존 레포 3개 조합으로 **코드 70% 재사용**:

| 레포 | 활용 내용 | 포팅 방식 |
|------|-----------|-----------|
| flutter-cardgame | 카드 UI, 애니메이션, 드래그 | Solitaire → 맞고 변환 |
| flutter-webrtc-demo | 방 생성, P2P 연결, DataChannel | 채팅 → 게임 이벤트 변환 |
| 고스톱 JS/Python 리포 | 덱 클래스, 턴 관리, 점수 계산 | JS/Python → Dart 포팅 |

참고 리포:
- [reidlindsay/gostop](https://github.com/reidlindsay/gostop) — Python 룰 엔진
- [JJANGCUTE/matgo](https://github.com/JJANGCUTE/matgo) — Unity UI/그래픽 자산
- [skarl86/gostop_c](https://github.com/skarl86/gostop_c) — C 저수준 로직

---

## 9. 서버 인프라

### 9.1 필요 서버 (최소 구성)

| 서버 | 역할 | 기술 | 비용 |
|------|------|------|------|
| Signaling | 방 매칭, ICE/SDP 교환 | Socket.io (Node.js) | 무료 (Render/Railway) |
| STUN | NAT 타입 확인 | Google STUN (공개) | 무료 |
| TURN | 방화벽 뚫기 백업 | coturn (자체 호스팅) | $5~10/월 |
| Analytics | 사용자 데이터 | Firebase | 무료 |

**총 서버 비용: 월 $5~15**

### 9.2 Signaling 서버 코드

```js
// signaling.js (Node.js + Socket.io)
const io = require('socket.io')(server);

io.on('connection', socket => {
  socket.on('create-room', (roomId) => {
    socket.join(roomId);
    socket.emit('room-created', roomId);
  });

  socket.on('join-room', (roomId) => {
    socket.join(roomId);
    socket.to(roomId).emit('peer-joined', socket.id);
  });

  socket.on('signal', (data) => {
    socket.to(data.roomId).emit('signal', data);
  });
});
```

---

## 10. 치트 방지 상세

| 위협 | 대응 | 구현 |
|------|------|------|
| 덱 조작 | Seed 기반 셔플 | `seed = hash(A_id + B_id + timestamp)` |
| 불법 카드 내기 | Host 입력 검증 | 매 턴 유효성 체크 후 reject/accept |
| 상태 변조 | Hash 검증 | 턴마다 `sha256(state)` 교환 비교 |
| 통신 변조 | DTLS 암호화 | WebRTC 기본 내장 |

---

## 11. 예상 문제 & 해결

| 문제 | 발생 상황 | 해결 방법 |
|------|-----------|-----------|
| NAT 실패 | 양쪽 모바일, 제한적 네트워크 | TURN 서버 fallback (coturn) |
| 룰 차이 | 지역별 맞고 규칙 상이 | Config로 룰 변형 옵션 제공 |
| 싱크 오류 | 네트워크 지연/패킷 유실 | State Hash 불일치 시 Host 상태 강제 동기 |
| 연결 끊김 | 모바일 환경 불안정 | 30초 재연결 대기, 게임 상태 보존 |
| 레이턴시 | 해외 대전 | 한국 내 50ms 이내 목표, TURN 백업 |

---

## 12. 수익 모델

| 수익원 | 방식 | 예상 |
|--------|------|------|
| **광고** | AdMob (배너 + 리워드 영상) | 기본 수익원 |
| **스킨** | 카드 디자인 판매 (인앱 구매) | 프리미엄 수익 |
| **프리미엄** | 광고 제거 유료 버전 | 일회성 구매 |

---

## 13. 스케일업: App Factory 전략

MVP 성공 후 **템플릿 기반 파생앱 대량 생산** 전략.

### 13.1 핵심 개념

```
90% 템플릿 고정 + 10% 변경 (스킨/룰/AI) = 새로운 앱
```

### 13.2 변형 축

| 변형 요소 | 예시 |
|-----------|------|
| UI 테마 | 클래식, 애니, 레트로, 미니멀 |
| AI 난이도 | easy, normal, hard, expert |
| 룰 변형 | 빠른게임, 정통, 3점제, 7점제 |
| 게임 속도 | 일반, 스피드, 번개 |

### 13.3 자동화 파이프라인

```
Scheduler (Daily)
  ↓
LLM: Config 생성 (테마/룰/난이도 조합)
  ↓
Code Generator: 템플릿 + Config 적용
  ↓
GitHub Actions: Flutter build (APK/AAB)
  ↓
Google Play API: 자동 업로드
  ↓
Firebase: Analytics 수집
  ↓
LLM: 성과 분석 → 다음 Config 생성
```

### 13.4 App Factory 리포 구조

```
gostop-app-factory/
 template/           # 공통 코드 (90%)
  engine/
  ai/
  ui/
  network/
 variants/           # 변형 요소
  themes/
  rules/
  ai_levels/
 generator/          # 앱 생성기
  generate_app.py
 publisher/          # 자동 배포
  playstore_upload.py
 apps/               # 생성된 앱들
```

### 13.5 스케일 전략

```
Phase A: 20개 생성 → 데이터 수집
Phase B: 상위 5개 선별 → 성공 패턴 분석
Phase C: 성공 패턴 기반 80개 변형 집중 생산
```

### 13.6 멀티 에이전트 구조

```
Idea Agent → Design Agent → Code Agent → Build Agent → Publish Agent → Analytics Agent
```

각 에이전트는 LLM(Anthropic/OpenAI) 기반, GitHub API 연동.

---

## 14. 확정 사양 요약

```
게임:        2인 맞고 (고스톱)
프레임워크:   Flutter (Dart)
네트워크:     WebRTC DataChannel (P2P)
동기화:       Event Sync + State Hash 검증
네트워크 모델: 클라이언트-호스트
Signaling:   Socket.io (Node.js)
NAT 우회:    coturn (STUN/TURN)
상태 관리:    Riverpod
AI:          기본 전략 AI (Phase 2)
광고:        AdMob
Analytics:   Firebase
CI/CD:       GitHub Actions
배포:        Google Play (자동 퍼블리싱)
MVP 기간:    6주 (4 Phase)
서버 비용:    월 $5~15
```

---

> 리서치 및 탐색 자료는 [`game-design.md`](game-design.md)를 참고하세요.
