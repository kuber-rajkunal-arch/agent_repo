"""
Main entry point for the CRM data ingestion pipeline.

This script orchestrates the data processing for all configured tables,
loading data from the Raw layer to the Curated layer in BigQuery.
"""
import logging
import os
import sys

from google.cloud import bigquery
from google.cloud.exceptions import GoogleCloudError

from src.config import TABLE_CONFIGURATIONS
from src.data_processor import DataProcessor


def setup_logging():
    """Configures the root logger for the application."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        stream=sys.stdout,
    )


def main():
    """
    Main function to run the CRM data ingestion pipelines.
    """
    setup_logging()
    logger = logging.getLogger(__name__)

    project_id = os.environ.get("GCP_PROJECT_ID")
    if not project_id:
        logger.error("GCP_PROJECT_ID environment variable not set.")
        sys.exit(1)

    logger.info("Starting CRM data ingestion for project: %s", project_id)

    try:
        bq_client = bigquery.Client(project=project_id)
        processor = DataProcessor(client=bq_client, project_id=project_id)
    except GoogleCloudError as e:
        logger.error("Failed to initialize BigQuery client: %s", e)
        sys.exit(1)

    has_errors = False
    for config in TABLE_CONFIGURATIONS:
        try:
            processor.process_table(config)
        except Exception:
            # The error is already logged by the processor
            logger.error("Failed to process table defined in %s.", config["id"])
            has_errors = True

    if has_errors:
        logger.error("One or more tables failed to process.")
        sys.exit(1)
    else:
        logger.info("All tables processed successfully.")


if __name__ == "__main__":
    main()
