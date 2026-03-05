"""
Unit tests for the ingestion module.
"""

import unittest
import logging
from project_name.src.ingestion import IngestionService

class TestIngestionService(unittest.TestCase):

    def setUp(self):
        self.ingestion_service = IngestionService()
        # Suppress logging during tests to keep console clean
        logging.disable(logging.CRITICAL)

    def tearDown(self):
        logging.disable(logging.NOTSET) # Re-enable logging after tests

    def test_ingest_raw_data_valid(self):
        """
        Test that valid raw sensor data is ingested successfully.
        """
        raw_data = "sensor_id:123,temp:25.5,location:34.5,-118.9"
        ingested_data = self.ingestion_service.ingest_raw_data(raw_data)
        self.assertEqual(ingested_data, raw_data)

    def test_ingest_raw_data_empty_string(self):
        """
        Test that an empty string is handled correctly (returns None).
        """
        ingested_data = self.ingestion_service.ingest_raw_data("")
        self.assertIsNone(ingested_data)

    def test_ingest_raw_data_whitespace_string(self):
        """
        Test that a whitespace-only string is handled correctly (returns None).
        """
        ingested_data = self.ingestion_service.ingest_raw_data("   \t\n")
        self.assertIsNone(ingested_data)

    def test_ingest_raw_data_non_string_type(self):
        """
        Test that non-string input is handled correctly (returns None).
        """
        ingested_data = self.ingestion_service.ingest_raw_data(12345) # type: ignore
        self.assertIsNone(ingested_data)
        ingested_data = self.ingestion_service.ingest_raw_data(None) # type: ignore
        self.assertIsNone(ingested_data)
        ingested_data = self.ingestion_service.ingest_raw_data({"key": "value"}) # type: ignore
        self.assertIsNone(ingested_data)

    def test_ingest_raw_data_long_string(self):
        """
        Test ingestion of a longer string (to ensure no arbitrary length limits).
        """
        long_data = "A" * 1024 + "B" * 500
        ingested_data = self.ingestion_service.ingest_raw_data(long_data)
        self.assertEqual(ingested_data, long_data)

if __name__ == '__main__':
    unittest.main()
