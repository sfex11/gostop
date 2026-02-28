#!/usr/bin/env python3
"""
앱 생성기 — Config YAML → Flutter 프로젝트 생성

사용법:
  python generate_app.py configs/gostop_anime_fast_easy.yaml
  python generate_app.py configs/gostop_anime_fast_easy.yaml --output apps/
  python generate_app.py --latest          # configs/ 에서 최신 1개
  python generate_app.py --all --limit 5   # 전체 중 5개
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

import yaml


FACTORY_DIR = Path(__file__).resolve().parent.parent
PROJECT_ROOT = FACTORY_DIR.parent
TEMPLATE_APP = PROJECT_ROOT / "app"
TEMPLATE_ENGINE = PROJECT_ROOT / "engine"
APPS_DIR = FACTORY_DIR / "apps"


def load_config(config_path: str) -> dict:
    """Config YAML 로드."""
    with open(config_path) as f:
        return yaml.safe_load(f)


def generate_flutter_project(config: dict, output_dir: Path) -> Path:
    """Config를 기반으로 Flutter 프로젝트 생성."""
    slug = config["slug"]
    app_dir = output_dir / slug
    engine_dir = app_dir / "engine"

    if app_dir.exists():
        print(f"  기존 프로젝트 삭제: {app_dir}")
        shutil.rmtree(app_dir)

    # 1. 템플릿 복사
    print(f"  템플릿 복사: app/ → {app_dir}/app/")
    app_src = app_dir / "app"
    shutil.copytree(TEMPLATE_APP, app_src, ignore=shutil.ignore_patterns(
        ".dart_tool", "build", ".flutter-plugins*", "*.lock",
        ".packages", ".metadata",
    ))

    print(f"  엔진 복사: engine/ → {app_dir}/engine/")
    shutil.copytree(TEMPLATE_ENGINE, engine_dir, ignore=shutil.ignore_patterns(
        ".dart_tool", "build", ".packages",
    ))

    # 2. pubspec.yaml 패치
    patch_pubspec(app_src, config)

    # 3. main.dart 패치 (테마, 앱 이름)
    patch_main_dart(app_src, config)

    # 4. GameConfig 패치 (기본 룰 변경)
    patch_game_config(app_src, config)

    # 5. AI 설정 패치
    patch_ai_config(app_src, config)

    # 6. Android 매니페스트 패치 (패키지명, 앱 이름)
    patch_android_manifest(app_src, config)

    # 7. 앱 Config YAML 복사 (런타임 참조용)
    config_dest = app_src / "assets" / "app_config.yaml"
    config_dest.parent.mkdir(parents=True, exist_ok=True)
    with open(config_dest, "w") as f:
        yaml.dump(config, f, allow_unicode=True, default_flow_style=False)

    # 8. 앱 메타데이터 생성
    write_metadata(app_dir, config)

    print(f"  완료: {app_dir}")
    return app_dir


def patch_pubspec(app_src: Path, config: dict):
    """pubspec.yaml에 앱 이름/버전/패키지명 적용."""
    pubspec_path = app_src / "pubspec.yaml"
    content = pubspec_path.read_text()

    # 앱 이름 변경
    content = re.sub(
        r'^name: .*$',
        f'name: {config["slug"]}',
        content,
        flags=re.MULTILINE,
    )
    # 설명 변경
    content = re.sub(
        r'^description: .*$',
        f'description: "{config["app"]["description_en"]}"',
        content,
        flags=re.MULTILINE,
    )
    # 버전 변경
    content = re.sub(
        r'^version: .*$',
        f'version: {config["version"]}',
        content,
        flags=re.MULTILINE,
    )

    # app_config.yaml 에셋 추가
    if "app_config.yaml" not in content:
        content = content.replace(
            "    - assets/icon/",
            "    - assets/icon/\n    - assets/app_config.yaml",
        )

    pubspec_path.write_text(content)
    print("    pubspec.yaml 패치 완료")


def patch_main_dart(app_src: Path, config: dict):
    """main.dart에 테마 색상, 앱 타이틀 적용."""
    main_path = app_src / "lib" / "main.dart"
    content = main_path.read_text()

    # 앱 타이틀 변경
    content = content.replace(
        "title: '고스톱'",
        f"title: '{config['app']['name_ko']}'",
    )

    # 시드 색상 변경
    seed_color = config["theme"]["seed_color"]
    content = content.replace(
        "seedColor: const Color(0xFF2E7D32)",
        f"seedColor: const Color({seed_color})",
    )

    main_path.write_text(content)
    print(f"    main.dart 패치 완료 (color: {seed_color})")


def patch_game_config(app_src: Path, config: dict):
    """GameNotifier의 기본 GameConfig를 룰 변형에 맞게 패치."""
    rules = config["rules"]
    # game_notifier.dart에서 기본 GameConfig 변경
    notifier_path = app_src / "lib" / "game" / "game_notifier.dart"
    if not notifier_path.exists():
        print("    game_notifier.dart 없음 — 스킵")
        return

    content = notifier_path.read_text()

    # GameConfig.standard 또는 GameConfig() 호출을 커스텀으로 변경
    custom_config = f"""GameConfig(
    scoreThreshold: {rules['score_threshold']},
    useSsangpi: {str(rules['use_ssangpi']).lower()},
    useBomb: {str(rules['use_bomb']).lower()},
    useSwing: {str(rules['use_swing']).lower()},
    useChongtong: {str(rules['use_chongtong']).lower()},
    usePiSteal: {str(rules['use_pi_steal']).lower()},
    useSweep: {str(rules['use_sweep']).lower()},
    useGwangBak: {str(rules['use_gwang_bak']).lower()},
    usePiBak: {str(rules['use_pi_bak']).lower()},
    useGoBak: {str(rules['use_go_bak']).lower()},
    useMungTung: {str(rules['use_mung_tung']).lower()},
    useGodori: {str(rules['use_godori']).lower()},
  )"""

    # GameConfig.standard → 커스텀 Config
    content = content.replace("GameConfig.standard", custom_config)
    # 단독 GameConfig() 호출도 변경
    content = re.sub(
        r'(?<!\.)GameConfig\(\)',
        custom_config,
        content,
    )

    notifier_path.write_text(content)
    print(f"    game_notifier.dart 패치 완료 (rule: {rules['id']})")


def patch_ai_config(app_src: Path, config: dict):
    """AI 난이도 설정 패치."""
    ai = config["ai"]
    notifier_path = app_src / "lib" / "game" / "game_notifier.dart"
    if not notifier_path.exists():
        return

    content = notifier_path.read_text()

    # AI think time 패치 (기본 700ms → 커스텀)
    think_time = ai["think_time_ms"]
    content = re.sub(
        r'Duration\(milliseconds:\s*700\)',
        f'Duration(milliseconds: {think_time})',
        content,
    )

    notifier_path.write_text(content)
    print(f"    AI 패치 완료 (difficulty: {ai['difficulty']}, think: {think_time}ms)")


def patch_android_manifest(app_src: Path, config: dict):
    """Android 패키지명, 앱 이름 변경."""
    manifest_path = app_src / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
    if not manifest_path.exists():
        print("    AndroidManifest.xml 없음 — 스킵")
        return

    content = manifest_path.read_text()
    content = content.replace(
        'android:label="gostop_app"',
        f'android:label="{config["app"]["name_ko"]}"',
    )
    manifest_path.write_text(content)

    # build.gradle applicationId 패치
    gradle_path = app_src / "android" / "app" / "build.gradle"
    if not gradle_path.exists():
        gradle_path = app_src / "android" / "app" / "build.gradle.kts"
    if gradle_path.exists():
        gradle_content = gradle_path.read_text()
        gradle_content = re.sub(
            r'applicationId\s*[=:]\s*"[^"]*"',
            f'applicationId = "{config["app_id"]}"',
            gradle_content,
        )
        gradle_path.write_text(gradle_content)
        print(f"    Android 패치 완료 (id: {config['app_id']})")


def write_metadata(app_dir: Path, config: dict):
    """앱 메타데이터 (스토어 등록용) 생성."""
    metadata = {
        "app_id": config["app_id"],
        "slug": config["slug"],
        "version": config["version"],
        "name_ko": config["app"]["name_ko"],
        "name_en": config["app"]["name_en"],
        "description_ko": config["app"]["description_ko"],
        "description_en": config["app"]["description_en"],
        "theme": config["theme"]["id"],
        "rule": config["rules"]["id"],
        "ai": config["ai"]["id"],
    }
    meta_path = app_dir / "metadata.json"
    with open(meta_path, "w") as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)
    print(f"    metadata.json 생성 완료")


def find_latest_config() -> Path | None:
    """configs/ 에서 가장 최근 생성된 Config 반환."""
    configs_dir = FACTORY_DIR / "configs"
    configs = sorted(configs_dir.glob("*.yaml"), key=lambda p: p.stat().st_mtime)
    return configs[-1] if configs else None


def main():
    parser = argparse.ArgumentParser(description="앱 생성기 — Config → Flutter 프로젝트")
    parser.add_argument("config", nargs="?", help="Config YAML 파일 경로")
    parser.add_argument("--latest", action="store_true", help="최신 Config 1개로 생성")
    parser.add_argument("--all", action="store_true", help="configs/ 전체 생성")
    parser.add_argument("--limit", type=int, help="--all 시 개수 제한")
    parser.add_argument("--output", default=str(APPS_DIR), help="출력 디렉토리")
    args = parser.parse_args()

    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)

    configs_to_process = []

    if args.config:
        configs_to_process.append(Path(args.config))
    elif args.latest:
        latest = find_latest_config()
        if latest:
            configs_to_process.append(latest)
        else:
            print("Error: configs/ 디렉토리에 Config 파일이 없습니다.", file=sys.stderr)
            sys.exit(1)
    elif args.all:
        configs_dir = FACTORY_DIR / "configs"
        configs_to_process = sorted(configs_dir.glob("*.yaml"))
        if args.limit:
            configs_to_process = configs_to_process[:args.limit]
    else:
        parser.print_help()
        sys.exit(1)

    if not configs_to_process:
        print("Error: 처리할 Config가 없습니다.", file=sys.stderr)
        sys.exit(1)

    print(f"=== 앱 생성 시작 ({len(configs_to_process)}개) ===\n")

    for i, config_path in enumerate(configs_to_process, 1):
        config = load_config(config_path)
        print(f"[{i}/{len(configs_to_process)}] {config['slug']}")
        generate_flutter_project(config, output_dir)
        print()

    print(f"=== 완료: {len(configs_to_process)}개 앱 생성 → {output_dir}/ ===")


if __name__ == "__main__":
    main()
