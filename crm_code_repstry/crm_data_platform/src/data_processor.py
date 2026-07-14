"""
Core data processing module for BigQuery SCD Type 1 merges.
"""
import logging
from typing import Any, Dict, List, Optional

from google.cloud import bigquery
from google.cloud.exceptions import GoogleCloudError

logger = logging.getLogger(__name__)


class DataProcessor:
    """
    Handles the data ingestion and transformation logic for BigQuery tables.
    """

    def __init__(self, client: bigquery.Client, project_id: str):
        """
        Initializes the DataProcessor.

        Args:
            client: An authenticated Google BigQuery client instance.
            project_id: The Google Cloud project ID.
        """
        self.client = client
        self.project_id = project_id

    def _get_high_watermark(
        self, table_id: str, watermark_column: str
    ) -> Optional[Any]:
        """
        Retrieves the maximum value of the watermark column from the target table.

        Args:
            table_id: The full ID of the target BigQuery table.
            watermark_column: The name of the column to use for watermarking.

        Returns:
            The maximum value of the watermark column, or None if the table
            is empty or an error occurs.
        """
        query = f"SELECT MAX({watermark_column}) FROM `{table_id}`"
        logger.info("Executing watermark query: %s", query)
        try:
            query_job = self.client.query(query)
            result = list(query_job.result())
            if result and result[0][0] is not None:
                watermark = result[0][0]
                logger.info("High watermark for %s is '%s'", table_id, watermark)
                return watermark
            logger.info("No existing watermark found for %s. Proceeding with full load.", table_id)
            return None
        except GoogleCloudError as e:
            # If the table does not exist, a 404 Not Found error is raised.
            # In this case, we can proceed as if there's no watermark.
            if "Not found" in str(e):
                logger.warning("Target table %s not found for watermark retrieval. Assuming first run.", table_id)
                return None
            logger.error("Failed to retrieve watermark for %s: %s", table_id, e)
            raise

    def _build_merge_query(
        self,
        config: Dict[str, Any],
        watermark_value: Optional[Any],
    ) -> str:
        """Constructs the BigQuery MERGE statement."""
        source_id = f"`{self.project_id}.{config['source_dataset']}.{config['source_table']}`"
        target_id = f"`{self.project_id}.{config['target_dataset']}.{config['target_table']}`"
        pk = config["primary_key"]
        columns = [col[0] for col in config["columns"]]

        update_setters = ",\n".join([f"T.{col} = S.{col}" for col in columns if col != pk])
        insert_columns = ",\n".join(columns)
        source_columns = ",\n".join([f"S.{col}" for col in columns])

        source_data_cte = f"SourceData AS (SELECT * FROM {source_id}"
        if config.get("watermark_column") and watermark_value:
            watermark_col = config["watermark_column"]
            source_data_cte += f" WHERE {watermark_col} > TIMESTAMP('{watermark_value.isoformat()}')"
        source_data_cte += ")"

        query = f"""
        MERGE {target_id} AS T
        USING (
            SELECT * FROM {source_id}
            {'WHERE ' + config['watermark_column'] + f" > TIMESTAMP('{watermark_value.isoformat()}')"
             if config.get('watermark_column') and watermark_value else ''}
        ) AS S
        ON T.{pk} = S.{pk}
        WHEN MATCHED THEN
            UPDATE SET
                {update_setters}
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                {insert_columns}
            )
            VALUES (
                {source_columns}
            )
        """
        return query

    def _ensure_table_exists(self, config: Dict[str, Any]) -> None:
        """
        Ensures the target table exists with the correct partitioning and clustering.
        """
        table_id = f"{self.project_id}.{config['target_dataset']}.{config['target_table']}"
        schema_str = ",\n".join([f"{name} {dtype}" for name, dtype in config["columns"]])

        options = []
        if config.get("partition"):
            part_conf = config["partition"]
            options.append(f"PARTITION BY {part_conf['type']}({part_conf['field']})")

        if config.get("cluster_by"):
            cluster_cols = ", ".join(config["cluster_by"])
            options.append(f"CLUSTER BY {cluster_cols}")

        options_str = "\n".join(options)

        query = f"""
        CREATE TABLE IF NOT EXISTS `{table_id}` (
            {schema_str}
        )
        {f'OPTIONS({options_str})' if options_str else ''};
        """
        logger.info("Ensuring target table %s exists with correct structure.", table_id)
        try:
            self.client.query(query).result()
            logger.info("Table %s is ready.", table_id)
        except GoogleCloudError as e:
            logger.error("Failed to create or verify table %s: %s", table_id, e)
            raise

    def process_table(self, config: Dict[str, Any]) -> None:
        """
        Executes the full incremental ingestion process for a single table.

        Args:
            config: A dictionary containing the configuration for the table.
        """
        target_id = f"{self.project_id}.{config['target_dataset']}.{config['target_table']}"
        logger.info("Starting processing for table: %s", target_id)

        try:
            # Stage 4: Ensure table exists with correct optimization
            self._ensure_table_exists(config)

            # Stage 3: Watermark Application
            watermark_value = None
            if config.get("watermark_column"):
                watermark_value = self._get_high_watermark(
                    target_id, config["watermark_column"]
                )

            # Stage 1 & 2: Data Retrieval and Incremental Merge
            merge_query = self._build_merge_query(config, watermark_value)
            logger.info("Executing MERGE statement for %s.", target_id)
            logger.debug("Merge Query:\n%s", merge_query)

            query_job = self.client.query(merge_query)
            query_job.result()  # Wait for the job to complete

            logger.info(
                "Successfully merged data into %s. Records affected: %s.",
                target_id,
                query_job.num_dml_affected_rows,
            )

        except GoogleCloudError as e:
            logger.error("An error occurred during processing of %s: %s", target_id, e)
            # Re-raise to allow the caller to handle the failure
            raise
        except Exception as e:
            logger.error("An unexpected error occurred for %s: %s", target_id, e)
            raise
