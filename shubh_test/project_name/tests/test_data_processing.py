import unittest
from datetime import datetime
from unittest.mock import patch

from src.data_processing import (
    identify_source_and_parse,
    clean_sensor_data,
    transform_to_standard_schema,
    process_raw_sensor_data
)
from src.data_ingestion import receive_raw_sensor_data
from src.models import RawSensorData, StandardSensorData
from src.config import SENSOR_FORMATS, CLEANING_RULES
from src.logger import app_logger

class TestDataProcessing(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        # Suppress logging output during tests for cleaner console, but keep it for debugging if needed
        app_logger.setLevel(100) # CRITICAL + 1 to effectively disable

    @classmethod
    def tearDownClass(cls):
        app_logger.setLevel(10) # Reset to DEBUG or INFO after tests

    def setUp(self):
        self.mock_raw_data_ref = "mock_raw_data_content"
        self.mock_timestamp = datetime(2023, 10, 27, 10, 0, 0)

    def test_identify_source_and_parse_truck_a_valid(self):
        """
        Test TR-IOT-002, Stage 2: Source identification and parsing for TRUCK_A (CSV).
        """
        raw_data_str = "TRUCK_A,2023-10-27T10:00:00Z,34.0522,-118.2437,85,200,1500"
        raw_sensor_data = RawSensorData(data=raw_data_str, received_timestamp=self.mock_timestamp)
        parsed_data = identify_source_and_parse(raw_sensor_data)

        self.assertIsNotNone(parsed_data)
        self.assertEqual(parsed_data["device_id"], "TRUCK_A")
        self.assertEqual(parsed_data["timestamp"], "2023-10-27T10:00:00Z")
        self.assertEqual(parsed_data["latitude"], "34.0522")
        self.assertEqual(parsed_data["fuel_level"], "85")
        self.assertEqual(parsed_data["_sensor_type"], "TRUCK_A")
        self.assertEqual(parsed_data["_format_config"], SENSOR_FORMATS["TRUCK_A"])

    def test_identify_source_and_parse_truck_b_valid(self):
        """
        Test TR-IOT-002, Stage 2: Source identification and parsing for TRUCK_B (Key-Value).
        """
        raw_data_str = "TRUCK_B,2023-10-27T10:00:05Z,LOC:34.0525,-118.2440;FUEL:84;ENG:201,1510"
        raw_sensor_data = RawSensorData(data=raw_data_str, received_timestamp=self.mock_timestamp)
        parsed_data = identify_source_and_parse(raw_sensor_data)

        self.assertIsNotNone(parsed_data)
        self.assertEqual(parsed_data["device_id"], "TRUCK_B")
        self.assertEqual(parsed_data["timestamp"], "2023-10-27T10:00:05Z")
        self.assertEqual(parsed_data["latitude"], "34.0525")
        self.assertEqual(parsed_data["longitude"], "-118.2440")
        self.assertEqual(parsed_data["fuel_level"], "84")
        self.assertEqual(parsed_data["engine_temperature"], "201")
        self.assertEqual(parsed_data["engine_rpm"], "1510")
        self.assertEqual(parsed_data["_sensor_type"], "TRUCK_B")
        self.assertEqual(parsed_data["_format_config"], SENSOR_FORMATS["TRUCK_B"])

    def test_identify_source_and_parse_unknown_format(self):
        """
        Test TR-IOT-002, Stage 2: Handling of unknown sensor data format.
        """
        raw_data_str = "UNKNOWN_SENSOR,data1,data2"
        raw_sensor_data = RawSensorData(data=raw_data_str, received_timestamp=self.mock_timestamp)
        parsed_data = identify_source_and_parse(raw_sensor_data)
        self.assertIsNone(parsed_data)

    def test_identify_source_and_parse_malformed_csv(self):
        """
        Test TR-IOT-002, Stage 2: Handling of malformed CSV data.
        """
        raw_data_str = "TRUCK_A,2023-10-27T10:00:00Z,34.0522,-118.2437,85,200" # Missing RPM
        raw_sensor_data = RawSensorData(data=raw_data_str, received_timestamp=self.mock_timestamp)
        parsed_data = identify_source_and_parse(raw_sensor_data)
        self.assertIsNone(parsed_data)

    def test_clean_sensor_data_valid(self):
        """
        Test TR-IOT-002, Stage 3: Cleaning valid data.
        """
        parsed_data = {
            "device_id": "TRUCK_A",
            "timestamp": "2023-10-27T10:00:00Z",
            "latitude": "34.0522",
            "longitude": "-118.2437",
            "fuel_level": "85",
            "engine_temperature": "200",
            "engine_rpm": "1500",
            "_sensor_type": "TRUCK_A",
            "_format_config": SENSOR_FORMATS["TRUCK_A"]
        }
        cleaned_data = clean_sensor_data(parsed_data)

        self.assertEqual(cleaned_data["device_id"], "TRUCK_A")
        self.assertEqual(cleaned_data["timestamp"], self.mock_timestamp)
        self.assertEqual(cleaned_data["latitude"], 34.0522)
        self.assertEqual(cleaned_data["fuel_level"], 85)
        self.assertEqual(cleaned_data["engine_temperature"], 200)
        self.assertEqual(cleaned_data["engine_rpm"], 1500)

    def test_clean_sensor_data_invalid_fuel_level(self):
        """
        Test TR-IOT-002, Stage 3: Cleaning data with out-of-range fuel level.
        """
        parsed_data = {
            "device_id": "TRUCK_A",
            "timestamp": "2023-10-27T10:00:00Z",
            "latitude": "34.0522",
            "longitude": "-118.2437",
            "fuel_level": "105", # Invalid
            "engine_temperature": "200",
            "engine_rpm": "1500",
            "_sensor_type": "TRUCK_A",
            "_format_config": SENSOR_FORMATS["TRUCK_A"]
        }
        cleaned_data = clean_sensor_data(parsed_data)
        self.assertEqual(cleaned_data["fuel_level"], CLEANING_RULES["fuel_level"]["default_on_invalid"]) # Should be 0

    def test_clean_sensor_data_invalid_latitude(self):
        """
        Test TR-IOT-002, Stage 3: Cleaning data with out-of-range latitude.
        """
        parsed_data = {
            "device_id": "TRUCK_A",
            "timestamp": "2023-10-27T10:00:00Z",
            "latitude": "999.0", # Invalid
            "longitude": "-118.2437",
            "fuel_level": "85",
            "engine_temperature": "200",
            "engine_rpm": "1500",
            "_sensor_type": "TRUCK_A",
            "_format_config": SENSOR_FORMATS["TRUCK_A"]
        }
        cleaned_data = clean_sensor_data(parsed_data)
        self.assertIsNone(cleaned_data["latitude"]) # Should be None as no default_on_invalid

    def test_clean_sensor_data_non_numeric_engine_temp(self):
        """
        Test TR-IOT-002, Stage 3: Cleaning data with non-numeric engine temperature.
        """
        parsed_data = {
            "device_id": "TRUCK_A",
            "timestamp": "2023-10-27T10:00:00Z",
            "latitude": "34.0522",
            "longitude": "-118.2437",
            "fuel_level": "85",
            "engine_temperature": "abc", # Invalid
            "engine_rpm": "1500",
            "_sensor_type": "TRUCK_A",
            "_format_config": SENSOR_FORMATS["TRUCK_A"]
        }
        cleaned_data = clean_sensor_data(parsed_data)
        self.assertEqual(cleaned_data["engine_temperature"], CLEANING_RULES["engine_temperature"]["default_on_invalid"]) # Should be 100

    def test_transform_to_standard_schema_valid(self):
        """
        Test TR-IOT-002, Stage 4: Transformation to standard schema with valid data.
        """
        cleaned_data = {
            "device_id": "TRUCK_A",
            "timestamp": self.mock_timestamp,
            "latitude": 34.0522,
            "longitude": -118.2437,
            "fuel_level": 85,
            "engine_temperature": 200,
            "engine_rpm": 1500,
            "extra_field": "some_value" # Should go into additional_info
        }
        standard_data = transform_to_standard_schema(cleaned_data, self.mock_raw_data_ref)

        self.assertIsInstance(standard_data, StandardSensorData)
        self.assertEqual(standard_data.device_id, "TRUCK_A")
        self.assertEqual(standard_data.timestamp, self.mock_timestamp)
        self.assertEqual(standard_data.latitude, 34.0522)
        self.assertEqual(standard_data.fuel_level, 85)
        self.assertEqual(standard_data.additional_info, {"extra_field": "some_value"})
        self.assertEqual(standard_data.raw_data_ref, self.mock_raw_data_ref)

    def test_transform_to_standard_schema_missing_essential_fields(self):
        """
        Test TR-IOT-002, Stage 4: Transformation with missing device_id or timestamp.
        """
        cleaned_data_no_device_id = {
            "timestamp": self.mock_timestamp,
            "latitude": 34.0522
        }
        standard_data = transform_to_standard_schema(cleaned_data_no_device_id, self.mock_raw_data_ref)
        self.assertIsNone(standard_data)

        cleaned_data_no_timestamp = {
            "device_id": "TRUCK_A",
            "latitude": 34.0522
        }
        standard_data = transform_to_standard_schema(cleaned_data_no_timestamp, self.mock_raw_data_ref)
        self.assertIsNone(standard_data)

    def test_process_raw_sensor_data_end_to_end_valid(self):
        """
        Test TR-IOT-002: End-to-end processing with valid data.
        """
        raw_data_str = "TRUCK_A,2023-10-27T10:00:00Z,34.0522,-118.2437,85,200,1500"
        raw_sensor_data = receive_raw_sensor_data(raw_data_str, "Gateway-001")
        processed_data = process_raw_sensor_data(raw_sensor_data)

        self.assertIsInstance(processed_data, StandardSensorData)
        self.assertEqual(processed_data.device_id, "TRUCK_A")
        self.assertEqual(processed_data.latitude, 34.0522)
        self.assertEqual(processed_data.fuel_level, 85)
        self.assertEqual(processed_data.raw_data_ref, raw_data_str)

    def test_process_raw_sensor_data_end_to_end_invalid_data(self):
        """
        Test TR-IOT-002: End-to-end processing with data that causes cleaning/parsing issues.
        """
        # Malformed data for TRUCK_A (missing fields)
        raw_data_str_malformed = "TRUCK_A,2023-10-27T10:00:00Z,34.0522,-118.2437,85"
        raw_sensor_data_malformed = receive_raw_sensor_data(raw_data_str_malformed, "Gateway-001")
        processed_data_malformed = process_raw_sensor_data(raw_sensor_data_malformed)
        self.assertIsNone(processed_data_malformed)

        # Data with invalid values that get cleaned to None or default
        raw_data_str_invalid_values = "TRUCK_A,2023-10-27T10:00:00Z,999.0,-118.2437,105,abc,1500"
        raw_sensor_data_invalid_values = receive_raw_sensor_data(raw_data_str_invalid_values, "Gateway-001")
        processed_data_invalid_values = process_raw_sensor_data(raw_sensor_data_invalid_values)
        self.assertIsNotNone(processed_data_invalid_values)
        self.assertIsNone(processed_data_invalid_values.latitude) # 999.0 is out of range, no default
        self.assertEqual(processed_data_invalid_values.fuel_level, CLEANING_RULES["fuel_level"]["default_on_invalid"]) # 105 is out of range, has default
        self.assertEqual(processed_data_invalid_values.engine_temperature, CLEANING_RULES["engine_temperature"]["default_on_invalid"]) # 'abc' is invalid, has default

    def test_process_raw_sensor_data_end_to_end_unknown_sensor(self):
        """
        Test TR-IOT-002: End-to-end processing with an unknown sensor type.
        """
        raw_data_str = "UNKNOWN_TRUCK,2023-10-27T10:00:00Z,34.0522,-118.2437,85,200,1500"
        raw_sensor_data = receive_raw_sensor_data(raw_data_str, "Gateway-001")
        processed_data = process_raw_sensor_data(raw_sensor_data)
        self.assertIsNone(processed_data)

if __name__ == '__main__':
    unittest.main()
