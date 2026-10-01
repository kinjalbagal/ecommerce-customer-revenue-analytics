"""Run every SQL file in sql/profiling and sql/analysis and save each result as CSV.

Usage: python scripts/run_sql.py [profiling|analysis]
"""
import sys

from bq import REPO_ROOT, client, run_query

OUTPUT_DIRS = {
    "profiling": REPO_ROOT / "analysis" / "outputs" / "profiling",
    "analysis": REPO_ROOT / "analysis" / "outputs",
}


def main() -> None:
    groups = sys.argv[1:] or list(OUTPUT_DIRS)
    bq_client = client()
    for group in groups:
        output_dir = OUTPUT_DIRS[group]
        output_dir.mkdir(parents=True, exist_ok=True)
        for sql_file in sorted((REPO_ROOT / "sql" / group).glob("*.sql")):
            result = run_query(bq_client, sql_file.read_text())
            result.to_csv(output_dir / f"{sql_file.stem}.csv", index=False)
            print(f"{group}/{sql_file.name}: {len(result)} rows")


if __name__ == "__main__":
    main()
