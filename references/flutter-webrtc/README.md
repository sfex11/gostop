# Flutter WebRTC P2P 참고 리포

## 핵심 참고 (우선순위순)

### 1. flutter-webrtc/flutter-webrtc-demo — 공식 DataChannel 샘플 ★★★
- **URL**: https://github.com/flutter-webrtc/flutter-webrtc-demo
- **Stars**: ~1,200
- **License**: MIT
- **활용**: DataChannel P2P 데이터 교환, Signaling 프로토콜
- **핵심 파일**:
  - `lib/src/call_sample/data_channel_sample.dart` — **DataChannel 설정 및 사용법**
  - `lib/src/call_sample/signaling.dart` — **SDP/ICE 교환 프로토콜**
  - `lib/src/call_sample/call_sample.dart` — 전체 연결 플로우

### 2. flutter-webrtc/flutter-webrtc-server — Signaling 서버
- **URL**: https://github.com/flutter-webrtc/flutter-webrtc-server
- **Stars**: ~812
- **License**: MIT
- **활용**: Go 언어 시그널링 서버, TURN 서버 REST API
- **핵심**: demo와 조합하면 완전한 WebRTC 시스템

### 3. Piasy/FlutterWebRTCDataChannel — DataChannel 전용 플러그인
- **URL**: https://github.com/Piasy/FlutterWebRTCDataChannel
- **Stars**: ~67
- **License**: MIT
- **활용**: DataChannel만 집중한 미니멀 구현 (비디오/오디오 없음)

### 4. peer_rtc (pub.dev) — 게임용 P2P 라이브러리 ★★
- **URL**: https://pub.dev/packages/peer_rtc
- **License**: Apache-2.0
- **활용**: 게임 특화 P2P, StarHub(호스트 모델), 바이너리 최적화 (~80% 대역폭 절약)
- **특징**:
  - `StarHub` — 호스트-클라이언트 토폴로지 (우리 모델과 동일!)
  - `MeshHub` — 풀 메시
  - `Packer` — 바이너리 델타 최적화
  - 자동 재연결 + 지수 백오프

### 5. peerdart (pub.dev) — PeerJS 포트
- **URL**: https://pub.dev/packages/peerdart
- **GitHub**: https://github.com/MuhammedKpln/peerdart
- **License**: MIT
- **활용**: 가장 간단한 P2P API (PeerJS 스타일)

## DataChannel 핵심 API 패턴

```dart
// 데이터 채널 생성
var dc = await peerConnection.createDataChannel('game', RTCDataChannelInit());

// 텍스트 전송
dc.send(RTCDataChannelMessage('{"action":"play_card","card":"5H"}'));

// 바이너리 전송
dc.send(RTCDataChannelMessage.fromBinary(Uint8List.fromList([...])));

// 메시지 수신
dc.onMessage = (RTCDataChannelMessage data) {
  if (data.isBinary) { /* 바이너리 처리 */ }
  else { print(data.text); }
};

// 상태 모니터링
dc.onDataChannelState = (RTCDataChannelState state) {
  print('State: $state');
};
```

## 우리 프로젝트에 적용할 것

| 관심사 | 1순위 | 2순위 |
|--------|------|------|
| DataChannel 구현 | flutter-webrtc-demo | Piasy/FlutterWebRTCDataChannel |
| Signaling 서버 | flutter-webrtc-server (Go) | 직접 Node.js 구현 |
| 게임용 P2P 라이브러리 | peer_rtc (StarHub) | peerdart (간단한 API) |
| P2P 아키텍처 패턴 | Niggelgame/flutter-games | xajik/thedeck |
