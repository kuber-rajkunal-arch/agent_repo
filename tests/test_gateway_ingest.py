"""
Unit tests for the gateway_ingest module.
"""

import unittest
from collections import deque
from unittest.mock import patch

from project_name.src.gateway_ingest import SensorDataIngestor

class TestSensorDataIngestor(unittest.TestCase):

    def setUp(self):
        """Set up for test methods."""
        self.ingestor = SensorDataIngestor(buffer_max_size=5)

    def test_initial_buffer_is_empty(self):
        """Test that the buffer is empty on initialization."""
        self.assertEqual(len(self.ingestor.buffer), 0)
        self.assertFalse(self.ingestor)

    def test_ingest_single_data(self):
        """Test ingesting a single raw data string."""
        raw_data = "SENSOR_ID_1,DATA_STRING_1"
        self.ingestor.ingest_raw_data(raw_data)
        self.assertEqual(len(self.ingestor.buffer), 1)
        self.assertEqual(self.ingestor.buffer[0], raw_data)
        self.assertTrue(self.ingestor)

    def test_ingest_multiple_data(self):
        """Test ingesting multiple raw data strings."""
        data_list = ["DATA_1", "DATA_2", "DATA_3"]
        for data in data_list:
            self.ingestor.ingest_raw_data(data)
        self.assertEqual(len(self.ingestor.buffer), 3)
        self.assertListEqual(list(self.ingestor.buffer), data_list)

    def test_buffer_max_size(self):
        """Test that the buffer respects its maximum size."""
        data_list = ["DATA_1", "DATA_2", "DATA_3", "DATA_4", "DATA_5", "DATA_6"]
        for data in data_list:
            self.ingestor.ingest_raw_data(data)
        
        self.assertEqual(len(self.ingestor.buffer), 5)
        # "DATA_1" should have been pushed out
        self.assertListEqual(list(self.ingestor.buffer), ["DATA_2", "DATA_3", "DATA_4", "DATA_5", "DATA_6"])

    def test_get_buffered_data_all(self):
        """Test retrieving all buffered data."""
        data_list = ["DATA_A", "DATA_B"]
        self.ingestor.ingest_raw_data(data_list[0])
        self.ingestor.ingest_raw_data(data_list[1])

        retrieved = self.ingestor.get_buffered_data()
        self.assertListEqual(retrieved, data_list)
        self.assertEqual(len(self.ingestor.buffer), 0) # Buffer should be empty after retrieval

    def test_get_buffered_data_count(self):
        """Test retrieving a specific count of buffered data."""
        data_list = ["D1", "D2", "D3", "D4"]
        for data in data_list:
            self.ingestor.ingest_raw_data(data)
        
        retrieved = self.ingestor.get_buffered_data(count=2)
        self.assertListEqual(retrieved, ["D1", "D2"])
        self.assertEqual(len(self.ingestor.buffer), 2)
        self.assertListEqual(list(self.ingestor.buffer), ["D3", "D4"])

    def test_get_buffered_data_more_than_available(self):
        """Test retrieving more data than available in the buffer."""
        data_list = ["ITEM_X", "ITEM_Y"]
        for data in data_list:
            self.ingestor.ingest_raw_data(data)
        
        retrieved = self.ingestor.get_buffered_data(count=5) # Request 5, only 2 available
        self.assertListEqual(retrieved, ["ITEM_X", "ITEM_Y"])
        self.assertEqual(len(self.ingestor.buffer), 0)

    def test_get_buffered_data_from_empty_buffer(self):
        """Test retrieving data when the buffer is empty."""
        retrieved = self.ingestor.get_buffered_data()
        self.assertEqual(retrieved, [])
        self.assertEqual(len(self.ingestor.buffer), 0)

    @patch('project_name.src.gateway_ingest.logger')
    def test_ingest_invalid_data(self, mock_logger):
        """Test ingesting invalid (empty/non-string) data."""
        self.ingestor.ingest_raw_data("")
        self.ingestor.ingest_raw_data("   ")
        self.ingestor.ingest_raw_data(None) # type: ignore
        self.assertEqual(len(self.ingestor.buffer), 0)
        self.assertTrue(mock_logger.warning.called) # Should log warnings for invalid data

    @patch('project_name.src.gateway_ingest.logger')
    def test_buffer_full_warning(self, mock_logger):
        """Test warning is logged when buffer is full."""
        for i in range(self.ingestor.buffer.maxlen):
            self.ingestor.ingest_raw_data(f"DATA_{i}")
        self.assertEqual(mock_logger.warning.call_count, 0) # No warning yet
        
        self.ingestor.ingest_raw_data("OVERFLOW_DATA") # This will make it full and push oldest
        self.assertEqual(mock_logger.warning.call_count, 1)
        self.assertIn("buffer is full", mock_logger.warning.call_args[0][0])

if __name__ == '__main__':
    unittest.main()

