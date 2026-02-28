# App Factory — 고스톱 파생앱 자동 생산 시스템

테마 × 룰 × AI 조합으로 **최대 192개** 변형 앱을 자동 생성하는 파이프라인.

## 변형 매트릭스

| 축 | 변형 | 수 |
|----|------|-----|
| **UI 테마** | classic, anime, retro, minimal, neon, traditional, ink, popart | 8 |
| **룰 변형** | standard, fast, three_point, seven_point, no_ssangpi, lightning | 6 |
| **AI 난이도** | easy, normal, hard, expert | 4 |

```
8 테마 × 6 룰 × 4 AI = 192 조합
```

## 사용법

### 1. Config 생성

```bash
# 전체 192개 Config 생성
python generator/generate_configs.py

# 특정 조합만
python generator/generate_configs.py --theme anime --rule fast --ai easy

# 미리보기
python generator/generate_configs.py --dry-run --limit 10
```

### 2. 앱 생성

```bash
# 특정 Config로 앱 생성
python generator/generate_app.py configs/gostop_anime_fast_easy.yaml

# 최신 Config 1개
python generator/generate_app.py --latest

# 전체 Config 일괄 생성
python generator/generate_app.py --all --limit 5
```

### 3. 빌드

```bash
cd apps/gostop_anime_fast_easy/app
flutter pub get
flutter build appbundle  # Google Play
flutter build web        # PWA
```

### 4. 배포

```bash
# Google Play
PLAY_SERVICE_ACCOUNT='...' python publisher/playstore_upload.py

# PWA (Firebase)
FIREBASE_TOKEN='...' bash publisher/pwa_deploy.sh
```

### 5. Analytics

```bash
python analytics/collect.py   # 데이터 수집
python analytics/analyze.py   # 분석 + 추천
```

## 자동화 (GitHub Actions)

- **Daily cron**: `.github/workflows/daily_generate.yml` — 매일 00:00 UTC 자동 실행
- **수동 실행**: GitHub Actions에서 workflow_dispatch로 실행 가능

### 필요한 Secrets

| Secret | 용도 |
|--------|------|
| `ANTHROPIC_API_KEY` | Idea Agent (LLM 기반 조합 선택) |
| `STABILITY_API_KEY` | Asset Agent (이미지 생성) |
| `PLAY_SERVICE_ACCOUNT` | Google Play 업로드 |
| `FIREBASE_TOKEN` | PWA 배포 |
| `DISCORD_WEBHOOK` | 알림 |

## 파이프라인 흐름

```
Idea Agent → Config 생성 → Asset Agent → Code Agent → Build → Publish → Analytics
   (LLM)     (YAML)       (이미지AI)   (Flutter)   (AAB/PWA)  (Store)   (Firebase)
```

## 디렉토리 구조

```
factory/
├── variants/           # 변형 정의
│   ├── themes/         # 8개 테마 YAML
│   ├── rules/          # 6개 룰 YAML
│   └── ai_levels/      # 4개 AI YAML
├── configs/            # 생성된 Config (gitignore)
├── generator/          # 생성 스크립트
│   ├── generate_configs.py   # Config 조합 생성
│   ├── generate_app.py       # Config → Flutter 프로젝트
│   └── idea_agent.py         # LLM 기반 조합 선택
├── publisher/          # 배포 스크립트
│   ├── playstore_upload.py   # Google Play API
│   └── pwa_deploy.sh         # Firebase Hosting
├── analytics/          # 성과 분석
│   ├── collect.py            # Firebase 데이터 수집
│   └── analyze.py            # LLM 분석 + 추천
└── apps/               # 생성된 앱 (gitignore)
```
