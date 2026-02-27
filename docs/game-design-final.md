# 고스톱 P2P 모바일 게임 — 확정 설계 문서

> 이 문서는 기존 탐색/리서치 문서(`game-design.md`)의 내용을 종합하여
> **확정된 기술 스택, 아키텍처, 개발 계획**을 정리한 최종 사양서입니다.

---

## 1. 프로젝트 개요

| 항목 | 확정 사양 |
|------|-----------|
| 프로젝트명 | 고스톱 P2P |
| 게임 종류 | 2인 맞고 (고스톱) |
| 기본 룰셋 | **서울 표준룰** (모든 규칙 Config화) |
| 플랫폼 | Android / iOS (크로스플랫폼) + **PWA (웹)** |
| 네트워크 | P2P (서버리스 게임 세션) |
| 매칭 방식 | **방 코드 공유 + 랜덤 매칭** 모두 제공 |
| 개발 인원 | 1인 개발 기준 |
| MVP 목표 기간 | 4~6주 |
| 패키지명 | **com.gostop.p2p** |
| 다국어 | **한/영 병기** |
| 로그인 | **없음** (익명 플레이) |
| 데이터 저장 | **로컬** (SharedPreferences) |

---

## 2. 확정 기술 스택

| 레이어 | 확정 기술 | 선정 이유 |
|--------|-----------|-----------|
| 프레임워크 | **Flutter 3.27 Stable** | WebRTC 라이브러리 풍부, 2D 카드게임 최적, 크로스플랫폼 |
| 언어 | **Dart 3.6** | Flutter 네이티브, JS 고스톱 로직 포팅 용이 (500~800줄 수준) |
| Android 최소 | **API 23 (Android 6.0)** | 한국 사용자 99%+ 커버 |
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

### 4.4 룰 Config 구조 (확정)

> **원칙: 서울 표준룰을 기본값으로 하되, 모든 규칙 요소를 Config로 설정 가능하게 설계.**
> App Factory에서 Config만 바꿔 다양한 룰 변형 앱을 자동 생성한다.

```yaml
# 기본값: 서울 표준룰
rules:
  # 고/스톱 기준
  go_stop_threshold: 3      # 3점부터 고/스톱 선택 가능 (7점제도 가능)
  go_limit: null             # 고 횟수 제한 없음 (null = 무제한)

  # 특수 규칙 (모두 on/off 가능)
  ssangpi: true              # 쌍피: 같은 월 피 2장 한번에 → 2피
  bomb: true                 # 폭탄(뻑): 바닥 3장 + 손패 1장
  shake: true                # 흔들기(뻑): 손패 같은 월 3장 → 배율 2배
  ttadak: true               # 따닥: 내 카드 + 뒤집은 카드 같은 월 → 연속 획득

  # 배수(벌칙) 규칙 (모두 on/off 가능)
  gwangbak: true             # 광박: 광 0장이면 패배 시 2배
  pibak: true                # 피박: 상대보다 피 적으면 2배
  gobak: true                # 고박: 상대 '고' 상태에서 내가 이기면 2배
  meongdda: true             # 멍따: 동물 7장 이상이면 배율 추가
  bibak: true                # 비박: 비 맞으면 2배

  # 게임 속도
  speed_multiplier: 1.0      # 1.0=일반, 1.5=스피드, 2.0=번개
  turn_timeout_sec: 30       # 턴 제한시간 (초)
```

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
| **Phase 1** | 룰 엔진 + **AI 대전** | 2주 | 룰 엔진(Config 기반) + 기본 AI + UI + 단위테스트 |
| **Phase 2** | AI 강화 + 마감 | 1주 | **룰 기반 휴리스틱** AI (난이도별) + 밸런스 조정 |
| **Phase 3** | P2P 온라인 | 2주 | WebRTC 연결 + 이벤트 동기화 + 재연결 |
| **Phase 4** | 매칭 서버 + 배포 | 1주 | Signaling 서버 + 로비(방코드+랜덤) + 스토어 배포 |

**총 MVP: 6주**

> **Phase 1 확정 사항:**
> - 상대방: **기본 AI** (랜덤 가중치 수준, Phase 2에서 강화)
> - 카드 에셋: **오픈소스 차용** (라이선스 확인 필수)
> - 테스트: **룰 엔진 단위테스트** (덱/매칭/점수 100% 커버)
> - 효과음/애니메이션: **MVP 후 추가** (Phase 1~2는 기능에 집중)

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

### 9.1 비용 목표: 월 $0

Oracle Cloud Free Tier를 활용해 **모든 서버를 무료**로 운영한다.

### 9.2 Oracle Cloud Free Tier 구성

| 리소스 | Free Tier 사양 | 용도 |
|--------|---------------|------|
| **VM (ARM)** | 4 OCPU / 24GB RAM (항상 무료) | Signaling + coturn 통합 |
| **VM (AMD)** | 1/8 OCPU / 1GB RAM × 2대 (항상 무료) | 백업/모니터링 |
| **부트 볼륨** | 200GB 총 (항상 무료) | OS + 로그 |
| **네트워크** | 월 10TB 아웃바운드 (항상 무료) | P2P 시그널링 + TURN relay |
| **로드밸런서** | 1대 (항상 무료) | HTTPS 종단 |

> Oracle Cloud "Always Free" 티어는 기간 제한 없이 영구 무료.
> 크레딧 소진/30일 트라이얼 종료와 무관하게 유지됨.

### 9.3 서버 배치 (단일 VM 통합)

```
Oracle Cloud ARM VM (4 OCPU / 24GB RAM)
 ├ Node.js        → Signaling 서버 (Socket.io, 포트 3000)
 ├ coturn          → STUN + TURN 서버 (포트 3478/5349)
 └ Nginx           → 리버스 프록시 + HTTPS (Let's Encrypt)
```

2인 맞고는 트래픽이 극소량이므로 **단일 VM에 전부 올려도 충분**.
ARM 4 OCPU / 24GB RAM은 동시 수천 세션도 처리 가능.

### 9.4 전체 서버 비용표

| 서버 | 역할 | 기술 | 호스팅 | 비용 |
|------|------|------|--------|------|
| Signaling | 방 매칭, ICE/SDP 교환 | Socket.io (Node.js) | Oracle Cloud VM | **$0** |
| STUN | NAT 타입 확인 | coturn | Oracle Cloud VM | **$0** |
| TURN | 방화벽 뚫기 백업 | coturn | Oracle Cloud VM | **$0** |
| Analytics | 사용자 데이터 | Firebase | Google | **$0** |
| HTTPS 인증서 | TLS 암호화 | Let's Encrypt | 자동 갱신 | **$0** |
| 도메인 | (선택) 커스텀 도메인 | Freenom 등 | 무료 도메인 가능 | **$0** |

**총 서버 비용: 월 $0**

### 9.5 Oracle Cloud 초기 세팅

```bash
# 1. VM 생성 후 SSH 접속
ssh -i key.pem ubuntu@<VM_PUBLIC_IP>

# 2. coturn 설치
sudo apt update && sudo apt install -y coturn
sudo systemctl enable coturn

# 3. coturn 설정 (/etc/turnserver.conf)
listening-port=3478
tls-listening-port=5349
realm=gostop.example.com
server-name=gostop.example.com
fingerprint
lt-cred-mech
user=gostop:password
total-quota=100
stale-nonce=600

# 4. Node.js + Signaling 서버
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
npm init -y && npm install socket.io express

# 5. Nginx + Let's Encrypt
sudo apt install -y nginx certbot python3-certbot-nginx
sudo certbot --nginx -d gostop.example.com

# 6. 방화벽 (Oracle Cloud Security List)
# 포트 개방: 80, 443, 3000, 3478, 5349, 49152-65535(UDP)
```

### 9.6 Signaling 서버 코드

```js
// signaling.js (Node.js + Socket.io)
const io = require('socket.io')(server, {
  cors: { origin: '*' }
});

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

### 9.7 Flutter 클라이언트 ICE 설정

```dart
final iceServers = [
  // Google 공개 STUN (백업)
  {'urls': 'stun:stun.l.google.com:19302'},
  // Oracle Cloud VM의 coturn
  {
    'urls': 'stun:<VM_PUBLIC_IP>:3478',
  },
  {
    'urls': 'turn:<VM_PUBLIC_IP>:3478',
    'username': 'gostop',
    'credential': 'password',
  },
];
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

## 12. 수익 모델 (확정)

| 수익원 | 방식 | 예상 |
|--------|------|------|
| **광고** | AdMob: **게임 종료 후 전면광고 + 하단 배너** | 기본 수익원 |
| **스킨** | 카드 디자인 판매 (인앱 구매) | 프리미엄 수익 |
| **프리미엄** | 광고 제거 유료 버전 | 일회성 구매 |

> **광고 타이밍**: 게임 중에는 광고 없음. 게임 종료 화면에서 전면(interstitial) 표시.
> 하단 배너는 로비/대기 화면에서만 표시. 플레이 중 방해 최소화.

---

## 13. 스케일업: App Factory — 완전 자동 Daily 워크플로 (확정)

MVP 성공 후 **템플릿 기반 파생앱 대량 생산**.
변형 축 **전부 조합** (테마 × 룰 × AI), **완전 자동**, 배포는 **Google Play + 웹(PWA)**.

### 13.1 확정 사양

| 항목 | 확정 |
|------|------|
| 변형 축 | 테마 × 룰 × AI **전부 조합** |
| 자동화 수준 | **완전 자동** (사람은 모니터링만) |
| 배포 타겟 | **Google Play (APK/AAB) + 웹 (PWA)** |
| 자동화 도구 | GitHub Actions + LLM API |

### 13.2 변형 매트릭스

3축 전체 조합으로 **최대 192개 앱** 생산 가능:

| 축 | 변형 | 수 |
|----|------|-----|
| **UI 테마** | 클래식, 애니, 레트로, 미니멀, 네온, 전통, 수묵화, 팝아트 | 8 |
| **룰 변형** | 정통, 빠른게임, 3점제, 7점제, 쌍피없음, 번개 | 6 |
| **AI 난이도** | easy, normal, hard, expert | 4 |

```
8 테마 × 6 룰 × 4 AI = 192 조합
```

각 조합은 Config 1개 = 앱 1개.

### 13.3 하루 자동 생성 파이프라인

```
┌─────────────────────────────────────────────────────────────┐
│  00:00  Scheduler (GitHub Actions cron)                     │
│    ↓                                                        │
│  00:01  Idea Agent (LLM)                                    │
│         - 어제 Analytics 데이터 분석                          │
│         - 미생성 조합 중 다음 Config 선택                      │
│         - 앱 이름/설명/키워드 생성                             │
│    ↓                                                        │
│  00:05  Asset Agent (이미지 생성 AI)                          │
│         - 아이콘, 카드 디자인, 스크린샷 생성                    │
│    ↓                                                        │
│  00:15  Code Generator                                      │
│         - 템플릿 복사 + Config 적용                           │
│         - 테마 CSS/위젯 주입                                  │
│         - 룰 파라미터 설정                                    │
│         - AI 레벨 설정                                       │
│    ↓                                                        │
│  00:20  Build Agent (GitHub Actions)                        │
│         - flutter build appbundle (Google Play)             │
│         - flutter build web (PWA)                           │
│         - 자동 테스트 실행                                    │
│    ↓                                                        │
│  00:40  Publish Agent                                       │
│         - Google Play: AAB 업로드 (Developer API)            │
│         - PWA: Firebase Hosting / GitHub Pages 배포          │
│         - 스토어 설명 + 스크린샷 자동 등록                      │
│    ↓                                                        │
│  01:00  완료 → Slack/Discord 알림                            │
│                                                             │
│  매일 23:00  Analytics Agent                                │
│         - Firebase에서 DAU/retention/수익 수집                │
│         - LLM 분석 → 내일 생성할 조합 우선순위 결정             │
└─────────────────────────────────────────────────────────────┘
```

**소요 시간: 약 1시간/앱 (사람 개입 0)**

### 13.4 Config 예시

```yaml
# config/gostop_anime_fast_easy.yaml
app_id: com.gostop.anime.fast.easy
app_name: "고스톱 애니 스피드"
version: 1.0.0

theme:
  name: anime
  card_style: cute_rounded
  background: pastel_gradient
  font: "NanumBarunGothic"

rules:
  variant: fast        # 빠른게임 (3점제)
  go_limit: 3
  ssangpi: true
  bomb: true
  speed_multiplier: 1.5

ai:
  level: easy           # 초보용
  strategy: random_weighted
  think_time_ms: 500

monetization:
  ads: true
  ad_provider: admob
  rewarded_video: true
  iap_skins: false

deploy:
  google_play: true
  pwa: true
  pwa_host: firebase    # Firebase Hosting
```

### 13.5 멀티 에이전트 구조 (확정)

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  Idea    │──▶│  Asset   │──▶│  Code    │──▶│  Build   │──▶│ Publish  │──▶│Analytics │
│  Agent   │   │  Agent   │   │  Agent   │   │  Agent   │   │  Agent   │   │  Agent   │
└──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
 LLM API        이미지 AI       Template       GitHub         Play API      Firebase
 (Anthropic)    (Stability)     + Patch        Actions        + Firebase    + LLM
```

| 에이전트 | 입력 | 출력 | 도구 |
|----------|------|------|------|
| Idea Agent | Analytics 데이터 | Config YAML | Anthropic API |
| Asset Agent | Config (테마) | 아이콘, 카드 이미지, 스크린샷 | Stability AI / OpenAI 이미지 |
| Code Agent | Config + Template | 완성된 Flutter 프로젝트 | Python 스크립트 |
| Build Agent | Flutter 프로젝트 | APK/AAB + PWA | GitHub Actions |
| Publish Agent | 빌드 산출물 | 스토어 등록 완료 | Google Play API + Firebase Hosting |
| Analytics Agent | Firebase 데이터 | 성과 리포트 + 다음 우선순위 | Firebase + Anthropic API |

### 13.6 듀얼 배포: Google Play + PWA (확정)

| 플랫폼 | 빌드 | 배포 | 비용 |
|--------|------|------|------|
| **Google Play** | `flutter build appbundle` | Google Play Developer API | $25 일회성 (개발자 등록) |
| **PWA (웹)** | `flutter build web` | Firebase Hosting / GitHub Pages | $0 |

PWA 장점:
- 설치 없이 브라우저에서 즉시 플레이
- 링크 공유만으로 사용자 유입
- Apple 심사 없이 iOS도 커버 (홈 화면 추가)

### 13.7 App Factory 리포 구조 (확정)

```
gostop-app-factory/
 template/                    # 공통 코드 (90%)
  lib/
   engine/                    # 룰 엔진
   ai/                        # AI 플레이어
   ui/                        # 카드 UI
   network/                   # WebRTC P2P
  web/                        # PWA 셸
  assets/                     # 기본 에셋
 variants/                    # 변형 리소스
  themes/
   anime/ classic/ retro/ minimal/ neon/ traditional/ ink/ popart/
  rules/
   standard.yaml fast.yaml 3point.yaml 7point.yaml nossangpi.yaml lightning.yaml
  ai_levels/
   easy.yaml normal.yaml hard.yaml expert.yaml
 configs/                     # 생성된 Config들
  gostop_anime_fast_easy.yaml
  gostop_retro_standard_hard.yaml
  ...
 generator/                   # 앱 생성기
  generate_app.py             # Config → Flutter 프로젝트
  idea_agent.py               # LLM 기반 Config 생성
  asset_agent.py              # 이미지 AI 생성
 publisher/                   # 배포 자동화
  playstore_upload.py         # Google Play API
  pwa_deploy.sh               # Firebase Hosting 배포
 analytics/                   # 성과 분석
  collect.py                  # Firebase 데이터 수집
  analyze.py                  # LLM 분석 + 다음 우선순위
 .github/workflows/
  daily_generate.yml          # 매일 자동 생성 cron
  build_and_deploy.yml        # 빌드 + 배포
 apps/                        # 생성된 앱들 (output)
```

### 13.8 GitHub Actions: Daily cron 워크플로

```yaml
# .github/workflows/daily_generate.yml
name: Daily App Generate

on:
  schedule:
    - cron: '0 0 * * *'  # 매일 00:00 UTC
  workflow_dispatch:       # 수동 실행도 가능

jobs:
  generate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Idea Agent - Generate Config
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: python generator/idea_agent.py

      - name: Asset Agent - Generate Images
        env:
          STABILITY_API_KEY: ${{ secrets.STABILITY_API_KEY }}
        run: python generator/asset_agent.py

      - name: Code Agent - Generate App
        run: python generator/generate_app.py

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'

      - name: Build AAB (Google Play)
        run: |
          cd apps/latest/
          flutter pub get
          flutter build appbundle

      - name: Build Web (PWA)
        run: |
          cd apps/latest/
          flutter build web

      - name: Publish to Google Play
        env:
          PLAY_SERVICE_ACCOUNT: ${{ secrets.PLAY_SERVICE_ACCOUNT }}
        run: python publisher/playstore_upload.py

      - name: Deploy PWA to Firebase
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
        run: bash publisher/pwa_deploy.sh

      - name: Notify
        run: |
          curl -X POST ${{ secrets.DISCORD_WEBHOOK }} \
            -H 'Content-Type: application/json' \
            -d '{"content": "New app deployed!"}'
```

### 13.9 스케일 전략 (확정)

```
Phase A (1~2주):  20개 생성 → DAU/retention 데이터 수집
Phase B (3주):    상위 5개 선별 → 성공 패턴 분석 (어떤 테마×룰×AI 조합?)
Phase C (4주~):   성공 패턴 기반 80개 변형 집중 생산
Phase D (운영):   Analytics Agent가 자동으로 다음 조합 결정
```

### 13.10 예상 수익

```
100 앱 × $30/month 평균 = $3,000/month
상위 10% 앱이 80% 수익 담당 → 히트 앱 집중 변형
```

### 13.11 비용 요약 (App Factory 운영)

| 항목 | 비용 |
|------|------|
| 서버 (Oracle Cloud) | $0 |
| LLM API (Anthropic) | ~$10/월 (Config 생성) |
| 이미지 AI | ~$5/월 (아이콘/카드) |
| Google Play 등록 | $25 일회성 |
| Firebase Hosting | $0 (무료 티어) |
| GitHub Actions | $0 (무료 티어, 2000분/월) |
| **총 운영 비용** | **~$15/월** |

---

## 14. 확정 사양 요약 (최종)

```
[프로젝트]
  게임:          2인 맞고 (고스톱)
  패키지명:       com.gostop.p2p
  기본 룰셋:      서울 표준룰 (모든 규칙 Config화)
  다국어:         한/영 병기

[기술 스택]
  프레임워크:     Flutter 3.27 Stable (Dart 3.6)
  Android 최소:  API 23 (Android 6.0)
  네트워크:       WebRTC DataChannel (P2P)
  동기화:         Event Sync + State Hash 검증
  네트워크 모델:   클라이언트-호스트
  Signaling:     Socket.io (Node.js)
  NAT 우회:      coturn (STUN/TURN)
  서버 호스팅:    Oracle Cloud Free Tier (ARM VM)
  상태 관리:      Riverpod

[게임 규칙 Config]
  고/스톱 기준:   Config (기본 3점)
  특수 규칙:      쌍피/폭탄/흔들기/따닥 (모두 Config on/off)
  배수 규칙:      광박/피박/고박/멍따/비박 (모두 Config on/off)

[AI]
  Phase 1:       랜덤 가중치 (기본)
  Phase 2:       룰 기반 휴리스틱 (난이도별)

[사용자 경험]
  로그인:         없음 (익명 플레이)
  매칭 방식:      방 코드 공유 + 랜덤 매칭 (둘 다)
  데이터 저장:     로컬 (SharedPreferences)
  효과음/애니:     MVP 후 추가
  카드 에셋:       오픈소스 차용

[수익화]
  광고:          AdMob (게임 종료 후 전면 + 하단 배너)
  스킨:          카드 디자인 인앱구매
  프리미엄:       광고 제거 유료

[인프라]
  Analytics:     Firebase
  CI/CD:         GitHub Actions
  배포:          Google Play + PWA (Firebase Hosting)
  서버 비용:      월 $0 (Oracle Cloud Always Free)
  MVP 기간:      6주 (4 Phase)
  테스트:         룰 엔진 단위테스트

[App Factory]
  변형 축:        테마 × 룰 × AI (전부 조합, 최대 192개)
  자동화:         완전 자동 (LLM → 코드 → 빌드 → 배포)
  배포:           Google Play + PWA
  생산량:         1개/일
  Play 정책 대응:  차별화 극대화 (이름/아이콘/테마 차별)
  리포 구조:       분리 (gostop-p2p + gostop-app-factory)
  Daily 파이프라인: GitHub Actions cron (매일 00:00)
  에이전트:        Idea → Asset → Code → Build → Publish → Analytics
  운영 비용:       ~$15/월
```

---

> 리서치 및 탐색 자료는 [`game-design.md`](game-design.md)를 참고하세요.
