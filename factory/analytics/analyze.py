#!/usr/bin/env python3
"""
Analytics 분석기 — 성과 데이터 분석 + 다음 우선순위 결정

사용법:
  python analyze.py              # 최신 리포트 분석
  python analyze.py --use-llm    # LLM API로 심층 분석
"""

import argparse
import json
import os
import sys
from collections import defaultdict
from pathlib import Path

import yaml


FACTORY_DIR = Path(__file__).resolve().parent.parent
ANALYTICS_DIR = FACTORY_DIR / "analytics"
APPS_DIR = FACTORY_DIR / "apps"


def load_latest_report() -> dict | None:
    """최신 Analytics 리포트 로드."""
    report_path = ANALYTICS_DIR / "latest_report.json"
    if report_path.exists():
        with open(report_path) as f:
            return json.load(f)
    return None


def analyze_by_dimension(report: dict) -> dict:
    """테마/룰/AI별 성과 집계."""
    theme_stats = defaultdict(lambda: {"dau": 0, "count": 0, "revenue": 0})
    rule_stats = defaultdict(lambda: {"dau": 0, "count": 0, "revenue": 0})
    ai_stats = defaultdict(lambda: {"dau": 0, "count": 0, "revenue": 0})

    for app_id, data in report.get("apps", {}).items():
        # app_id에서 차원 추출: com.gostop.<theme>.<rule>.<ai>
        parts = app_id.split(".")
        if len(parts) >= 5:
            theme = parts[2]
            rule = parts[3]
            ai = parts[4]

            dau = data.get("dau", 0)
            revenue = data.get("revenue_usd", 0)

            for dim, key in [(theme_stats, theme), (rule_stats, rule), (ai_stats, ai)]:
                dim[key]["dau"] += dau
                dim[key]["count"] += 1
                dim[key]["revenue"] += revenue

    return {
        "themes": dict(theme_stats),
        "rules": dict(rule_stats),
        "ai_levels": dict(ai_stats),
    }


def rank_dimensions(dimension_stats: dict) -> list[str]:
    """DAU 기준 상위 차원 정렬."""
    return sorted(
        dimension_stats.keys(),
        key=lambda k: dimension_stats[k]["dau"],
        reverse=True,
    )


def generate_recommendations(analysis: dict) -> dict:
    """다음 생성 우선순위 추천."""
    top_themes = rank_dimensions(analysis["themes"])[:3]
    top_rules = rank_dimensions(analysis["rules"])[:3]
    top_ai = rank_dimensions(analysis["ai_levels"])[:2]

    return {
        "top_themes": top_themes,
        "top_rules": top_rules,
        "top_ai": top_ai,
        "recommendation": (
            f"테마 '{top_themes[0] if top_themes else 'N/A'}' + "
            f"룰 '{top_rules[0] if top_rules else 'N/A'}' 조합이 "
            f"가장 높은 DAU를 기록하고 있습니다."
        ),
    }


def main():
    parser = argparse.ArgumentParser(description="Analytics 분석기")
    parser.add_argument("--use-llm", action="store_true", help="LLM 심층 분석")
    args = parser.parse_args()

    report = load_latest_report()
    if not report:
        print("Analytics 리포트가 없습니다.")
        print("먼저 'python collect.py'를 실행하세요.")
        sys.exit(1)

    print(f"=== Analytics 분석 ===")
    print(f"수집 시각: {report.get('collected_at', 'N/A')}")
    print(f"앱 수: {report['summary']['total_apps']}")
    print()

    # 차원별 분석
    analysis = analyze_by_dimension(report)

    print("📊 테마별 성과:")
    for theme in rank_dimensions(analysis["themes"]):
        stats = analysis["themes"][theme]
        print(f"  {theme}: DAU {stats['dau']}, 앱 {stats['count']}개")

    print("\n📊 룰별 성과:")
    for rule in rank_dimensions(analysis["rules"]):
        stats = analysis["rules"][rule]
        print(f"  {rule}: DAU {stats['dau']}, 앱 {stats['count']}개")

    print("\n📊 AI별 성과:")
    for ai in rank_dimensions(analysis["ai_levels"]):
        stats = analysis["ai_levels"][ai]
        print(f"  {ai}: DAU {stats['dau']}, 앱 {stats['count']}개")

    # 추천
    recommendations = generate_recommendations(analysis)
    print(f"\n💡 추천: {recommendations['recommendation']}")

    # 리포트 저장
    enriched_report = {
        **report,
        "analysis": analysis,
        "recommendations": recommendations,
    }
    output_path = ANALYTICS_DIR / "latest_report.json"
    with open(output_path, "w") as f:
        json.dump(enriched_report, f, ensure_ascii=False, indent=2)

    print(f"\n분석 결과 저장: {output_path}")


if __name__ == "__main__":
    main()
