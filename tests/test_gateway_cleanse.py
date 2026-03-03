"""
Unit tests for the gateway_cleanse module.
"""

import unittest
import datetime
from unittest.mock import patch

from project_name.src.gateway_cleanse import SensorDataCleanser
from project_name.src.gateway_schemas import CleansingFlag, RawSensorData, CleansedSensorData

class TestSensorDataCleanser(unittest.TestCase):

    def setUp(self):
        """Set up for test methods."""
        self.cleanser = SensorDataCleanser()
        # Mock datetime.now() for consistent timestamps in parsing, if needed.
        # For now, we only parse existing timestamps.

    def test_cleanse_valid_bosch_data(self):
        """Test cleansing a valid Bosch raw data string."""
        raw_data = "BOSCH,2023-10-27T10:00:00Z,TRUCK001,40.7128,-74.0060,55.2,85.1,NORMAL"
        cleaned = self.cleanser.cleanse(raw_data)

        self.assertIsInstance(cleaned, dict)
        self.assertEqual(cleaned["manufacturer"], "BOSCH")
        self.assertEqual(cleaned["truck_id"], "TRUCK001")
        self.assertEqual(cleaned["timestamp"], datetime.datetime(2023, 10, 27, 10, 0, 0, tzinfo=datetime.timezone.utc))
        self.assertAlmostEqual(cleaned["latitude"], 40.7128)
        self.assertAlmostEqual(cleaned["longitude"], -74.0060)
        self.assertAlmostEqual(cleaned["fuel_level_percent"], 55.2)
        self.assertAlmostEqual(cleaned["engine_temp_celsius"], 85.1)
        self.assertEqual(cleaned["engine_alert_code"], "NORMAL")
        self.assertEqual(cleaned["cleansing_flags"], [])
        self.assertEqual(cleaned["original_raw_data"], raw_data)

    def test_cleanse_valid_garmin_data_with_alert(self):
        """Test cleansing a valid Garmin raw data string with an alert."""
        raw_data = "GARMIN,2023-10-27T10:00:05Z,TRUCK002,34.0522,-118.2437,40.1,90.5,LOW_OIL_PRESSURE"
        cleaned = self.cleanser.cleanse(raw_data)

        self.assertEqual(cleaned["manufacturer"], "GARMIN")
        self.assertEqual(cleaned["truck_id"], "TRUCK002")
        self.assertEqual(cleaned["timestamp"], datetime.datetime(2023, 10, 27, 10, 0, 5, tzinfo=datetime.timezone.utc))
        self.assertAlmostEqual(cleaned["latitude"], 34.0522)
        self.assertEqual(cleaned["engine_alert_code"], "LOW_OIL_PRESSURE")
        self.assertEqual(cleaned["cleansing_flags"], [])

    def test_cleanse_data_with_zeroed_gps(self):
        """Test cleansing data where GPS coordinates are zeroed (noisy)."""
        raw_data = "BOSCH,2023-10-27T10:00:10Z,TRUCK001,0.0,0.0,55.1,85.0,NORMAL"
        cleaned = self.cleanser.cleanse(raw_data)

        self.assertAlmostEqual(cleaned["latitude"], 0.0)
        self.assertAlmostEqual(cleaned["longitude"], 0.0)
        self.assertIn(CleansingFlag.GPS_ZEROED, cleaned["cleansing_flags"])
        self.assertEqual(len(cleaned["cleansing_flags"]), 1)

    def test_cleanse_data_with_invalid_fuel_level(self):
        """Test cleansing data with an out-of-range fuel level."""
        raw_data = "GARMIN,2023-10-27T10:00:15Z,TRUCK003,33.0,-117.0,105.0,120.0,TEMP_EXCEEDED"
        cleaned = self.cleanser.cleanse(raw_data)

        self.assertAlmostEqual(cleaned["fuel_level_percent"], 100.0) # Clamped to max
        self.assertIn(CleansingFlag.FUEL_LEVEL_INVALID, cleaned["cleansing_flags"])
        self.assertAlmostEqual(cleaned["engine_temp_celsius"], 120.0) # Within default max (150)
        self.assertEqual(cleaned["engine_alert_code"], "TEMP_EXCEEDED")
        self.assertNotIn(CleansingFlag.ENGINE_TEMP_INVALID, cleaned["cleansing_flags"])

    def test_cleanse_data_with_invalid_engine_temp(self):
        """Test cleansing data with an out-of-range engine temperature."""
        raw_data = "BOSCH,2023-10-27T10:00:20Z,TRUCK004,38.0,-97.0,70.0,180.0,NORMAL"
        cleaned = self.cleanser.cleanse(raw_data)

        self.assertAlmostEqual(cleaned["engine_temp_celsius"], 150.0) # Clamped to max
        self.assertIn(CleansingFlag.ENGINE_TEMP_INVALID, cleaned["cleansing_flags"])
        self.assertEqual(len(cleaned["cleansing_flags"]), 1)

    def test_cleanse_data_with_missing_timestamp(self):
        """Test cleansing data with a missing (empty) timestamp."""
        raw_data = "BOSCH,,TRUCK004,38.0,-97.0,70.0,75.0,BATT_CRIT"
        cleaned = self.cleanser.cleanse(raw_data)

        self.assertIn(CleansingFlag.INVALID_TIMESTAMP, cleaned["cleansing_flags"])
        # Should default to datetime.min or a safe value
        self.assertEqual(cleaned["timestamp"], datetime.datetime.min)
        self.assertEqual(cleaned["engine_alert_code"], "BATT_CRIT")

    def test_cleanse_malformed_data_too_few_fields(self):
        """Test cleansing malformed data with too few fields."""
        raw_data = "MALFORMED_SENSOR,2023-10-27T10:00:25Z,TRUCK005,10.0,20.0" # Missing fuel, temp, alert
        cleaned = self.cleanser.cleanse(raw_data)

        self.assertEqual(cleaned["manufacturer"], "MALFORMED_SENSOR")
        self.assertAlmostEqual(cleaned["latitude"], 10.0)
        self.assertAlmostEqual(cleaned["longitude"], 20.0)
        # Should default or clamp missing numeric fields, and flag MISSING_FIELD
        self.assertIn(CleansingFlag.MISSING_FIELD, cleaned["cleansing_flags"])
        self.assertIn(CleansingFlag.FUEL_LEVEL_INVALID, cleaned["cleansing_flags"]) # Due to default 0.0 being clamped
        self.assertIn(CleansingFlag.ENGINE_TEMP_INVALID, cleaned["cleansing_flags"]) # Due to default 0.0 being clamped
        self.assertIsNone(cleaned["engine_alert_code"])
        
    def test_cleanse_malformed_data_non_numeric_gps(self):
        """Test cleansing data with non-numeric GPS coordinates."""
        raw_data = "BOSCH,2023-10-27T10:00:00Z,TRUCK001,INVALID_LAT,-74.0060,55.2,85.1,NORMAL"
        cleaned = self.cleanser.cleanse(raw_data)

        self.assertIn(CleansingFlag.MISSING_FIELD, cleaned["cleansing_flags"])
        self.assertIn(CleansingFlag.GPS_INVALID_RANGE, cleaned["cleansing_flags"])
        self.assertAlmostEqual(cleaned["latitude"], 0.0) # Should default to 0.0 or a safe value

    def test_cleanse_data_with_invalid_gps_range(self):
        """Test cleansing data with GPS coordinates outside valid range."""
        raw_data = "GARMIN,2023-10-27T10:00:00Z,TRUCK001,91.0,-181.0,50.0,80.0,NORMAL"
        cleaned = self.cleanser.cleanse(raw_data)

        self.assertIn(CleansingFlag.GPS_INVALID_RANGE, cleaned["cleansing_flags"])
        self.assertAlmostEqual(cleaned["latitude"], 0.0)
        self.assertAlmostEqual(cleaned["longitude"], 0.0)


    def test_default_cleansing_rules(self):
        """Test that default rules are applied correctly."""
        cleanser = SensorDataCleanser()
        self.assertIn("gps_zero_threshold_lat", cleanser.cleansing_rules)
        self.assertIn("fuel_level_min", cleanser.cleansing_rules)

    def test_custom_cleansing_rules(self):
        """Test that custom rules can override defaults."""
        custom_rules = {
            "fuel_level_min": 10.0,
            "fuel_level_max": 90.0
        }
        cleanser = SensorDataCleanser(cleansing_rules=custom_rules)
        self.assertEqual(cleanser.cleansing_rules["fuel_level_min"], 10.0)
        self.assertEqual(cleanser.cleansing_rules["fuel_level_max"], 90.0)
        # Other default rules should still exist
        self.assertIn("gps_zero_threshold_lat", cleanser.cleansing_rules)

        raw_data = "BOSCH,2023-10-27T10:00:00Z,TRUCK001,40.0,-70.0,5.0,85.0,NORMAL"
        cleaned = cleanser.cleanse(raw_data)
        self.assertIn(CleansingFlag.FUEL_LEVEL_INVALID, cleaned["cleansing_flags"])
        self.assertAlmostEqual(cleaned["fuel_level_percent"], 10.0) # Clamped by custom rule

    @patch('project_name.src.gateway_cleanse.logger')
    def test_logging_warnings(self, mock_logger):
        """Test that warnings are logged for noisy data."""
        raw_data_invalid_gps = "BOSCH,2023-10-27T10:00:00Z,TRUCK001,0.0,0.0,55.2,85.1,NORMAL"
        self.cleanser.cleanse(raw_data_invalid_gps)
        mock_logger.debug.assert_called()
        self.assertIn("GPS zeroed detected", mock_logger.debug.call_args[0][0])
        
        mock_logger.reset_mock()
        raw_data_invalid_fuel = "GARMIN,2023-10-27T10:00:15Z,TRUCK003,33.0,-117.0,105.0,120.0,TEMP_EXCEEDED"
        self.cleanser.cleanse(raw_data_invalid_fuel)
        mock_logger.warning.assert_called()
        self.assertIn("Invalid fuel level", mock_logger.warning.call_args[0][0])


if __name__ == '__main__':
    unittest.main()

