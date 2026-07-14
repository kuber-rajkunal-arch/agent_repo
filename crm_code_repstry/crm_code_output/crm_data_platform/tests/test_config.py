import pytest
from src.config import TABLE_CONFIGURATIONS


def test_table_configurations_is_list_of_dicts():
    """Ensures TABLE_CONFIGURATIONS is a non-empty list of dictionaries."""
    assert isinstance(TABLE_CONFIGURATIONS, list)
    assert len(TABLE_CONFIGURATIONS) > 0
    assert all(isinstance(item, dict) for item in TABLE_CONFIGURATIONS)


@pytest.mark.parametrize("config", TABLE_CONFIGURATIONS, ids=[c.get('id', 'unknown-id') for c in TABLE_CONFIGURATIONS])
class TestConfigSchema:
    """Validates the schema for each table configuration."""

    def test_has_required_keys(self, config):
        """Tests that each configuration has the required top-level keys."""
        required_keys = {
            "id", "source_dataset", "source_table", "target_dataset",
            "target_table", "primary_key", "watermark_column", "columns",
            "partition", "cluster_by"
        }
        assert required_keys == set(config.keys()), f"Missing/extra keys in config ID: {config.get('id')}"

    def test_column_definitions_are_valid(self, config):
        """Tests that column definitions are a list of (name, type) tuples."""
        assert isinstance(config["columns"], list)
        assert len(config["columns"]) > 0, "Columns list cannot be empty"
        for col in config["columns"]:
            assert isinstance(col, tuple), "Each column must be a tuple"
            assert len(col) == 2, "Each column tuple must have two elements (name, type)"
            assert isinstance(col[0], str) and col[0], "Column name must be a non-empty string"
            assert isinstance(col[1], str) and col[1], "Column type must be a non-empty string"

    def test_primary_key_is_in_columns(self, config):
        """Ensures the primary key is defined in the columns list."""
        column_names = {col[0] for col in config["columns"]}
        assert config["primary_key"] in column_names, "Primary key must be a defined column"

    def test_watermark_column_is_in_columns(self, config):
        """Ensures the watermark column, if specified, is in the columns list."""
        if config["watermark_column"]:
            column_names = {col[0] for col in config["columns"]}
            assert config["watermark_column"] in column_names, "Watermark column must be a defined column"

    def test_partition_key_is_valid_and_in_columns(self, config):
        """Ensures the partition key, if specified, is valid and in the columns list."""
        if config["partition"]:
            assert isinstance(config["partition"], dict), "Partition config must be a dictionary"
            assert "field" in config["partition"], "Partition config must have a 'field' key"
            assert "type" in config["partition"], "Partition config must have a 'type' key"
            column_names = {col[0] for col in config["columns"]}
            assert config["partition"]["field"] in column_names, "Partition field must be a defined column"

    def test_cluster_keys_are_in_columns(self, config):
        """Ensures clustering keys, if specified, are in the columns list."""
        if config["cluster_by"]:
            assert isinstance(config["cluster_by"], list), "cluster_by must be a list"
            column_names = {col[0] for col in config["columns"]}
            for cluster_key in config["cluster_by"]:
                assert cluster_key in column_names, f"Cluster key '{cluster_key}' must be a defined column"
