# 화투 카드 이미지 에셋 (오픈소스)

> 48장 화투 카드 이미지를 확보하기 위한 오픈소스 에셋 조사 결과.

## 추천 순위

### 1순위: Marcus Richert의 Hwatu 이미지 ★★★ (한국 화투 전용)
- **URL**: https://marcusrichert.com/images/hwatu/
- **Wikimedia**: https://commons.wikimedia.org/wiki/Category:SVG_Hwatu
- **License**: **CC BY-SA 4.0** (상업적 사용 가능, 출처 표기 필수)
- **Format**: SVG (벡터, 무한 해상도)
- **48장 커버**: YES
- **특징**:
  - **한국 화투 스타일** (일본 하나후다가 아님!)
  - Board Game Arena의 고스톱 게임에서 실제 사용 중
  - 광(gwang), 열(yul) 등 한국식 카드 타입명 사용
  - Louie Mantia Jr.의 원작을 한국 화투 색감으로 리컬러링
- **적합도**: 최고. 고스톱 게임에 바로 사용 가능

### 2순위: dotty-dev/Hanafuda-Louie-Recolor ★★ (GitHub 호스팅)
- **URL**: https://github.com/dotty-dev/Hanafuda-Louie-Recolor
- **SVG**: https://github.com/dotty-dev/Hanafuda-Louie-Recolor/tree/master/svg
- **PNG**: https://github.com/dotty-dev/Hanafuda-Louie-Recolor/tree/master/png
- **License**: **CC BY-SA 4.0**
- **Format**: SVG + PNG
- **48장 커버**: YES (12월 × 4장)
- **네이밍**: `Hanafuda_[Month]_[Type].svg` (예: `Hanafuda_January_Hikari.svg`)
- **특징**:
  - GitHub에서 바로 다운로드 가능
  - 깔끔한 모던 벡터 일러스트
  - 일본 하나후다 스타일 → 11/12월 스왑 + 한국 띠 텍스트 필요
- **적합도**: 높음. 약간의 수정 필요

### 3순위: sunduk/freegostop ★★ (한국 고스톱 전용)
- **URL**: https://github.com/sunduk/freegostop
- **이미지**: `client/Assets/resources/atlas/allcard.png` (스프라이트 시트)
- **License**: **상업적/비상업적 자유 사용** (README에 명시)
- **Format**: PNG 스프라이트 아틀라스
- **48장 커버**: YES (스프라이트 시트에 포함)
- **특징**:
  - 한국 고스톱 전용 디자인
  - 카드 상단에 숫자 표시 (초보자 친화적)
  - Unity5 프로젝트 → 스프라이트 시트 슬라이싱 필요
- **적합도**: 높음. 스프라이트 슬라이싱 작업 필요

## 추가 옵션

### 4. Wikimedia Commons SVG Hanafuda (일본 하나후다)
- **URL**: https://commons.wikimedia.org/wiki/Category:SVG_Hanafuda
- **License**: CC BY-SA 4.0
- **특징**: 여러 색상 변형 (검정/빨강 테두리, 초록 식물 등), 50개+ SVG
- **주의**: 일본 스타일 → 한국 고스톱용 수정 필요

### 5. nightsky30/koikoi
- **URL**: https://github.com/nightsky30/koikoi
- **License**: **GPL-2.0** (copyleft — 파생작도 GPL 필수)
- **Format**: SVG 64파일 (48 + 추가)
- **주의**: GPL 라이선스 때문에 상업용 앱에 부적합

## 라이선스별 사용 가능 여부

| 에셋 | 라이선스 | 상업적 사용 | 조건 |
|------|---------|------------|------|
| Marcus Richert Hwatu | CC BY-SA 4.0 | **가능** | 출처 표기 + 동일 라이선스 |
| Hanafuda-Louie-Recolor | CC BY-SA 4.0 | **가능** | 출처 표기 + 동일 라이선스 |
| sunduk/freegostop | 자유 사용 | **가능** | 없음 |
| nightsky30/koikoi | GPL-2.0 | 가능하나 제한 | 전체 앱 GPL 공개 필수 |
| sammy12519/Hanafuda | 없음 | **불가** | 저작권자 허가 필요 |

## 결론: 우리 프로젝트 적용 계획

1. **MVP**: Marcus Richert의 Hwatu SVG 사용 (1순위)
   - CC BY-SA 4.0 출처 표기 (앱 내 크레딧 화면)
   - SVG → Flutter에서 `flutter_svg` 패키지로 렌더링
2. **App Factory**: 테마별로 다른 에셋 세트 적용
   - 클래식: Marcus Richert Hwatu
   - 모던: Hanafuda-Louie-Recolor (커스터마이징)
   - 미니멀: AI 생성 카드
3. **출처 표기 문구 예시**:
   ```
   Card artwork based on work by Marcus Richert and Louie Mantia Jr.
   Licensed under CC BY-SA 4.0
   ```
