from unittest.mock import MagicMock, patch, call

import pytest
from google.cloud.exceptions import GoogleCloudError

from src.main import main
from src.config import TABLE_CONFIGURATIONS


@pytest.fixture
def mock_env_vars(monkeypatch):
    """Fixture to set environment variables for tests."""
    monkeypatch.setenv("GCP_PROJECT_ID", "test-project")


@patch("src.main.sys.exit")
@patch("src.main.logging.getLogger")
def test_main_missing_env_var(mock_logger, mock_exit, monkeypatch):
    """Test main function exits if GCP_PROJECT_ID is not set."""
    monkeypatch.delenv("GCP_PROJECT_ID", raising=False)
    main()
    mock_logger().error.assert_called_with("GCP_PROJECT_ID environment variable not set.")
    mock_exit.assert_called_once_with(1)


@patch("src.main.DataProcessor")
@patch("src.main.bigquery.Client")
@patch("src.main.sys.exit")
def test_main_bq_client_init_fails(mock_exit, mock_bq_client, mock_processor, mock_env_vars):
    """Test main exits if BigQuery client initialization fails."""
    mock_bq_client.side_effect = GoogleCloudError("Auth error")
    main()
    mock_exit.assert_called_once_with(1)


@patch("src.main.DataProcessor")
@patch("src.main.bigquery.Client")
@patch("src.main.sys.exit")
def test_main_success_flow(mock_exit, mock_bq_client, mock_processor, mock_env_vars):
    """Test the successful execution of the main function."""
    mock_proc_instance = MagicMock()
    mock_processor.return_value = mock_proc_instance

    main()

    mock_bq_client.assert_called_once_with(project="test-project")
    mock_processor.assert_called_once_with(
        client=mock_bq_client.return_value, project_id="test-project"
    )

    expected_calls = [call(config) for config in TABLE_CONFIGURATIONS]
    mock_proc_instance.process_table.assert_has_calls(expected_calls, any_order=False)
    assert mock_proc_instance.process_table.call_count == len(TABLE_CONFIGURATIONS)

    mock_exit.assert_not_called()


@patch("src.main.DataProcessor")
@patch("src.main.bigquery.Client")
@patch("src.main.sys.exit")
@patch("src.main.logging.getLogger")
def test_main_partial_failure(mock_logger, mock_exit, mock_bq_client, mock_processor, mock_env_vars):
    """Test that main exits with an error if one table fails to process."""
    mock_proc_instance = MagicMock()
    # Fail on the second table config
    effects = [None] * len(TABLE_CONFIGURATIONS)
    effects[1] = Exception("Something went wrong")
    mock_proc_instance.process_table.side_effect = effects
    mock_processor.return_value = mock_proc_instance

    main()

    # Check that process_table was called for all configurations, as the loop continues on error
    assert mock_proc_instance.process_table.call_count == len(TABLE_CONFIGURATIONS)

    # Check that the error was logged for the specific failing table
    failed_config_id = TABLE_CONFIGURATIONS[1]["id"]
    mock_logger().error.assert_any_call("Failed to process table defined in %s.", failed_config_id)

    # Check that the final summary error is logged and sys.exit is called
    mock_logger().error.assert_any_call("One or more tables failed to process.")
    mock_exit.assert_called_once_with(1)
