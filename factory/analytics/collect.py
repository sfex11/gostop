#!/usr/bin/env python3
"""
Analytics 수집기 — Firebase에서 앱 성과 데이터 수집

사용법:
  python collect.py                          # 전체 앱 데이터 수집
  python collect.py --app-id com.gostop.anime.fast.easy
"""

import argparse
import json
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path


FACTORY_DIR = Path(__file__).resolve().parent.parent
ANALYTICS_DIR = FACTORY_DIR / "analytics"
APPS_DIR = FACTORY_DIR / "apps"


def collect_firebase_data(app_ids: list[str]) -> dict:
    """Firebase Analytics에서 데이터 수집."""
    firebase_project = os.environ.get("FIREBASE_PROJECT_ID")
    if not firebase_project:
        print("FIREBASE_PROJECT_ID 없음 — 더미 데이터 생성")
        return generate_dummy_data(app_ids)

    try:
        from google.analytics.data_v1beta import BetaAnalyticsDataClient
        from google.analytics.data_v1beta.types import (
            DateRange, Dimension, Metric, RunReportRequest,
        )
    except ImportError:
        print("google-analytics-data 패키지 필요 — 더미 데이터 생성")
        return generate_dummy_data(app_ids)

    # Firebase GA4 데이터 수집
    client = BetaAnalyticsDataClient()
    results = {}

    for app_id in app_ids:
        try:
            request = RunReportRequest(
                property=f"properties/{firebase_project}",
                dimensions=[Dimension(name="appId")],
                metrics=[
                    Metric(name="activeUsers"),
                    Metric(name="sessions"),
                    Metric(name="averageSessionDuration"),
                ],
                date_ranges=[DateRange(
                    start_date=(datetime.now() - timedelta(days=7)).strftime("%Y-%m-%d"),
                    end_date="today",
                )],
            )
            response = client.run_report(request)
            for row in response.rows:
                results[app_id] = {
                    "dau": int(row.metric_values[0].value),
                    "sessions": int(row.metric_values[1].value),
                    "avg_session_sec": float(row.metric_values[2].value),
                }
        except Exception as e:
            print(f"  {app_id}: 수집 실패 ({e})")

    return results


def generate_dummy_data(app_ids: list[str]) -> dict:
    """테스트용 더미 데이터."""
    import random
    results = {}
    for app_id in app_ids:
        results[app_id] = {
            "dau": random.randint(0, 100),
            "sessions": random.randint(0, 500),
            "avg_session_sec": random.uniform(60, 600),
            "revenue_usd": random.uniform(0, 5),
        }
    return results


def get_deployed_app_ids() -> list[str]:
    """배포된 앱 ID 목록."""
    app_ids = []
    for app_dir in APPS_DIR.iterdir():
        meta_path = app_dir / "metadata.json"
        if meta_path.exists():
            with open(meta_path) as f:
                meta = json.load(f)
                app_ids.append(meta["app_id"])
    return app_ids


def save_report(data: dict):
    """수집 결과 저장."""
    ANALYTICS_DIR.mkdir(parents=True, exist_ok=True)

    report = {
        "collected_at": datetime.now().isoformat(),
        "apps": data,
        "summary": {
            "total_apps": len(data),
            "total_dau": sum(d.get("dau", 0) for d in data.values()),
            "avg_session_sec": (
                sum(d.get("avg_session_sec", 0) for d in data.values()) / len(data)
                if data else 0
            ),
        },
    }

    # 최신 리포트
    latest_path = ANALYTICS_DIR / "latest_report.json"
    with open(latest_path, "w") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)

    # 날짜별 히스토리
    date_str = datetime.now().strftime("%Y%m%d")
    history_path = ANALYTICS_DIR / f"report_{date_str}.json"
    with open(history_path, "w") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)

    print(f"리포트 저장: {latest_path}")
    return report


def main():
    parser = argparse.ArgumentParser(description="Analytics 수집기")
    parser.add_argument("--app-id", help="특정 앱 ID")
    args = parser.parse_args()

    if args.app_id:
        app_ids = [args.app_id]
    else:
        app_ids = get_deployed_app_ids()

    if not app_ids:
        print("수집할 앱이 없습니다.")
        sys.exit(0)

    print(f"=== Analytics 수집 ({len(app_ids)}개 앱) ===")
    data = collect_firebase_data(app_ids)
    report = save_report(data)

    print(f"\n요약:")
    print(f"  총 앱: {report['summary']['total_apps']}")
    print(f"  총 DAU: {report['summary']['total_dau']}")
    print(f"  평균 세션: {report['summary']['avg_session_sec']:.0f}초")


if __name__ == "__main__":
    main()
