"""
Unit tests for the normalization module.
"""

import unittest
import logging
from datetime import datetime, timezone
from unittest.mock import patch, MagicMock

from project_name.src.normalization import Normalizer
from project_name.src.data_models import StandardSensorData
from project_name.src.config import AppConfig # For manufacturer mappings

class TestNormalizer(unittest.TestCase):

    def setUp(self):
        self.normalizer = Normalizer()
        # Suppress logging during tests to keep console clean
        logging.disable(logging.CRITICAL)

    def tearDown(self):
        logging.disable(logging.NOTSET) # Re-enable logging after tests

    def test_identify_manufacturer_bosch(self):
        """
        Test correct identification of BOSCH manufacturer.
        """
        raw_data = "BOSCH|SENSOR_ID:truck_001|..."
        manufacturer = self.normalizer._identify_manufacturer(raw_data)
        self.assertEqual(manufacturer, "BOSCH")

    def test_identify_manufacturer_garmin(self):
        """
        Test correct identification of GARMIN manufacturer.
        """
        raw_data = "GARMIN|DEVICE_ID:truck_002|..."
        manufacturer = self.normalizer._identify_manufacturer(raw_data)
        self.assertEqual(manufacturer, "GARMIN")

    def test_identify_manufacturer_generic(self):
        """
        Test fallback to GENERIC manufacturer for unknown formats.
        """
        raw_data = "UNKNOWN_VENDOR|ID:sensor_X|..."
        manufacturer = self.normalizer._identify_manufacturer(raw_data)
        self.assertEqual(manufacturer, "GENERIC")

    def test_normalize_data_bosch_full(self):
        """
        Test normalization of a complete BOSCH data string.
        """
        raw_data = "BOSCH|SENSOR_ID:truck_001|TS:1678886400|LAT:34.0522|LON:-118.2437|ET:85.5|OP:45.0|FL:75|ES:OK"
        expected_timestamp = datetime(2023, 3, 15, 10, 40, 0, tzinfo=timezone.utc) # Example value for patched datetime
        
        with patch('project_name.src.normalization.datetime') as mock_dt:
            mock_dt.fromtimestamp.return_value = expected_timestamp
            mock_dt.now.return_value = datetime(2023, 3, 15, 10, 40, 0, tzinfo=timezone.utc)
            mock_dt.strptime = datetime.strptime # ensure strptime works as normal
            mock_dt.side_effect = lambda *args, **kw: datetime(*args, **kw) # Allow other datetime ops

            normalized = self.normalizer.normalize_data(raw_data)

            self.assertIsNotNone(normalized)
            self.assertIsInstance(normalized, StandardSensorData)
            self.assertEqual(normalized.sensor_id, "truck_001")
            self.assertEqual(normalized.timestamp, expected_timestamp)
            self.assertEqual(normalized.manufacturer, "BOSCH")
            self.assertEqual(normalized.latitude, 34.0522)
            self.assertEqual(normalized.longitude, -118.2437)
            self.assertEqual(normalized.engine_temp_celsius, 85.5)
            self.assertEqual(normalized.oil_pressure_psi, 45.0)
            self.assertEqual(normalized.fuel_level_percent, 75.0)
            self.assertEqual(normalized.engine_status, "OK")
            self.assertIsNone(normalized.altitude)
            self.assertIsNone(normalized.engine_rpm)

    def test_normalize_data_garmin_full(self):
        """
        Test normalization of a complete GARMIN data string with ISO timestamp.
        """
        raw_data = "GARMIN|DEVICE_ID:truck_002|DATETIME:2023-03-15T10:30:00Z|GPS_LAT:34.1000|GPS_LON:-118.3000|ALT:100.5|ACCURACY:HIGH|RPM:1500|ENG_STAT:OK"
        expected_timestamp = datetime(2023, 3, 15, 10, 30, 0, tzinfo=timezone.utc)

        normalized = self.normalizer.normalize_data(raw_data)

        self.assertIsNotNone(normalized)
        self.assertIsInstance(normalized, StandardSensorData)
        self.assertEqual(normalized.sensor_id, "truck_002")
        self.assertEqual(normalized.timestamp, expected_timestamp)
        self.assertEqual(normalized.manufacturer, "GARMIN")
        self.assertEqual(normalized.latitude, 34.1000)
        self.assertEqual(normalized.longitude, -118.3000)
        self.assertEqual(normalized.altitude, 100.5)
        self.assertEqual(normalized.location_accuracy, "HIGH")
        self.assertEqual(.engine_rpm, 1500)
        self.assertEqual(normalized.engine_status, "OK")
        self.assertIsNone(normalized.engine_temp_celsius)

    def test_normalize_data_missing_mandatory_fields(self):
        """
        Test normalization when mandatory fields (like sensor_id or timestamp) are missing.
        """
        # Missing SENSOR_ID
        raw_data_no_id = "BOSCH|TS:1678886400|LAT:34.0522|LON:-118.2437|ET:85.5|OP:45.0|FL:75|ES:OK"
        # Missing TS
        raw_data_no_ts = "BOSCH|SENSOR_ID:truck_001|LAT:34.0522|LON:-118.2437|ET:85.5|OP:45.0|FL:75|ES:OK"

        with self.assertLogs('project_name.src.normalization', level='ERROR') as cm:
            normalized_no_id = self.normalizer.normalize_data(raw_data_no_id)
            self.assertIsNone(normalized_no_id)
            self.assertIn("Missing crucial field during normalization", cm.output[0])

        with self.assertLogs('project_name.src.normalization', level='ERROR') as cm:
            normalized_no_ts = self.normalizer.normalize_data(raw_data_no_ts)
            self.assertIsNone(normalized_no_ts)
            self.assertIn("Missing crucial field during normalization", cm.output[0])


    def test_normalize_data_empty_input(self):
        """
        Test normalization with an empty input string.
        """
        normalized = self.normalizer.normalize_data("")
        self.assertIsNone(normalized)

    def test_normalize_data_unmapped_fields(self):
        """
        Test that unmapped fields are ignored (not present in StandardSensorData).
        """
        raw_data = "BOSCH|SENSOR_ID:truck_001|TS:1678886400|LAT:34.0522|LON:-118.2437|CUSTOM_FIELD:123|ET:85.5"
        expected_timestamp = datetime(2023, 3, 15, 10, 40, 0, tzinfo=timezone.utc)
        
        with patch('project_name.src.normalization.datetime') as mock_dt:
            mock_dt.fromtimestamp.return_value = expected_timestamp
            mock_dt.now.return_value = datetime(2023, 3, 15, 10, 40, 0, tzinfo=timezone.utc)
            mock_dt.strptime = datetime.strptime # ensure strptime works as normal
            mock_dt.side_effect = lambda *args, **kw: datetime(*args, **kw) # Allow other datetime ops

            normalized = self.normalizer.normalize_data(raw_data)
            self.assertIsNotNone(normalized)
            self.assertIsNone(getattr(normalized, 'custom_field', None)) # Should not be part of the model

    def test_normalize_data_generic_parser(self):
        """
        Test normalization using the generic parser for an unknown manufacturer.
        """
        raw_data = "MY_SENSOR|ID:generic_001|TIME:1678886400|LAT:33.0|LON:-117.0"
        expected_timestamp = datetime(2023, 3, 15, 10, 40, 0, tzinfo=timezone.utc)

        with patch('project_name.src.normalization.datetime') as mock_dt:
            mock_dt.fromtimestamp.return_value = expected_timestamp
            mock_dt.now.return_value = datetime(2023, 3, 15, 10, 40, 0, tzinfo=timezone.utc)
            mock_dt.strptime = datetime.strptime # ensure strptime works as normal
            mock_dt.side_effect = lambda *args, **kw: datetime(*args, **kw) # Allow other datetime ops

            normalized = self.normalizer.normalize_data(raw_data)
            self.assertIsNotNone(normalized)
            self.assertEqual(normalized.manufacturer, "GENERIC")
            self.assertEqual(normalized.sensor_id, "generic_001")
            self.assertEqual(normalized.timestamp, expected_timestamp)
            self.assertEqual(normalized.latitude, 33.0)
            self.assertEqual(normalized.longitude, -117.0)
            self.assertIsNone(normalized.engine_temp_celsius) # Generic doesn't map these

    def test_safe_float_conversion(self):
        self.assertIsNone(self.normalizer._safe_float_conversion(None))
        self.assertIsNone(self.normalizer._safe_float_conversion("abc"))
        self.assertEqual(self.normalizer._safe_float_conversion("123.45"), 123.45)
        self.assertEqual(self.normalizer._safe_float_conversion(123), 123.0)

    def test_safe_int_conversion(self):
        self.assertIsNone(self.normalizer._safe_int_conversion(None))
        self.assertIsNone(self.normalizer._safe_int_conversion("abc"))
        self.assertEqual(self.normalizer._safe_int_conversion("123"), 123)
        self.assertEqual(self.normalizer._safe_int_conversion(123.0), 123)

if __name__ == '__main__':
    unittest.main()
