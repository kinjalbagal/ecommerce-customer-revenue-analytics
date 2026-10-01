"""Smoke test: render every dashboard page headlessly and fail on any exception.

Usage: python scripts/check_dashboard.py
"""
import sys
from pathlib import Path

from streamlit.testing.v1 import AppTest

DASHBOARD = Path(__file__).resolve().parents[1] / "dashboard"
PAGES = ["executive", "customers", "funnel", "opportunity"]


def render_page(page: str) -> None:
    import importlib

    importlib.import_module(f"views.{page}").render()


def main() -> None:
    sys.path.insert(0, str(DASHBOARD))
    failed = False
    for page in PAGES:
        app = AppTest.from_function(render_page, args=(page,), default_timeout=120).run()
        errors = [str(error.value) for error in app.exception]
        metrics = {metric.label: metric.value for metric in app.metric}
        print(f"{page}: {'FAILED ' + '; '.join(errors) if errors else 'ok'} {metrics}")
        failed = failed or bool(errors)
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
