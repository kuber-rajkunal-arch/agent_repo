"""
Unit tests for the data_models module.
"""

import unittest
from datetime import datetime, timezone
from project_name.src.data_models import StandardSensorData

class TestStandardSensorData(unittest.TestCase):

    def setUp(self):
        self.test_timestamp = datetime(2023, 1, 1, 12, 0, 0, tzinfo=timezone.utc)

    def test_standard_sensor_data_creation_minimal(self):
        """
        Test creation of StandardSensorData with only mandatory fields.
        """
        data = StandardSensorData(
            sensor_id="s1",
            timestamp=self.test_timestamp,
            manufacturer="TEST"
        )
        self.assertEqual(data.sensor_id, "s1")
        self.assertEqual(data.timestamp, self.test_timestamp)
        self.assertEqual(data.manufacturer, "TEST")
        self.assertIsNone(data.latitude)
        self.assertIsNone(data.engine_temp_celsius)

    def test_standard_sensor_data_creation_full(self):
        """
        Test creation of StandardSensorData with all fields populated.
        """
        data = StandardSensorData(
            sensor_id="s2",
            timestamp=self.test_timestamp,
            manufacturer="FULL",
            latitude=10.1,
            longitude=20.2,
            altitude=100.0,
            location_accuracy="HIGH",
            engine_temp_celsius=90.5,
            oil_pressure_psi=50.0,
            fuel_level_percent=75.0,
            engine_rpm=2500,
            engine_status="OK",
            raw_data_tags={"extra_tag": "value"}
        )
        self.assertEqual(data.sensor_id, "s2")
        self.assertEqual(data.timestamp, self.test_timestamp)
        self.assertEqual(data.manufacturer, "FULL")
        self.assertEqual(data.latitude, 10.1)
        self.assertEqual(data.longitude, 20.2)
        self.assertEqual(data.altitude, 100.0)
        self.assertEqual(data.location_accuracy, "HIGH")
        self.assertEqual(data.engine_temp_celsius, 90.5)
        self.assertEqual(data.oil_pressure_psi, 50.0)
        self.assertEqual(data.fuel_level_percent, 75.0)
        self.assertEqual(data.engine_rpm, 2500)
        self.assertEqual(data.engine_status, "OK")
        self.assertEqual(data.raw_data_tags, {"extra_tag": "value"})

    def test_standard_sensor_data_to_dict_minimal(self):
        """
        Test conversion to dictionary for minimal data.
        """
        data = StandardSensorData(
            sensor_id="s3",
            timestamp=self.test_timestamp,
            manufacturer="TEST"
        )
        expected_dict = {
            "sensor_id": "s3",
            "timestamp": self.test_timestamp.isoformat(),
            "manufacturer": "TEST"
        }
        self.assertEqual(data.to_dict(), expected_dict)

    def test_standard_sensor_data_to_dict_full(self):
        """
        Test conversion to dictionary for full data, ensuring optional None fields are omitted.
        """
        data = StandardSensorData(
            sensor_id="s4",
            timestamp=self.test_timestamp,
            manufacturer="FULL",
            latitude=10.1,
            longitude=20.2,
            engine_temp_celsius=90.5,
            engine_status="OK"
        )
        expected_dict = {
            "sensor_id": "s4",
            "timestamp": self.test_timestamp.isoformat(),
            "manufacturer": "FULL",
            "latitude": 10.1,
            "longitude": 20.2,
            "engine_temp_celsius": 90.5,
            "engine_status": "OK"
        }
        self.assertEqual(data.to_dict(), expected_dict)

    def test_standard_sensor_data_to_dict_with_raw_tags(self):
        """
        Test conversion to dictionary when raw_data_tags is present.
        """
        raw_tags_data = {"firmware_version": "1.2.3", "battery_status": "GOOD"}
        data = StandardSensorData(
            sensor_id="s5",
            timestamp=self.test_timestamp,
            manufacturer="TAGS",
            raw_data_tags=raw_tags_data
        )
        expected_dict = {
            "sensor_id": "s5",
            "timestamp": self.test_timestamp.isoformat(),
            "manufacturer": "TAGS",
            "raw_data_tags": raw_tags_data
        }
        self.assertEqual(data.to_dict(), expected_dict)

if __name__ == '__main__':
    unittest.main()
