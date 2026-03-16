import unittest
from datetime import datetime, timedelta
from unittest.mock import patch

from src.data_ingestion import receive_raw_sensor_data, simulate_sensor_transmission
from src.models import RawSensorData
from src.logger import app_logger

class TestDataIngestion(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        # Suppress logging output during tests for cleaner console, but keep it for debugging if needed
        app_logger.setLevel(100) # CRITICAL + 1 to effectively disable

    @classmethod
    def tearDownClass(cls):
        app_logger.setLevel(10) # Reset to DEBUG or INFO after tests

    def test_receive_raw_sensor_data_basic(self):
        """
        Test TR-IOT-001: Basic reception and acknowledgment of raw data.
        """
        raw_data_str = "TRUCK_A,2023-10-27T10:00:00Z,34.0522,-118.2437,85,200,1500"
        source_id = "Gateway-001"

        # Mock datetime.utcnow to ensure consistent timestamps for testing
        with patch('src.data_ingestion.datetime') as mock_datetime:
            mock_now = datetime(2023, 10, 27, 10, 0, 10)
            mock_datetime.utcnow.return_value = mock_now
            mock_datetime.side_effect = lambda *args, **kw: datetime(*args, **kw) # Allow other datetime calls

            acknowledged_data = receive_raw_sensor_data(raw_data_str, source_id)

            self.assertIsInstance(acknowledged_data, RawSensorData)
            self.assertEqual(acknowledged_data.data, raw_data_str)
            self.assertEqual(acknowledged_data.source_identifier, source_id)
            self.assertEqual(acknowledged_data.received_timestamp, mock_now)
            self.assertLessEqual(datetime.utcnow() - acknowledged_data.received_timestamp, timedelta(seconds=1)) # Check it\'s recent

    def test_receive_raw_sensor_data_empty_string(self):
        """
        Test reception with an empty raw data string.
        """
        raw_data_str = ""
        source_id = "Gateway-002"
        acknowledged_data = receive_raw_sensor_data(raw_data_str, source_id)

        self.assertIsInstance(acknowledged_data, RawSensorData)
        self.assertEqual(acknowledged_data.data, "")
        self.assertEqual(acknowledged_data.source_identifier, source_id)

    def test_receive_raw_sensor_data_long_string(self):
        """
        Test reception with a very long raw data string.
        """
        long_raw_data_str = "A" * 1000
        source_id = "Gateway-003"
        acknowledged_data = receive_raw_sensor_data(long_raw_data_str, source_id)

        self.assertIsInstance(acknowledged_data, RawSensorData)
        self.assertEqual(acknowledged_data.data, long_raw_data_str)
        self.assertEqual(acknowledged_data.source_identifier, source_id)

    def test_simulate_sensor_transmission(self):
        """
        Test the helper function for simulating sensor transmission.
        """
        sensor_id = "TEST_SENSOR_001"
        payload = "some,test,data"
        transmitted_id, transmitted_payload = simulate_sensor_transmission(sensor_id, payload)

        self.assertEqual(transmitted_id, sensor_id)
        self.assertEqual(transmitted_payload, payload)

if __name__ == '__main__':
    unittest.main()
