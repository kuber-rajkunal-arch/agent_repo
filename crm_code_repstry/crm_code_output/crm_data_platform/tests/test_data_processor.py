import datetime
import re
from unittest.mock import MagicMock

import pytest
from google.cloud import bigquery
from google.cloud.exceptions import GoogleCloudError, NotFound

from src.data_processor import DataProcessor
from src.config import TABLE_CONFIGURATIONS


def normalize_sql(query: str) -> str:
    """
    Removes comments, newlines, and collapses whitespace for consistent SQL comparison.
    """
    query = re.sub(r"--.*?\n", "", query)  # Remove single-line comments
    query = query.replace("\n", " ").replace("\t", " ")
    return " ".join(query.split()).strip()


@pytest.fixture
def mock_bq_client() -> MagicMock:
    """
    Fixture for a mocked BigQuery client.
    """
    return MagicMock(spec=bigquery.Client)


@pytest.fixture
def processor(mock_bq_client: MagicMock) -> DataProcessor:
    """
    Fixture for a DataProcessor instance.
    """
    return DataProcessor(client=mock_bq_client, project_id="test-project")


class TestGetHighWatermark:
    """
    Tests for the _get_high_watermark method.
    """

    def test_success(self, processor: DataProcessor, mock_bq_client: MagicMock):
        """Test retrieving a high watermark successfully."""
        mock_job = MagicMock()
        expected_watermark = datetime.datetime(
            2023, 10, 26, 10, 0, 0, tzinfo=datetime.timezone.utc
        )
        mock_job.result.return_value = [[expected_watermark]]
        mock_bq_client.query.return_value = mock_job

        table_id = "test-project.Curated.customer"
        watermark_column = "created_on"
        watermark = processor._get_high_watermark(table_id, watermark_column)

        assert watermark == expected_watermark
        mock_bq_client.query.assert_called_once_with(
            f"SELECT MAX({watermark_column}) FROM `{table_id}`"
        )

    def test_empty_table(self, processor: DataProcessor, mock_bq_client: MagicMock):
        """
        Test retrieving a watermark when the table is empty (returns None).
        """
        mock_job = MagicMock()
        mock_job.result.return_value = [[None]]
        mock_bq_client.query.return_value = mock_job

        watermark = processor._get_high_watermark(
            "test-project.Curated.customer", "created_on"
        )
        assert watermark is None

    def test_table_not_found(self, processor: DataProcessor, mock_bq_client: MagicMock):
        """
        Test watermark retrieval when the target table does not exist.
        """
        mock_bq_client.query.side_effect = NotFound("Table not found")
        watermark = processor._get_high_watermark(
            "test-project.Curated.customer", "created_on"
        )
        assert watermark is None

    def test_other_google_cloud_error(self, processor: DataProcessor, mock_bq_client: MagicMock):
        """
        Test that other GoogleCloudError exceptions are raised.
        """
        mock_bq_client.query.side_effect = GoogleCloudError("Permissions error")
        with pytest.raises(GoogleCloudError, match="Permissions error"):
            processor._get_high_watermark(
                "test-project.Curated.customer", "created_on"
            )


class TestEnsureTableExists:
    """
    Tests for the _ensure_table_exists method.
    """

    def test_with_partition_and_cluster(self, processor: DataProcessor, mock_bq_client: MagicMock):
        """
        Test CREATE TABLE for a partitioned and clustered table.
        """
        config = TABLE_CONFIGURATIONS[1]  # lead table
        processor._ensure_table_exists(config)

        expected_query = """
        CREATE TABLE IF NOT EXISTS `test-project.Curated.lead` (
            lead_id STRING, topic STRING, first_name STRING, last_name STRING,
            company_name STRING, email STRING, phone STRING, lead_source STRING,
            status STRING, customer_id STRING, created_on TIMESTAMP,
            qualified_on TIMESTAMP, owner_id STRING
        )
        OPTIONS(PARTITION BY DATE(created_on), CLUSTER BY lead_source, status);
        """
        mock_bq_client.query.assert_called_once()
        actual_query = mock_bq_client.query.call_args[0][0]
        assert normalize_sql(actual_query) == normalize_sql(expected_query)

    def test_with_cluster_only(self, processor: DataProcessor, mock_bq_client: MagicMock):
        """
        Test CREATE TABLE for a table with clustering but no partitioning.
        """
        config = TABLE_CONFIGURATIONS[0]  # customer table
        processor._ensure_table_exists(config)

        expected_query = """
        CREATE TABLE IF NOT EXISTS `test-project.Curated.customer` (
            customer_id STRING, customer_type STRING, name STRING, company_name STRING,
            industry STRING, email STRING, phone STRING, website STRING,
            address_line1 STRING, address_line2 STRING, city STRING, state STRING,
            country STRING, postal_code STRING, created_on TIMESTAMP,
            modified_on TIMESTAMP, is_active BOOL
        )
        OPTIONS(CLUSTER BY customer_type, industry);
        """
        mock_bq_client.query.assert_called_once()
        actual_query = mock_bq_client.query.call_args[0][0]
        assert normalize_sql(actual_query) == normalize_sql(expected_query)

    def test_no_optimization(self, processor: DataProcessor, mock_bq_client: MagicMock):
        """
        Test CREATE TABLE for a table with no optimizations.
        """
        config = TABLE_CONFIGURATIONS[4]  # quote_detail table
        processor._ensure_table_exists(config)

        expected_query = """
        CREATE TABLE IF NOT EXISTS `test-project.Curated.quote_detail` (
            quote_detail_id STRING, quote_id STRING, product_name STRING,
            product_category STRING, quantity INT64, unit_price FLOAT64,
            discount FLOAT64, total_amount FLOAT64
        );
        """
        mock_bq_client.query.assert_called_once()
        actual_query = mock_bq_client.query.call_args[0][0]
        assert normalize_sql(actual_query).replace(" OPTIONS()", "") == normalize_sql(expected_query)

    def test_google_cloud_error(self, processor: DataProcessor, mock_bq_client: MagicMock):
        """
        Test that GoogleCloudError is raised on failure.
        """
        config = TABLE_CONFIGURATIONS[0]
        mock_bq_client.query.side_effect = GoogleCloudError("DDL error")
        with pytest.raises(GoogleCloudError):
            processor._ensure_table_exists(config)


class TestBuildMergeQuery:
    """
    Tests for the _build_merge_query method.
    """

    def test_with_watermark(self, processor: DataProcessor):
        """
        Test building a MERGE query with a watermark value.
        """
        config = TABLE_CONFIGURATIONS[0]  # customer table
        watermark = datetime.datetime(2023, 1, 1, 0, 0, 0, tzinfo=datetime.timezone.utc)
        query = processor._build_merge_query(config, watermark)
        norm_query = normalize_sql(query)

        assert "MERGE `test-project.Curated.customer` AS T" in norm_query
        assert "USING ( SELECT * FROM `test-project.Raw.stg_customer` WHERE created_on > TIMESTAMP('2023-01-01T00:00:00+00:00') ) AS S" in norm_query
        assert "ON T.customer_id = S.customer_id" in norm_query
        assert "WHEN MATCHED THEN UPDATE SET" in norm_query
        assert "T.customer_id = S.customer_id" not in norm_query.split("UPDATE SET")[1]
        assert "T.is_active = S.is_active" in norm_query
        assert "WHEN NOT MATCHED BY TARGET THEN INSERT" in norm_query

    def test_without_watermark_value(self, processor: DataProcessor):
        """
        Test building a MERGE query when watermark_value is None (first run).
        """
        config = TABLE_CONFIGURATIONS[0]  # customer table, has watermark_column
        query = processor._build_merge_query(config, None)
        norm_query = normalize_sql(query)

        assert "MERGE `test-project.Curated.customer` AS T" in norm_query
        assert "USING ( SELECT * FROM `test-project.Raw.stg_customer` ) AS S" in norm_query
        assert "ON T.customer_id = S.customer_id" in norm_query

    def test_no_watermark_column(self, processor: DataProcessor):
        """
        Test building a MERGE query for a table without a watermark column.
        """
        config = TABLE_CONFIGURATIONS[4]  # quote_detail table
        query = processor._build_merge_query(config, None)
        norm_query = normalize_sql(query)

        assert "MERGE `test-project.Curated.quote_detail` AS T" in norm_query
        assert "USING ( SELECT * FROM `test-project.Raw.stg_quote_detail` ) AS S" in norm_query
        assert "ON T.quote_detail_id = S.quote_detail_id" in norm_query


class TestProcessTable:
    """
    Tests for the main process_table method.
    """

    @pytest.fixture(autouse=True)
    def mock_helpers(self, processor: DataProcessor, mocker: MagicMock):
        """
        Mock helper methods for all tests in this class.
        """
        mocker.patch.object(processor, '_ensure_table_exists')
        mocker.patch.object(processor, '_get_high_watermark')
        mocker.patch.object(processor, '_build_merge_query')

    def test_full_flow_with_watermark(self, processor: DataProcessor, mock_bq_client: MagicMock):
        """
        Test the end-to-end flow for a table with a watermark.
        """
        config = TABLE_CONFIGURATIONS[0]
        watermark_value = datetime.datetime(2023, 1, 1, 0, 0, 0)
        
        processor._get_high_watermark.return_value = watermark_value
        processor._build_merge_query.return_value = "MERGE QUERY"

        mock_job = MagicMock()
        mock_job.num_dml_affected_rows = 100
        mock_bq_client.query.return_value = mock_job

        processor.process_table(config)

        processor._ensure_table_exists.assert_called_once_with(config)
        processor._get_high_watermark.assert_called_once_with(
            "test-project.Curated.customer", "created_on"
        )
        processor._build_merge_query.assert_called_once_with(config, watermark_value)
        mock_bq_client.query.assert_called_once_with("MERGE QUERY")
        mock_job.result.assert_called_once()

    def test_flow_no_watermark_column(self, processor: DataProcessor, mock_bq_client: MagicMock):
        """
        Test the flow for a table without a watermark column.
        """
        config = TABLE_CONFIGURATIONS[4]  # quote_detail
        
        processor._build_merge_query.return_value = "MERGE QUERY"
        mock_job = MagicMock()
        mock_bq_client.query.return_value = mock_job

        processor.process_table(config)

        processor._ensure_table_exists.assert_called_once_with(config)
        processor._get_high_watermark.assert_not_called()
        processor._build_merge_query.assert_called_once_with(config, None)
        mock_bq_client.query.assert_called_once_with("MERGE QUERY")
        mock_job.result.assert_called_once()

    def test_merge_query_failure(self, processor: DataProcessor, mock_bq_client: MagicMock):
        """
        Test that an exception during the MERGE query is raised.
        """
        config = TABLE_CONFIGURATIONS[0]
        processor._get_high_watermark.return_value = None
        processor._build_merge_query.return_value = "MERGE QUERY"
        
        mock_bq_client.query.side_effect = GoogleCloudError("Query failed")

        with pytest.raises(GoogleCloudError, match="Query failed"):
            processor.process_table(config)

        # Ensure we don't try to get the result if the query submission fails
        mock_bq_client.query.return_value.result.assert_not_called()
