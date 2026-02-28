#!/usr/bin/env python3
"""
Idea Agent — LLM 기반 다음 Config 자동 선택

Analytics 데이터를 분석하여 다음에 생성할 테마×룰×AI 조합을 결정한다.
LLM API 없이도 동작 (규칙 기반 fallback).

사용법:
  python idea_agent.py                    # 다음 1개 조합 선택
  python idea_agent.py --count 3          # 다음 3개 조합 선택
  python idea_agent.py --use-llm          # LLM API 사용
"""

import argparse
import json
import os
import random
import sys
from itertools import product
from pathlib import Path

import yaml


FACTORY_DIR = Path(__file__).resolve().parent.parent
VARIANTS_DIR = FACTORY_DIR / "variants"
CONFIGS_DIR = FACTORY_DIR / "configs"
ANALYTICS_DIR = FACTORY_DIR / "analytics"


def load_variant_ids(category: str) -> list[str]:
    """변형 ID 목록 로드."""
    ids = []
    for f in sorted((VARIANTS_DIR / category).glob("*.yaml")):
        with open(f) as fh:
            data = yaml.safe_load(fh)
            ids.append(data["id"])
    return ids


def get_existing_configs() -> set[str]:
    """이미 생성된 Config의 slug 집합."""
    existing = set()
    for f in CONFIGS_DIR.glob("*.yaml"):
        existing.add(f.stem)
    return existing


def get_all_combinations() -> list[tuple[str, str, str]]:
    """모든 가능한 조합 생성."""
    themes = load_variant_ids("themes")
    rules = load_variant_ids("rules")
    ai_levels = load_variant_ids("ai_levels")
    return list(product(themes, rules, ai_levels))


def get_ungenerated_combinations() -> list[tuple[str, str, str]]:
    """아직 생성되지 않은 조합 목록."""
    all_combos = get_all_combinations()
    existing = get_existing_configs()

    ungenerated = []
    for theme, rule, ai in all_combos:
        slug = f"gostop_{theme}_{rule}_{ai}"
        if slug not in existing:
            ungenerated.append((theme, rule, ai))
    return ungenerated


def load_analytics_data() -> dict | None:
    """Analytics 리포트 로드 (있으면)."""
    report_path = ANALYTICS_DIR / "latest_report.json"
    if report_path.exists():
        with open(report_path) as f:
            return json.load(f)
    return None


def select_by_rules(count: int) -> list[tuple[str, str, str]]:
    """규칙 기반 조합 선택 (LLM 없이)."""
    ungenerated = get_ungenerated_combinations()

    if not ungenerated:
        print("모든 조합이 이미 생성되었습니다.")
        return []

    analytics = load_analytics_data()

    if analytics and "top_themes" in analytics:
        # Analytics 데이터 기반: 성공 패턴 우선
        top_themes = analytics.get("top_themes", [])
        top_rules = analytics.get("top_rules", [])

        # 성공 패턴 조합 우선 정렬
        def priority_score(combo):
            theme, rule, ai = combo
            score = 0
            if theme in top_themes:
                score += 10
            if rule in top_rules:
                score += 5
            return score

        ungenerated.sort(key=priority_score, reverse=True)
    else:
        # 초기 단계: 다양성 극대화 (테마별 균등 분배)
        random.shuffle(ungenerated)
        # 테마 다양성을 위해 라운드 로빈 정렬
        by_theme: dict[str, list] = {}
        for combo in ungenerated:
            by_theme.setdefault(combo[0], []).append(combo)

        diversified = []
        theme_lists = list(by_theme.values())
        idx = 0
        while len(diversified) < len(ungenerated):
            for tl in theme_lists:
                if idx < len(tl):
                    diversified.append(tl[idx])
            idx += 1
        ungenerated = diversified

    return ungenerated[:count]


def select_by_llm(count: int) -> list[tuple[str, str, str]]:
    """LLM API를 사용한 조합 선택."""
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("ANTHROPIC_API_KEY 없음 — 규칙 기반 fallback")
        return select_by_rules(count)

    try:
        import anthropic
    except ImportError:
        print("anthropic 패키지 없음 — 규칙 기반 fallback")
        return select_by_rules(count)

    ungenerated = get_ungenerated_combinations()
    if not ungenerated:
        return []

    analytics = load_analytics_data()
    analytics_text = json.dumps(analytics, ensure_ascii=False) if analytics else "데이터 없음"

    prompt = f"""고스톱 카드게임 App Factory에서 다음에 생성할 앱 {count}개를 선택해주세요.

미생성 조합 (테마, 룰, AI): {len(ungenerated)}개 남음
샘플: {ungenerated[:20]}

Analytics 데이터: {analytics_text}

기준:
1. 다양성: 같은 테마/룰이 연속되지 않도록
2. 인기도: Analytics 데이터가 있으면 성공 패턴 우선
3. 차별화: 스토어에서 눈에 띄는 조합 우선

JSON 배열로 응답해주세요: [["theme_id", "rule_id", "ai_id"], ...]"""

    client = anthropic.Anthropic(api_key=api_key)
    response = client.messages.create(
        model="claude-haiku-4-5-20251001",
        max_tokens=500,
        messages=[{"role": "user", "content": prompt}],
    )

    try:
        text = response.content[0].text
        # JSON 배열 추출
        import re
        match = re.search(r'\[.*\]', text, re.DOTALL)
        if match:
            combos = json.loads(match.group())
            return [tuple(c) for c in combos[:count]]
    except Exception as e:
        print(f"LLM 응답 파싱 실패: {e} — 규칙 기반 fallback")

    return select_by_rules(count)


def main():
    parser = argparse.ArgumentParser(description="Idea Agent — 다음 Config 선택")
    parser.add_argument("--count", type=int, default=1, help="선택할 조합 수")
    parser.add_argument("--use-llm", action="store_true", help="LLM API 사용")
    args = parser.parse_args()

    all_combos = get_all_combinations()
    existing = get_existing_configs()
    ungenerated = get_ungenerated_combinations()

    print(f"전체 조합: {len(all_combos)}개")
    print(f"생성 완료: {len(existing)}개")
    print(f"미생성: {len(ungenerated)}개")
    print()

    if args.use_llm:
        selected = select_by_llm(args.count)
    else:
        selected = select_by_rules(args.count)

    if not selected:
        print("선택할 조합이 없습니다.")
        sys.exit(0)

    print(f"선택된 조합 ({len(selected)}개):")
    for theme, rule, ai in selected:
        slug = f"gostop_{theme}_{rule}_{ai}"
        print(f"  - {slug}")

    # 선택 결과를 generate_configs.py에 전달하기 위해 파일로 저장
    selection_path = FACTORY_DIR / "configs" / "_next_selection.json"
    selection_path.parent.mkdir(parents=True, exist_ok=True)
    with open(selection_path, "w") as f:
        json.dump(selected, f)

    print(f"\n선택 저장: {selection_path}")


if __name__ == "__main__":
    main()
