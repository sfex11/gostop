#!/usr/bin/env python3
"""
Google Play Store 자동 업로드

사전 준비:
  1. Google Play Developer 계정 등록 ($25)
  2. Service Account JSON 키 생성
  3. GitHub Secrets에 PLAY_SERVICE_ACCOUNT 등록

사용법:
  python playstore_upload.py                          # 최신 앱 업로드
  python playstore_upload.py --app-dir factory/apps/gostop_anime_fast_easy/
"""

import argparse
import json
import os
import sys
from pathlib import Path


FACTORY_DIR = Path(__file__).resolve().parent.parent
APPS_DIR = FACTORY_DIR / "apps"


def find_latest_app() -> Path | None:
    """최신 생성 앱 디렉토리 반환."""
    apps = sorted(APPS_DIR.iterdir(), key=lambda p: p.stat().st_mtime)
    app_dirs = [a for a in apps if a.is_dir() and (a / "metadata.json").exists()]
    return app_dirs[-1] if app_dirs else None


def find_aab(app_dir: Path) -> Path | None:
    """AAB 파일 경로 반환."""
    aab_dir = app_dir / "app" / "build" / "app" / "outputs" / "bundle" / "release"
    aab_files = list(aab_dir.glob("*.aab"))
    return aab_files[0] if aab_files else None


def upload_to_play_store(app_dir: Path):
    """Google Play Developer API로 AAB 업로드."""
    service_account = os.environ.get("PLAY_SERVICE_ACCOUNT")
    if not service_account:
        print("Error: PLAY_SERVICE_ACCOUNT 환경변수 없음", file=sys.stderr)
        print("  → Google Play Service Account JSON을 설정하세요.")
        sys.exit(1)

    # 메타데이터 로드
    meta_path = app_dir / "metadata.json"
    with open(meta_path) as f:
        metadata = json.load(f)

    app_id = metadata["app_id"]
    aab_path = find_aab(app_dir)

    if not aab_path:
        print(f"Error: AAB 파일을 찾을 수 없습니다 ({app_dir})", file=sys.stderr)
        sys.exit(1)

    print(f"앱 업로드: {metadata['name_ko']} ({app_id})")
    print(f"AAB 파일: {aab_path}")
    print(f"파일 크기: {aab_path.stat().st_size / 1024 / 1024:.1f} MB")

    try:
        from google.oauth2 import service_account as sa
        from googleapiclient.discovery import build
        from googleapiclient.http import MediaFileUpload
    except ImportError:
        print("google-api-python-client 패키지 필요:")
        print("  pip install google-api-python-client google-auth")
        sys.exit(1)

    # Service Account 인증
    sa_info = json.loads(service_account)
    credentials = sa.Credentials.from_service_account_info(
        sa_info,
        scopes=["https://www.googleapis.com/auth/androidpublisher"],
    )

    service = build("androidpublisher", "v3", credentials=credentials)

    # 1. 편집 세션 시작
    edit = service.edits().insert(
        packageName=app_id,
        body={},
    ).execute()
    edit_id = edit["id"]
    print(f"편집 세션: {edit_id}")

    # 2. AAB 업로드
    media = MediaFileUpload(str(aab_path), mimetype="application/octet-stream")
    bundle = service.edits().bundles().upload(
        packageName=app_id,
        editId=edit_id,
        media_body=media,
    ).execute()
    version_code = bundle["versionCode"]
    print(f"업로드 완료: versionCode={version_code}")

    # 3. 내부 테스트 트랙에 배포
    service.edits().tracks().update(
        packageName=app_id,
        editId=edit_id,
        track="internal",
        body={
            "releases": [{
                "versionCodes": [version_code],
                "status": "completed",
            }],
        },
    ).execute()

    # 4. 커밋
    service.edits().commit(
        packageName=app_id,
        editId=edit_id,
    ).execute()

    print(f"Play Store 배포 완료: {app_id} (internal track)")


def main():
    parser = argparse.ArgumentParser(description="Google Play Store 업로드")
    parser.add_argument("--app-dir", help="앱 디렉토리 경로")
    args = parser.parse_args()

    if args.app_dir:
        app_dir = Path(args.app_dir)
    else:
        app_dir = find_latest_app()

    if not app_dir or not app_dir.exists():
        print("Error: 앱 디렉토리를 찾을 수 없습니다.", file=sys.stderr)
        sys.exit(1)

    print(f"=== Play Store 업로드 ===")
    print(f"앱 디렉토리: {app_dir}")
    upload_to_play_store(app_dir)


if __name__ == "__main__":
    main()
