"""
Unit tests for the gateway_normalize module.
"""

import unittest
import datetime
from typing import cast
from unittest.mock import patch

from project_name.src.gateway_normalize import SensorDataNormalizer
from project_name.src.gateway_schemas import CleansedSensorData, StandardSensorData, EngineAlertCode, CleansingFlag

class TestSensorDataNormalizer(unittest.TestCase):

    def setUp(self):
        """Set up for test methods."""
        self.normalizer = SensorDataNormalizer()

    def _create_cleansed_data(self, **kwargs) -> CleansedSensorData:
        """Helper to create a CleansedSensorData dict with defaults."""
        default_data: CleansedSensorData = {
            "manufacturer": "BOSCH",
            "timestamp": datetime.datetime(2023, 10, 27, 10, 0, 0, tzinfo=datetime.timezone.utc),
            "truck_id": "TRUCK001",
            "latitude": 40.7128,
            "longitude": -74.0060,
            "fuel_level_percent": 55.2,
            "engine_temp_celsius": 85.1,
            "engine_alert_code": None,
            "cleansing_flags": [],
            "original_raw_data": "BOSCH,2023-10-27T10:00:00Z,TRUCK001,40.7128,-74.0060,55.2,85.1,NORMAL"
        }
        default_data.update(kwargs)
        return default_data

    def test_normalize_valid_bosch_data(self):
        """Test normalizing valid Bosch data."""
        cleansed = self._create_cleansed_data(
            manufacturer="BOSCH",
            engine_alert_code="NORMAL"
        )
        normalized = self.normalizer.normalize(cleansed)

        self.assertIsInstance(normalized, dict)
        self.assertEqual(normalized["manufacturer"], "BOSCH")
        self.assertEqual(normalized["truck_id"], "TRUCK001")
        self.assertEqual(normalized["timestamp_utc"], cleansed["timestamp"])
        self.assertAlmostEqual(normalized["latitude"], 40.7128)
        self.assertIsNone(normalized["engine_alert_code"]) # "NORMAL" maps to None
        self.assertFalse(normalized["is_engine_alert"])
        self.assertTrue(normalized["is_location_update"])
        self.assertEqual(normalized["cleansing_flags"], [])
        self.assertIn("TRUCK001-2023-10-27T10:00:00+00:00", normalized["sensor_id"])


    def test_normalize_garmin_data_with_alert(self):
        """Test normalizing Garmin data with a recognized alert."""
        cleansed = self._create_cleansed_data(
            manufacturer="GARMIN",
            truck_id="TRUCK002",
            timestamp=datetime.datetime(2023, 10, 27, 10, 0, 5, tzinfo=datetime.timezone.utc),
            latitude=34.0522,
            longitude=-118.2437,
            engine_alert_code="LOW_OIL_PRESSURE"
        )
        normalized = self.normalizer.normalize(cleansed)

        self.assertEqual(normalized["manufacturer"], "GARMIN")
        self.assertEqual(normalized["truck_id"], "TRUCK002")
        self.assertEqual(normalized["engine_alert_code"], EngineAlertCode.LOW_OIL_PRESSURE)
        self.assertTrue(normalized["is_engine_alert"])
        self.assertTrue(normalized["is_location_update"])

    def test_normalize_bosch_data_with_unrecognized_alert(self):
        """Test normalizing Bosch data with an unrecognized alert code."""
        cleansed = self._create_cleansed_data(
            manufacturer="BOSCH",
            truck_id="TRUCK007",
            timestamp=datetime.datetime(2023, 10, 27, 10, 0, 40, tzinfo=datetime.timezone.utc),
            engine_alert_code="UNIDENTIFIED_ISSUE"
        )
        normalized = self.normalizer.normalize(cleansed)

        self.assertEqual(normalized["manufacturer"], "BOSCH")
        self.assertEqual(normalized["engine_alert_code"], EngineAlertCode.UNKNOWN_ALERT)
        self.assertTrue(normalized["is_engine_alert"])

    def test_normalize_data_with_zeroed_gps_flag(self):
        """Test normalizing data that had zeroed GPS flagged during cleansing."""
        cleansed = self._create_cleansed_data(
            manufacturer="BOSCH",
            truck_id="TRUCK001",
            timestamp=datetime.datetime(2023, 10, 27, 10, 0, 10, tzinfo=datetime.timezone.utc),
            latitude=0.0,
            longitude=0.0,
            cleansing_flags=[CleansingFlag.GPS_ZEROED]
        )
        normalized = self.normalizer.normalize(cleansed)

        self.assertAlmostEqual(normalized["latitude"], 0.0)
        self.assertAlmostEqual(normalized["longitude"], 0.0)
        self.assertIn(CleansingFlag.GPS_ZEROED, normalized["cleansing_flags"])
        self.assertTrue(normalized["is_location_update"]) # Zeroed GPS is still an update, but flagged.
                                                           # Policy might differ, e.g., set is_location_update to False.

    def test_normalize_data_with_invalid_timestamp_flag(self):
        """Test normalizing data that had an invalid timestamp flagged."""
        cleansed = self._create_cleansed_data(
            manufacturer="BOSCH",
            truck_id="TRUCK004",
            timestamp=datetime.datetime.min, # Cleanser sets to min if invalid
            engine_alert_code="BATT_CRIT",
            cleansing_flags=[CleansingFlag.INVALID_TIMESTAMP]
        )
        normalized = self.normalizer.normalize(cleansed)

        self.assertEqual(normalized["timestamp_utc"], datetime.datetime.min)
        self.assertIn(CleansingFlag.INVALID_TIMESTAMP, normalized["cleansing_flags"])
        self.assertEqual(normalized["engine_alert_code"], EngineAlertCode.CRITICAL_BATTERY)
        self.assertTrue(normalized["is_engine_alert"])

    def test_normalize_data_missing_field_from_cleansed(self):
        """Test normalizing data where a field was missing/invalid in cleansed stage."""
        cleansed = self._create_cleansed_data(
            manufacturer="MALFORMED_SENSOR", # Using a generic manufacturer
            truck_id="TRUCK005",
            latitude=10.0,
            longitude=20.0,
            fuel_level_percent=0.0, # Cleanser would set to 0 or clamp
            engine_temp_celsius=0.0, # Cleanser would set to 0 or clamp
            engine_alert_code=None,
            cleansing_flags=[
                CleansingFlag.MISSING_FIELD,
                CleansingFlag.FUEL_LEVEL_INVALID,
                CleansingFlag.ENGINE_TEMP_INVALID
            ]
        )
        normalized = self.normalizer.normalize(cleansed)
        self.assertEqual(normalized["manufacturer"], "MALFORMED_SENSOR")
        self.assertIn(CleansingFlag.MISSING_FIELD, normalized["cleansing_flags"])
        self.assertFalse(normalized["is_engine_alert"])
        self.assertTrue(normalized["is_location_update"])

    def test_schema_validation_missing_field(self):
        """Test that normalization fails if a required field is missing after transformation."""
        cleansed = self._create_cleansed_data()
        
        # Manually alter the normalizer's internal method to simulate a missing field
        original_apply_mapping = self.normalizer._apply_manufacturer_mapping
        def mock_apply_mapping(data):
            transformed = original_apply_mapping(data)
            if "truck_id" in transformed:
                del transformed["truck_id"] # Simulate missing
            return transformed
        
        self.normalizer._apply_manufacturer_mapping = mock_apply_mapping # type: ignore

        with self.assertRaisesRegex(ValueError, "Missing required field: truck_id"):
            self.normalizer.normalize(cleansed)
        
        # Restore original method
        self.normalizer._apply_manufacturer_mapping = original_apply_mapping # type: ignore

    def test_schema_validation_type_mismatch(self):
        """Test that normalization fails if a field has the wrong type after transformation."""
        cleansed = self._create_cleansed_data()

        # Manually alter the normalizer's internal method to simulate a type mismatch
        original_apply_mapping = self.normalizer._apply_manufacturer_mapping
        def mock_apply_mapping(data):
            transformed = original_apply_mapping(data)
            transformed["latitude"] = "not_a_float" # Simulate wrong type
            return transformed
        
        self.normalizer._apply_manufacturer_mapping = mock_apply_mapping # type: ignore

        with self.assertRaisesRegex(TypeError, "Field 'latitude' has wrong type"):
            self.normalizer.normalize(cleansed)
        
        # Restore original method
        self.normalizer._apply_manufacturer_mapping = original_apply_mapping # type: ignore

    @patch('project_name.src.gateway_normalize.logger')
    def test_logging_warnings(self, mock_logger):
        """Test that warnings are logged during normalization."""
        cleansed = self._create_cleansed_data(
            manufacturer="BOSCH",
            engine_alert_code="UNIDENTIFIED_ISSUE"
        )
        self.normalizer.normalize(cleansed)
        mock_logger.debug.assert_called() # Check for general debug logs
        # Specific check for alert mapping warning (though default maps unrecognized to UNKNOWN_ALERT)

        # Test extra fields warning
        original_apply_mapping = self.normalizer._apply_manufacturer_mapping
        def mock_apply_mapping_extra(data):
            transformed = original_apply_mapping(data)
            transformed["extra_field"] = "some_value" # Add an extra field
            return transformed
        
        self.normalizer._apply_manufacturer_mapping = mock_apply_mapping_extra # type: ignore
        cleansed_extra = self._create_cleansed_data()
        self.normalizer.normalize(cleansed_extra)
        mock_logger.warning.assert_called()
        self.assertIn("Extra field 'extra_field'", mock_logger.warning.call_args[0][0])
        self.normalizer._apply_manufacturer_mapping = original_apply_mapping # type: ignore


if __name__ == '__main__':
    unittest.main()

