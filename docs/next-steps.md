# 다음 단계 — Phase 3 완료, Phase 4 진행 예정

> 현재 상태: 룰 엔진 + HeuristicAgent + Flutter 앱 + **P2P 온라인 대전 + 효과음 + 테마**
> 목표: **서버 배포 + 스토어 제출 + App Factory**

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
| 규칙 설정 화면 | ✅ 완료 | GameConfig 13개 토글/슬라이더 + 사운드/테마 설정 |
| 전적 저장 | ✅ 완료 | 승/패/무 + 연승/연패 + 최고연승, SharedPreferences |
| 단위 테스트 | ✅ 완료 | 107+ tests |
| **P2P 프로토콜** | ✅ 완료 | GameMessage JSON 직렬화 + CardSerializer |
| **Signaling 서비스** | ✅ 완료 | WebSocket 클라이언트 (방 코드 + 랜덤 매칭) |
| **WebRTC P2P** | ✅ 완료 | DataChannel 기반 게임 메시지 송수신 |
| **온라인 게임 컨트롤러** | ✅ 완료 | OnlineGameNotifier (Host-Client 모델) |
| **P2P 로비 UI** | ✅ 완료 | 방 생성/참가/랜덤 매칭 화면 |
| **Signaling 서버** | ✅ 완료 | Node.js WebSocket (방/매칭/시그널 중계) |
| **효과음 서비스** | ✅ 완료 | SoundService + GameNotifier 통합 |
| **다크/라이트 테마** | ✅ 완료 | ThemeModeNotifier + 설정 페이지 토글 |
| **앱 아이콘/스플래시** | ✅ 완료 | flutter_launcher_icons + flutter_native_splash 설정 |

---

## Phase 3에서 추가된 사항

### Step 12: P2P 온라인 대전

#### 네트워크 레이어 (`app/lib/network/`)
- `game_message.dart` — P2P 게임 프로토콜 메시지
  - GameMessageType: gameInit, playCard, selectMatch, chooseGo/Stop, stateHash, ping/pong
  - CardSerializer: HwatooCard ↔ 이름 문자열 변환
  - GameConfigSerialization: GameConfig ↔ JSON 변환
- `signaling_service.dart` — WebSocket 시그널링 클라이언트
  - 방 생성/참가 (6자리 영대문자 코드)
  - 랜덤 매칭 대기열
  - WebRTC SDP/ICE 후보 교환
- `webrtc_service.dart` — WebRTC DataChannel P2P 서비스
  - PeerConnection + DataChannel 관리
  - Host: Offer 생성, Client: Answer 응답
  - 연결 상태 모니터링 (connected/disconnected/failed)
- `online_game_notifier.dart` — 온라인 게임 컨트롤러
  - Host-Client 모델 (Host=Player0, Client=Player1)
  - Seed 기반 덱 동기화 (양쪽 동일 게임 상태)
  - 카드 플레이 → 네트워크 전송 → 상대 상태 업데이트
  - 30초 재연결 대기 타이머

#### 서버 (`server/`)
- `signaling.js` — Node.js WebSocket 시그널링 서버
  - 방 생성/참가/나가기
  - 랜덤 매칭 (즉시 매칭 or 대기열)
  - WebRTC 시그널 중계
  - 30초 Heartbeat (연결 유지)
  - `/health` 엔드포인트 (상태 모니터링)

#### UI (`app/lib/ui/`)
- `online_lobby_page.dart` — P2P 대전 로비
  - 방 만들기 (코드 표시 + 클립보드 복사)
  - 방 코드 입력 + 참가
  - 랜덤 매칭 (대기 인디케이터 + 취소)
  - 에러 배너
- `online_game_page.dart` — 온라인 대전 게임 화면
  - 연결 상태 인디케이터 (초록/빨강)
  - 내 턴 표시
  - 상대 연결 끊김 다이얼로그
- `lobby_page.dart` — P2P 대전 버튼 활성화

### Step 13: 마감

- `sound_service.dart` — 효과음 서비스
  - audioplayers 패키지 기반
  - 8종 효과음 (카드, 쓸, 고/스톱, 승/패, 탭)
  - ON/OFF + 볼륨 조절 (SharedPreferences 저장)
  - GameNotifier에 통합 (카드 플레이, 캡처, 고/스톱, 게임 종료)
- `theme_service.dart` — 테마 관리
  - ThemeModeNotifier (Riverpod)
  - 다크/라이트 전환 (SharedPreferences 저장)
  - GameColors 유틸리티 (테마 인식 색상)
- 앱 아이콘/스플래시 — 설정 파일 준비
  - `flutter_launcher_icons.yaml`
  - `flutter_native_splash.yaml`
  - 에셋 디렉토리 (assets/icon/, assets/sounds/)

---

## 다음 단계 (Phase 4: 배포 & App Factory)

### Step 14: 서버 배포
- Oracle Cloud Free Tier VM 세팅
- coturn (STUN/TURN) 설치 + 설정
- Signaling 서버 배포 (PM2 + Nginx)
- HTTPS 인증서 (Let's Encrypt)
- 방화벽 규칙 설정

### Step 15: 앱 에셋 제작
- 실제 효과음 MP3 파일 추가 (freesound.org 등)
- 앱 아이콘 디자인 + 생성 (`dart run flutter_launcher_icons`)
- 스플래시 스크린 로고 + 생성 (`dart run flutter_native_splash:create`)

### Step 16: 스토어 배포
- Google Play 개발자 등록 ($25)
- APK/AAB 빌드 + 서명
- 스토어 설명/스크린샷 준비
- PWA (Flutter Web) 빌드 + Firebase Hosting 배포

### Step 17: App Factory 구축
- 템플릿 리포 분리
- Config 기반 변형 생성기
- Daily cron 파이프라인 (GitHub Actions)

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
| P2P 통신 | WebRTC DataChannel |
| 시그널링 | WebSocket (Node.js) |
| 네트워크 모델 | Host-Client (Host=게임 권한) |
| 동기화 | Seed 기반 덱 + Event Sync |
| 효과음 | audioplayers |
| 테마 | Material3 다크/라이트 |
| 최소 타겟 | Android API 23, iOS 12 |
