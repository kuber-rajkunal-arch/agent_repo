import datetime
import unittest
from unittest.mock import MagicMock, call, patch

from google.cloud import bigquery
from google.cloud.exceptions import NotFound

from src.data_processor import DataProcessor
from src.config import TABLE_CONFIGURATIONS


class TestDataProcessor(unittest.TestCase):
    """Unit tests for the DataProcessor class."""

    def setUp(self):
        """Set up the test environment."""
        self.mock_bq_client = MagicMock(spec=bigquery.Client)
        self.project_id = "test-project"
        self.processor = DataProcessor(
            client=self.mock_bq_client, project_id=self.project_id
        )

    def test_get_high_watermark_success(self):
        """Test retrieving a high watermark successfully."""
        mock_job = MagicMock()
        expected_watermark = datetime.datetime(
            2023, 10, 26, 10, 0, 0, tzinfo=datetime.timezone.utc
        )
        mock_job.result.return_value = [[expected_watermark]]
        self.mock_bq_client.query.return_value = mock_job

        table_id = "test-project.Curated.customer"
        watermark_column = "created_on"
        watermark = self.processor._get_high_watermark(table_id, watermark_column)

        self.assertEqual(watermark, expected_watermark)
        self.mock_bq_client.query.assert_called_once_with(
            f"SELECT MAX({watermark_column}) FROM `{table_id}`"
        )

    def test_get_high_watermark_no_data(self):
        """Test retrieving a watermark when the table is empty."""
        mock_job = MagicMock()
        mock_job.result.return_value = [[None]]
        self.mock_bq_client.query.return_value = mock_job

        watermark = self.processor._get_high_watermark(
            "test-project.Curated.customer", "created_on"
        )
        self.assertIsNone(watermark)

    def test_get_high_watermark_table_not_found(self):
        """Test watermark retrieval when the target table does not exist."""
        self.mock_bq_client.query.side_effect = NotFound("Table not found")
        watermark = self.processor._get_high_watermark(
            "test-project.Curated.customer", "created_on"
        )
        self.assertIsNone(watermark)

    def test_ensure_table_exists_with_partition_and_cluster(self):
        """Test the CREATE TABLE query for a partitioned and clustered table."""
        config = TABLE_CONFIGURATIONS[1]  # lead table
        self.processor._ensure_table_exists(config)

        expected_query = """
        CREATE TABLE IF NOT EXISTS `test-project.Curated.lead` (
            lead_id STRING,
topic STRING,
first_name STRING,
last_name STRING,
company_name STRING,
email STRING,
phone STRING,
lead_source STRING,
status STRING,
customer_id STRING,
created_on TIMESTAMP,
qualified_on TIMESTAMP,
owner_id STRING
        )
        OPTIONS(PARTITION BY DATE(created_on)
CLUSTER BY lead_source, status);
        """
        self.mock_bq_client.query.assert_called_once()
        actual_query = self.mock_bq_client.query.call_args[0][0]
        self.assertEqual("".join(expected_query.split()), "".join(actual_query.split()))

    def test_ensure_table_exists_no_optimization(self):
        """Test the CREATE TABLE query for a table with no optimizations."""
        config = TABLE_CONFIGURATIONS[4]  # quote_detail table
        self.processor._ensure_table_exists(config)

        expected_query = """
        CREATE TABLE IF NOT EXISTS `test-project.Curated.quote_detail` (
            quote_detail_id STRING,
quote_id STRING,
product_name STRING,
product_category STRING,
quantity INT64,
unit_price FLOAT64,
discount FLOAT64,
total_amount FLOAT64
        )
        ;
        """
        self.mock_bq_client.query.assert_called_once()
        actual_query = self.mock_bq_client.query.call_args[0][0]
        # Remove OPTIONS() if it's empty for comparison
        actual_query = actual_query.replace("OPTIONS()", "")
        self.assertEqual("".join(expected_query.split()), "".join(actual_query.split()))

    def test_build_merge_query_with_watermark(self):
        """Test building a MERGE query with a watermark value."""
        config = TABLE_CONFIGURATIONS[0]  # customer table
        watermark = datetime.datetime(2023, 1, 1, 0, 0, 0)
        query = self.processor._build_merge_query(config, watermark)

        self.assertIn("MERGE `test-project.Curated.customer` AS T", query)
        self.assertIn("USING (", query)
        self.assertIn("FROM `test-project.Raw.stg_customer`", query)
        self.assertIn("WHERE created_on > TIMESTAMP('2023-01-01T00:00:00')", query)
        self.assertIn("ON T.customer_id = S.customer_id", query)
        self.assertIn("WHEN MATCHED THEN", query)
        self.assertIn("UPDATE SET", query)
        self.assertIn("T.is_active = S.is_active", query)
        self.assertIn("WHEN NOT MATCHED BY TARGET THEN", query)
        self.assertIn("INSERT (", query)
        self.assertIn("VALUES (", query)

    def test_build_merge_query_without_watermark(self):
        """Test building a MERGE query for a full table scan."""
        config = TABLE_CONFIGURATIONS[4]  # quote_detail table
        query = self.processor._build_merge_query(config, None)

        self.assertIn("MERGE `test-project.Curated.quote_detail` AS T", query)
        self.assertIn("FROM `test-project.Raw.stg_quote_detail`", query)
        self.assertNotIn("WHERE", query)  # No watermark filter
        self.assertIn("ON T.quote_detail_id = S.quote_detail_id", query)

    @patch("src.data_processor.DataProcessor._get_high_watermark")
    @patch("src.data_processor.DataProcessor._ensure_table_exists")
    def test_process_table_flow(self, mock_ensure_table, mock_get_watermark):
        """Test the end-to-end flow of process_table."""
        config = TABLE_CONFIGURATIONS[0]  # customer table
        watermark_value = datetime.datetime(2023, 1, 1, 0, 0, 0)
        mock_get_watermark.return_value = watermark_value

        mock_job = MagicMock()
        mock_job.num_dml_affected_rows = 100
        self.mock_bq_client.query.return_value = mock_job

        self.processor.process_table(config)

        # Verify correct methods were called in order
        mock_ensure_table.assert_called_once_with(config)
        mock_get_watermark.assert_called_once_with(
            f"{self.project_id}.{config['target_dataset']}.{config['target_table']}",
            config["watermark_column"],
        )

        # Verify the merge query was executed
        self.mock_bq_client.query.assert_called_once()
        merge_query_call = self.mock_bq_client.query.call_args[0][0]
        self.assertIn("MERGE `test-project.Curated.customer`", merge_query_call)
        self.assertIn("WHERE created_on > TIMESTAMP('2023-01-01T00:00:00')", merge_query_call)

        # Verify the job result was awaited
        mock_job.result.assert_called_once()


if __name__ == "__main__":
    unittest.main()
