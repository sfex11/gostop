#!/usr/bin/env python3
"""
Config 조합 생성기 — 테마 × 룰 × AI 전체 조합 생성

사용법:
  python generate_configs.py                    # 전체 192개 조합 생성
  python generate_configs.py --limit 5          # 상위 5개만 생성
  python generate_configs.py --theme anime      # 애니 테마만
  python generate_configs.py --rule fast        # 스피드 룰만
  python generate_configs.py --ai easy          # Easy AI만
"""

import argparse
import os
import sys
from itertools import product
from pathlib import Path

import yaml


FACTORY_DIR = Path(__file__).resolve().parent.parent
VARIANTS_DIR = FACTORY_DIR / "variants"
CONFIGS_DIR = FACTORY_DIR / "configs"


def load_variants(category: str, filter_id: str | None = None) -> list[dict]:
    """variants 디렉토리에서 YAML 파일 로드."""
    variants_path = VARIANTS_DIR / category
    variants = []
    for f in sorted(variants_path.glob("*.yaml")):
        with open(f) as fh:
            data = yaml.safe_load(fh)
            if filter_id and data["id"] != filter_id:
                continue
            variants.append(data)
    return variants


def generate_app_id(theme_id: str, rule_id: str, ai_id: str) -> str:
    """패키지명 생성: com.gostop.<theme>.<rule>.<ai>"""
    return f"com.gostop.{theme_id}.{rule_id}.{ai_id}"


def generate_config(theme: dict, rule: dict, ai: dict) -> dict:
    """하나의 완성된 앱 Config 생성."""
    theme_id = theme["id"]
    rule_id = rule["id"]
    ai_id = ai["id"]

    app_id = generate_app_id(theme_id, rule_id, ai_id)
    slug = f"gostop_{theme_id}_{rule_id}_{ai_id}"

    # 앱 이름: 테마 + 룰 조합
    app_name_ko = f"{theme['name_ko']}"
    if rule_id != "standard":
        app_name_ko += f" {rule['name_ko']}"

    app_name_en = f"{theme['name_en']}"
    if rule_id != "standard":
        app_name_en += f" {rule['name_en']}"

    # 설명: 테마 설명 + 룰 설명 + AI 설명
    desc_ko = f"{theme['description_ko']}. {rule['description_ko']}. {ai['description_ko']}."
    desc_en = f"{theme['description_en']}. {rule['description_en']}. {ai['description_en']}."

    return {
        "app_id": app_id,
        "slug": slug,
        "version": "1.0.0",
        # 앱 정보
        "app": {
            "name_ko": app_name_ko,
            "name_en": app_name_en,
            "description_ko": desc_ko,
            "description_en": desc_en,
        },
        # 테마 설정
        "theme": {
            "id": theme_id,
            "card_style": theme["card_style"],
            "background": theme["background"],
            "seed_color": theme["seed_color"],
            "font": theme.get("font", "NanumGothic"),
            "icon_style": theme.get("icon_style", "default"),
        },
        # 룰 설정 (GameConfig 매핑)
        "rules": {
            "id": rule_id,
            "score_threshold": rule["score_threshold"],
            "use_ssangpi": rule["use_ssangpi"],
            "use_bomb": rule["use_bomb"],
            "use_swing": rule["use_swing"],
            "use_chongtong": rule["use_chongtong"],
            "use_pi_steal": rule["use_pi_steal"],
            "use_sweep": rule["use_sweep"],
            "use_gwang_bak": rule["use_gwang_bak"],
            "use_pi_bak": rule["use_pi_bak"],
            "use_go_bak": rule["use_go_bak"],
            "use_mung_tung": rule["use_mung_tung"],
            "use_godori": rule["use_godori"],
            "speed_multiplier": rule.get("speed_multiplier", 1.0),
        },
        # AI 설정
        "ai": {
            "id": ai_id,
            "strategy": ai["strategy"],
            "difficulty": ai["difficulty"],
            "think_time_ms": ai["think_time_ms"],
            "go_aggressiveness": ai.get("go_aggressiveness", 0.5),
        },
        # 수익화
        "monetization": {
            "ads": True,
            "ad_provider": "admob",
            "interstitial_on_game_end": True,
            "banner_in_lobby": True,
        },
        # 배포
        "deploy": {
            "google_play": True,
            "pwa": True,
            "pwa_host": "firebase",
        },
    }


def main():
    parser = argparse.ArgumentParser(description="Config 조합 생성기")
    parser.add_argument("--theme", help="특정 테마만 생성")
    parser.add_argument("--rule", help="특정 룰만 생성")
    parser.add_argument("--ai", help="특정 AI만 생성")
    parser.add_argument("--limit", type=int, help="생성 개수 제한")
    parser.add_argument("--dry-run", action="store_true", help="파일 생성 없이 목록만 출력")
    args = parser.parse_args()

    # 변형 로드
    themes = load_variants("themes", args.theme)
    rules = load_variants("rules", args.rule)
    ai_levels = load_variants("ai_levels", args.ai)

    if not themes:
        print(f"Error: 테마를 찾을 수 없습니다 (filter: {args.theme})", file=sys.stderr)
        sys.exit(1)
    if not rules:
        print(f"Error: 룰을 찾을 수 없습니다 (filter: {args.rule})", file=sys.stderr)
        sys.exit(1)
    if not ai_levels:
        print(f"Error: AI 레벨을 찾을 수 없습니다 (filter: {args.ai})", file=sys.stderr)
        sys.exit(1)

    total = len(themes) * len(rules) * len(ai_levels)
    print(f"조합: {len(themes)} 테마 × {len(rules)} 룰 × {len(ai_levels)} AI = {total}개")

    # 출력 디렉토리
    CONFIGS_DIR.mkdir(parents=True, exist_ok=True)

    count = 0
    for theme, rule, ai in product(themes, rules, ai_levels):
        if args.limit and count >= args.limit:
            break

        config = generate_config(theme, rule, ai)
        slug = config["slug"]

        if args.dry_run:
            print(f"  [{count+1}] {slug} — {config['app']['name_ko']}")
        else:
            config_path = CONFIGS_DIR / f"{slug}.yaml"
            with open(config_path, "w") as f:
                yaml.dump(config, f, allow_unicode=True, default_flow_style=False,
                          sort_keys=False)
            print(f"  [{count+1}] {config_path.name}")

        count += 1

    print(f"\n총 {count}개 Config {'미리보기' if args.dry_run else '생성 완료'}")
    if not args.dry_run:
        print(f"출력 경로: {CONFIGS_DIR}/")


if __name__ == "__main__":
    main()
