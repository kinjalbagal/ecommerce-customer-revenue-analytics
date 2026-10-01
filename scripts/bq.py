"""Shared BigQuery helpers for the analysis, export and figure scripts."""
import os
import warnings
from pathlib import Path

from google.cloud import bigquery

REPO_ROOT = Path(__file__).resolve().parents[1]
DATASET = "thelook_analytics"

# The REST fallback is fast enough for these small result sets.
warnings.filterwarnings("ignore", message="BigQuery Storage module not found")
warnings.filterwarnings("ignore", message="Your application has authenticated using end user credentials")


def client() -> bigquery.Client:
    return bigquery.Client(project=os.environ["GCP_PROJECT_ID"])


def run_query(bq_client: bigquery.Client, sql: str):
    # Unqualified table names in sql/analysis resolve to the dbt dataset.
    config = bigquery.QueryJobConfig(
        default_dataset=f"{bq_client.project}.{DATASET}",
        maximum_bytes_billed=5 * 10**9,
    )
    return bq_client.query(sql, job_config=config).to_dataframe()
