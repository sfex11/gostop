# 참고 리소스 디렉토리

> Phase 1 개발 시작 전, GitHub에서 수집한 오픈소스 참고 자료를 정리한 디렉토리입니다.

## 디렉토리 구조

```
references/
├── README.md                  # 이 파일
├── rule-engines/              # 고스톱 룰 엔진 참고 코드 (Python/C/JS)
│   └── README.md
├── card-assets/               # 화투 카드 이미지 에셋 (오픈소스)
│   └── README.md
├── flutter-cardgame/          # Flutter 카드게임 UI 참고
│   └── README.md
└── flutter-webrtc/            # Flutter WebRTC P2P 참고
    └── README.md
```

## Phase별 활용 계획

| Phase | 참고 디렉토리 | 활용 내용 |
|-------|-------------|-----------|
| Phase 1 | `rule-engines/` | 고스톱 룰 로직을 Dart로 포팅 |
| Phase 1 | `card-assets/` | 오픈소스 화투 이미지 적용 |
| Phase 1 | `flutter-cardgame/` | 카드 위젯, 드래그&드롭, 프로젝트 구조 |
| Phase 2 | `rule-engines/` | AI 전략 로직 참고 |
| Phase 3 | `flutter-webrtc/` | DataChannel P2P, Signaling 구현 |
| Phase 4 | `flutter-webrtc/` | 매칭 서버 구현 |

## 라이선스 요약

모든 참고 리포는 **상업적 사용 가능한 오픈소스 라이선스**:

| 리포 | 라이선스 |
|------|---------|
| reidlindsay/gostop | MIT |
| skarl86/gostop_c | (확인 필요) |
| flutter/games | BSD-3-Clause |
| flutter/io_flip | BSD-3-Clause |
| flutter-webrtc-demo | MIT |
| peer_rtc | Apache-2.0 |
| flip_card | BSD-3-Clause |
| thedeck | MIT |
