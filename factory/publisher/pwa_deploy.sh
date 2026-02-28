#!/bin/bash
# PWA 배포 — Firebase Hosting

set -euo pipefail

FACTORY_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APPS_DIR="$FACTORY_DIR/apps"

# 최신 앱 찾기
LATEST=$(ls -td "$APPS_DIR"/*/ 2>/dev/null | head -1)
if [ -z "$LATEST" ]; then
  echo "Error: 앱 디렉토리를 찾을 수 없습니다."
  exit 1
fi

APP_DIR="$LATEST/app"
WEB_BUILD="$APP_DIR/build/web"

if [ ! -d "$WEB_BUILD" ]; then
  echo "Error: Web 빌드를 찾을 수 없습니다: $WEB_BUILD"
  echo "먼저 'flutter build web'을 실행하세요."
  exit 1
fi

# 메타데이터 로드
META="$LATEST/metadata.json"
SLUG=$(python3 -c "import json; print(json.load(open('$META'))['slug'])" 2>/dev/null || echo "unknown")

echo "=== PWA 배포 ==="
echo "앱: $SLUG"
echo "빌드: $WEB_BUILD"

# Firebase 토큰 확인
if [ -z "${FIREBASE_TOKEN:-}" ]; then
  echo "Error: FIREBASE_TOKEN 환경변수 없음"
  echo "  → 'firebase login:ci'로 토큰을 생성하세요."
  exit 1
fi

# firebase.json 생성 (없으면)
FIREBASE_JSON="$APP_DIR/firebase.json"
if [ ! -f "$FIREBASE_JSON" ]; then
  cat > "$FIREBASE_JSON" <<EOF
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      { "source": "**", "destination": "/index.html" }
    ],
    "headers": [
      {
        "source": "**/*.@(js|css|png|jpg|gif|svg|woff2)",
        "headers": [
          { "key": "Cache-Control", "value": "max-age=31536000" }
        ]
      }
    ]
  }
}
EOF
  echo "firebase.json 생성 완료"
fi

# Firebase 배포
cd "$APP_DIR"
npx firebase-tools deploy --only hosting --token "$FIREBASE_TOKEN" --non-interactive

echo ""
echo "PWA 배포 완료: $SLUG"
