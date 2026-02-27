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
