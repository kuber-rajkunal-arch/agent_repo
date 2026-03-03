"""
Unit tests for the gateway_router module.
"""

import unittest
import datetime
from unittest.mock import patch, MagicMock

from project_name.src.gateway_router import GatewayRouter
from project_name.src.gateway_schemas import StandardSensorData, EngineAlertCode, CleansingFlag

class TestGatewayRouter(unittest.TestCase):

    def setUp(self):
        """Set up for test methods."""
        self.router = GatewayRouter()
        
        # Mock the transmission methods to capture payloads instead of sending
        self.mock_maintenance_transmitter = MagicMock()
        self.mock_customer_tracking_transmitter = MagicMock()
        self.router._maintenance_agent_transmitter = self.mock_maintenance_transmitter # type: ignore
        self.router._customer_tracking_agent_transmitter = self.mock_customer_tracking_transmitter # type: ignore

    def _create_standard_data(self, **kwargs) -> StandardSensorData:
        """Helper to create a StandardSensorData dict with defaults."""
        default_data: StandardSensorData = {
            "sensor_id": "TRUCK001-2023-10-27T10:00:00+00:00",
            "truck_id": "TRUCK001",
            "timestamp_utc": datetime.datetime(2023, 10, 27, 10, 0, 0, tzinfo=datetime.timezone.utc),
            "latitude": 40.7128,
            "longitude": -74.0060,
            "fuel_level_percent": 55.2,
            "engine_temp_celsius": 85.1,
            "engine_alert_code": None,
            "manufacturer": "BOSCH",
            "is_engine_alert": False,
            "is_location_update": True,
            "cleansing_flags": []
        }
        default_data.update(kwargs)
        return default_data

    def test_route_data_no_alerts_no_location_update(self):
        """Test routing with no alerts and no valid location update."""
        data = self._create_standard_data(is_engine_alert=False, is_location_update=False)
        self.router.route_data(data)
        self.mock_maintenance_transmitter.assert_not_called()
        self.mock_customer_tracking_transmitter.assert_not_called()

    def test_route_data_engine_alert_critical(self):
        """Test routing a critical engine alert."""
        data = self._create_standard_data(
            is_engine_alert=True,
            engine_alert_code=EngineAlertCode.LOW_OIL_PRESSURE,
            engine_temp_celsius=95.0,
            fuel_level_percent=30.0
        )
        self.router.route_data(data)
        self.mock_maintenance_transmitter.assert_called_once()
        
        # Validate the payload sent to maintenance agent
        payload = self.mock_maintenance_transmitter.call_args[0][0]
        self.assertEqual(payload["truckId"], "TRUCK001")
        self.assertEqual(payload["alertCode"], EngineAlertCode.LOW_OIL_PRESSURE)
        self.assertEqual(payload["severity"], "CRITICAL")
        self.assertEqual(payload["details"]["engineTempCelsius"], 95.0)
        self.assertEqual(payload["details"]["fuelLevelPercent"], 30.0)
        self.mock_customer_tracking_transmitter.assert_called_once() # Location update also happens

    def test_route_data_engine_alert_non_critical_default_config(self):
        """
        Test routing a non-critical engine alert with default config (all alerts routed).
        Default config has "include_all_alerts": True.
        """
        data = self._create_standard_data(
            is_engine_alert=True,
            engine_alert_code=EngineAlertCode.MAINTENANCE_REQUIRED # Not in critical_alert_codes
        )
        self.router.route_data(data)
        self.mock_maintenance_transmitter.assert_called_once()
        payload = self.mock_maintenance_transmitter.call_args[0][0]
        self.assertEqual(payload["alertCode"], EngineAlertCode.MAINTENANCE_REQUIRED)
        self.assertEqual(payload["severity"], "WARNING") # Not critical
        self.mock_customer_tracking_transmitter.assert_called_once()

    def test_route_data_engine_alert_non_critical_filtered_config(self):
        """Test routing a non-critical engine alert with a config that filters them out."""
        router = GatewayRouter(alert_detection_config={"critical_alert_codes": [EngineAlertCode.HIGH_ENGINE_TEMPERATURE], "include_all_alerts": False})
        router._maintenance_agent_transmitter = self.mock_maintenance_transmitter # type: ignore
        router._customer_tracking_agent_transmitter = self.mock_customer_tracking_transmitter # type: ignore

        data = self._create_standard_data(
            is_engine_alert=True,
            engine_alert_code=EngineAlertCode.LOW_OIL_PRESSURE # Is critical, but not in THIS custom config's critical_alert_codes
        )
        router.route_data(data)
        self.mock_maintenance_transmitter.assert_not_called() # Should be filtered out
        self.mock_customer_tracking_transmitter.assert_called_once() # Location update still routed

    def test_route_data_location_update(self):
        """Test routing a location update."""
        data = self._create_standard_data(
            is_engine_alert=False,
            latitude=34.123,
            longitude=-118.456
        )
        self.router.route_data(data)
        self.mock_customer_tracking_transmitter.assert_called_once()
        
        # Validate the payload sent to customer tracking agent
        payload = self.mock_customer_tracking_transmitter.call_args[0][0]
        self.assertEqual(payload["truckId"], "TRUCK001")
        self.assertAlmostEqual(payload["latitude"], 34.123)
        self.assertAlmostEqual(payload["longitude"], -118.456)
        self.mock_maintenance_transmitter.assert_not_called()

    def test_route_data_both_alert_and_location(self):
        """Test routing both an alert and a location update."""
        data = self._create_standard_data(
            is_engine_alert=True,
            engine_alert_code=EngineAlertCode.HIGH_ENGINE_TEMPERATURE,
            latitude=35.0,
            longitude=-90.0
        )
        self.router.route_data(data)
        self.mock_maintenance_transmitter.assert_called_once()
        self.mock_customer_tracking_transmitter.assert_called_once()

    def test_route_data_location_with_cleansing_flags(self):
        """Test routing location data that had cleansing flags."""
        data = self._create_standard_data(
            cleansing_flags=[CleansingFlag.GPS_ZEROED],
            latitude=0.0,
            longitude=0.0
        )
        self.router.route_data(data)
        self.mock_customer_tracking_transmitter.assert_called_once()
        payload = self.mock_customer_tracking_transmitter.call_args[0][0]
        self.assertIn(CleansingFlag.GPS_ZEROED, payload["cleansingFlags"])

    @patch('project_name.src.gateway_router.logger')
    def test_transmission_failure_logging_maintenance(self, mock_logger):
        """Test logging for transmission failures to maintenance agent."""
        self.mock_maintenance_transmitter.side_effect = Exception("Network error")
        data = self._create_standard_data(is_engine_alert=True, engine_alert_code=EngineAlertCode.LOW_OIL_PRESSURE)
        self.router.route_data(data)
        mock_logger.error.assert_called_once()
        self.assertIn("Failed to transmit alert to Maintenance Agent", mock_logger.error.call_args[0][0])
        self.mock_customer_tracking_transmitter.assert_called_once() # Location should still try to send

    @patch('project_name.src.gateway_router.logger')
    def test_transmission_failure_logging_customer_tracking(self, mock_logger):
        """Test logging for transmission failures to customer tracking agent."""
        self.mock_customer_tracking_transmitter.side_effect = Exception("API rate limit")
        data = self._create_standard_data(is_engine_alert=False, is_location_update=True)
        self.router.route_data(data)
        mock_logger.error.assert_called_once()
        self.assertIn("Failed to transmit location update to Customer Tracking Agent", mock_logger.error.call_args[0][0])
        self.mock_maintenance_transmitter.assert_not_called()


if __name__ == '__main__':
    unittest.main()

