"""
Integration tests for the main IoTDataGateway class.
"""

import unittest
import logging
from unittest.mock import patch, MagicMock
from datetime import datetime, timezone

from project_name.src.gateway import IoTDataGateway
from project_name.src.data_models import StandardSensorData
from project_name.src.config import AppConfig

class TestIoTDataGateway(unittest.TestCase):

    def setUp(self):
        self.gateway = IoTDataGateway()
        # Suppress logging during tests to keep console clean, unless specific log assertions are made
        logging.disable(logging.CRITICAL)

        # Mock agents to capture what they receive
        self.mock_maintenance_agent = MagicMock()
        self.mock_customer_tracking_agent = MagicMock()
        self.gateway.maintenance_router.maintenance_agent = self.mock_maintenance_agent
        self.gateway.customer_router.customer_tracking_agent = self.mock_customer_tracking_agent

    def tearDown(self):
        logging.disable(logging.NOTSET) # Re-enable logging after tests

    def test_full_pipeline_normal_data(self):
        """
        Test the entire pipeline with normal, valid sensor data.
        Expects no cleaning actions and both agents to receive data.
        """
        raw_data = "BOSCH|SENSOR_ID:truck_001|TS:1678886400|LAT:34.0522|LON:-118.2437|ET:85.5|OP:45.0|FL:75|ES:OK"
        
        # Patch datetime.now to ensure consistent timestamps for normalization
        with patch('project_name.src.normalization.datetime') as mock_dt:
            mock_dt.fromtimestamp.return_value = datetime(2023, 3, 15, 10, 40, 0, tzinfo=timezone.utc)
            mock_dt.now.return_value = datetime(2023, 3, 15, 10, 40, 0, tzinfo=timezone.utc)
            mock_dt.strptime = datetime.strptime # ensure strptime works as normal
            mock_dt.side_effect = lambda *args, **kw: datetime(*args, **kw) # Allow other datetime ops

            result = self.gateway.process_sensor_data(raw_data)

            self.assertIsNotNone(result)
            self.assertIsInstance(result, StandardSensorData)
            self.assertEqual(result.sensor_id, "truck_001")
            self.assertEqual(result.latitude, 34.0522)
            self.assertEqual(result.engine_temp_celsius, 85.5)

            # Assert routing: No engine alert, but location update should be sent
            self.mock_maintenance_agent.send_engine_alert.assert_not_called()
            self.mock_customer_tracking_agent.send_location_update.assert_called_once()
            args, _ = self.mock_customer_tracking_agent.send_location_update.call_args
            self.assertEqual(args[0]["latitude"], 34.0522)
            self.assertEqual(args[0]["longitude"], -118.2437)

    def test_full_pipeline_with_cleaning_and_routing_alert(self):
        """
        Test the pipeline with noisy data that requires cleaning and triggers an engine alert.
        """
        raw_data = "BOSCH|SENSOR_ID:truck_002|TS:1678886400|LAT:GPS:LOST|LON:INVALID|ENGINE_TEMP:105.0|OP:5.0|FL:75|ES:ALERT"
        
        with patch('project_name.src.normalization.datetime') as mock_dt:
            mock_dt.fromtimestamp.return_value = datetime(2023, 3, 15, 10, 40, 0, tzinfo=timezone.utc)
            mock_dt.now.return_value = datetime(2023, 3, 15, 10, 40, 0, tzinfo=timezone.utc)
            mock_dt.strptime = datetime.strptime # ensure strptime works as normal
            mock_dt.side_effect = lambda *args, **kw: datetime(*args, **kw) # Allow other datetime ops

            result = self.gateway.process_sensor_data(raw_data)

            self.assertIsNotNone(result)
            self.assertIsInstance(result, StandardSensorData)
            self.assertEqual(result.sensor_id, "truck_002")
            
            # Assert cleaning: GPS should be defaulted
            self.assertEqual(result.latitude, AppConfig.CLEANING_DEFAULTS["default_latitude"])
            self.assertEqual(result.longitude, AppConfig.CLEANING_DEFAULTS["default_longitude"])
            
            # Assert normalization: Engine temp and oil pressure should be parsed correctly
            self.assertEqual(result.engine_temp_celsius, 105.0)
            self.assertEqual(result.oil_pressure_psi, 5.0)
            self.assertEqual(result.engine_status, "ALERT")

            # Assert routing: Engine alert should be sent, location update with defaulted GPS
            self.mock_maintenance_agent.send_engine_alert.assert_called_once()
            alert_args, _ = self.mock_maintenance_agent.send_engine_alert.call_args
            self.assertEqual(alert_args[0]["sensor_id"], "truck_002")
            self.assertEqual(alert_args[0]["details"]["engine_temp_celsius"], 105.0)
            self.assertEqual(alert_args[0]["details"]["oil_pressure_psi"], 5.0)
            self.assertEqual(alert_args[0]["details"]["engine_status"], "ALERT")
            self.assertEqual(alert_args[0]["details"]["current_location"]["latitude"], AppConfig.CLEANING_DEFAULTS["default_latitude"])


            self.mock_customer_tracking_agent.send_location_update.assert_called_once()
            loc_args, _ = self.mock_customer_tracking_agent.send_location_update.call_args
            self.assertEqual(loc_args[0]["latitude"], AppConfig.CLEANING_DEFAULTS["default_latitude"])

    def test_full_pipeline_empty_raw_data(self):
        """
        Test the pipeline with an empty raw data string.
        Should fail gracefully at ingestion.
        """
        result = self.gateway.process_sensor_data("")
        self.assertIsNone(result)
        self.mock_maintenance_agent.send_engine_alert.assert_not_called()
        self.mock_customer_tracking_agent.send_location_update.assert_not_called()

    def test_full_pipeline_malformed_data_normalization_failure(self):
        """
        Test pipeline with data that cannot be normalized due to missing sensor_id.
        Should fail at normalization.
        """
        raw_data = "BOSCH|TS:1678886400|LAT:34.0522|LON:-118.2437|ET:85.5|OP:45.0|FL:75|ES:OK" # Missing SENSOR_ID
        
        with patch('project_name.src.normalization.datetime') as mock_dt:
            mock_dt.fromtimestamp.return_value = datetime(2023, 3, 15, 10, 40, 0, tzinfo=timezone.utc)
            mock_dt.now.return_value = datetime(2023, 3, 15, 10, 40, 0, tzinfo=timezone.utc)
            mock_dt.strptime = datetime.strptime # ensure strptime works as normal
            mock_dt.side_effect = lambda *args, **kw: datetime(*args, **kw) # Allow other datetime ops

            result = self.gateway.process_sensor_data(raw_data)
            self.assertIsNone(result)
            self.mock_maintenance_agent.send_engine_alert.assert_not_called()
            self.mock_customer_tracking_agent.send_location_update.assert_not_called()

    def test_full_pipeline_garmin_data(self):
        """
        Test with Garmin specific data format and ISO timestamp.
        """
        raw_data = "GARMIN|DEVICE_ID:truck_003|DATETIME:2023-03-15T11:00:00Z|GPS_LAT:35.0|GPS_LON:-120.0|ALT:150.0|ACCURACY:HIGH|RPM:2000|ENG_STAT:OK"
        expected_timestamp = datetime(2023, 3, 15, 11, 0, 0, tzinfo=timezone.utc)
        
        result = self.gateway.process_sensor_data(raw_data)

        self.assertIsNotNone(result)
        self.assertEqual(result.sensor_id, "truck_003")
        self.assertEqual(result.manufacturer, "GARMIN")
        self.assertEqual(result.timestamp, expected_timestamp)
        self.assertEqual(result.latitude, 35.0)
        self.assertEqual(result.longitude, -120.0)
        self.assertEqual(result.altitude, 150.0)
        self.assertEqual(result.engine_rpm, 2000)
        self.assertEqual(result.engine_status, "OK")

        self.mock_maintenance_agent.send_engine_alert.assert_not_called()
        self.mock_customer_tracking_agent.send_location_update.assert_called_once()
        args, _ = self.mock_customer_tracking_agent.send_location_update.call_args
        self.assertEqual(args[0]["latitude"], 35.0)

if __name__ == '__main__':
    unittest.main()
