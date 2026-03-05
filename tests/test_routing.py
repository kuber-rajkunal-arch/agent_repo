"""
Unit tests for the routing module.
"""

import unittest
import logging
from datetime import datetime, timezone
from unittest.mock import MagicMock

from project_name.src.routing import MaintenanceAlertRouter, CustomerTrackingRouter
from project_name.src.data_models import StandardSensorData
from project_name.src.config import AppConfig
from project_name.src.agents import AbstractMaintenanceAgent, AbstractCustomerTrackingAgent

class TestRouting(unittest.TestCase):

    def setUp(self):
        # Mock agents for testing routing logic without actual sending
        self.mock_maintenance_agent = MagicMock(spec=AbstractMaintenanceAgent)
        self.mock_customer_tracking_agent = MagicMock(spec=AbstractCustomerTrackingAgent)

        self.maintenance_router = MaintenanceAlertRouter(self.mock_maintenance_agent)
        self.customer_router = CustomerTrackingRouter(self.mock_customer_tracking_agent)

        self.test_timestamp = datetime(2023, 3, 15, 10, 30, 0, tzinfo=timezone.utc)

        # Suppress logging during tests to keep console clean
        logging.disable(logging.CRITICAL)

    def tearDown(self):
        logging.disable(logging.NOTSET) # Re-enable logging after tests

    # --- MaintenanceAlertRouter Tests (FR-GW-004) ---

    def test_maintenance_router_engine_temp_alert(self):
        """
        Test that an engine alert is triggered and sent for high temperature.
        """
        data = StandardSensorData(
            sensor_id="truck_001",
            timestamp=self.test_timestamp,
            manufacturer="BOSCH",
            engine_temp_celsius=AppConfig.ENGINE_ALERT_RULES["engine_temp_threshold"] + 10, # Above threshold
            oil_pressure_psi=45.0,
            engine_status="OK",
            latitude=34.0, longitude=-118.0
        )
        self.mock_maintenance_agent.send_engine_alert.return_value = True

        result = self.maintenance_router.route_engine_alert(data)
        self.assertTrue(result)
        self.mock_maintenance_agent.send_engine_alert.assert_called_once()
        alert_payload = self.mock_maintenance_agent.send_engine_alert.call_args[0][0]
        self.assertEqual(alert_payload["sensor_id"], "truck_001")
        self.assertIn("Engine_Malfunction", alert_payload["alert_type"])
        self.assertEqual(alert_payload["details"]["engine_temp_celsius"], data.engine_temp_celsius)

    def test_maintenance_router_oil_pressure_alert(self):
        """
        Test that an engine alert is triggered and sent for low oil pressure.
        """
        data = StandardSensorData(
            sensor_id="truck_002",
            timestamp=self.test_timestamp,
            manufacturer="BOSCH",
            engine_temp_celsius=80.0,
            oil_pressure_psi=AppConfig.ENGINE_ALERT_RULES["oil_pressure_min_psi"] - 5, # Below threshold
            engine_status="OK",
            latitude=34.0, longitude=-118.0
        )
        self.mock_maintenance_agent.send_engine_alert.return_value = True

        result = self.maintenance_router.route_engine_alert(data)
        self.assertTrue(result)
        self.mock_maintenance_agent.send_engine_alert.assert_called_once()
        alert_payload = self.mock_maintenance_agent.send_engine_alert.call_args[0][0]
        self.assertEqual(alert_payload["sensor_id"], "truck_002")
        self.assertEqual(alert_payload["details"]["oil_pressure_psi"], data.oil_pressure_psi)

    def test_maintenance_router_engine_status_alert(self):
        """
        Test that an engine alert is triggered and sent for alert status.
        """
        data = StandardSensorData(
            sensor_id="truck_003",
            timestamp=self.test_timestamp,
            manufacturer="GARMIN",
            engine_temp_celsius=80.0,
            oil_pressure_psi=40.0,
            engine_status="ALERT", # Matches keyword
            latitude=34.0, longitude=-118.0
        )
        self.mock_maintenance_agent.send_engine_alert.return_value = True

        result = self.maintenance_router.route_engine_alert(data)
        self.assertTrue(result)
        self.mock_maintenance_agent.send_engine_alert.assert_called_once()
        alert_payload = self.mock_maintenance_agent.send_engine_alert.call_args[0][0]
        self.assertEqual(alert_payload["sensor_id"], "truck_003")
        self.assertEqual(alert_payload["details"]["engine_status"], "ALERT")

    def test_maintenance_router_no_alert(self):
        """
        Test that no alert is sent when conditions are normal.
        """
        data = StandardSensorData(
            sensor_id="truck_004",
            timestamp=self.test_timestamp,
            manufacturer="BOSCH",
            engine_temp_celsius=AppConfig.ENGINE_ALERT_RULES["engine_temp_threshold"] - 10,
            oil_pressure_psi=AppConfig.ENGINE_ALERT_RULES["oil_pressure_min_psi"] + 10,
            engine_status="OK",
            latitude=34.0, longitude=-118.0
        )
        self.mock_maintenance_agent.send_engine_alert.return_value = True

        result = self.maintenance_router.route_engine_alert(data)
        self.assertFalse(result)
        self.mock_maintenance_agent.send_engine_alert.assert_not_called()

    def test_maintenance_router_agent_send_failure(self):
        """
        Test handling of a failure to send alert by the agent.
        """
        data = StandardSensorData(
            sensor_id="truck_005",
            timestamp=self.test_timestamp,
            manufacturer="BOSCH",
            engine_temp_celsius=AppConfig.ENGINE_ALERT_RULES["engine_temp_threshold"] + 1,
            latitude=34.0, longitude=-118.0
        )
        self.mock_maintenance_agent.send_engine_alert.return_value = False # Simulate failure

        result = self.maintenance_router.route_engine_alert(data)
        self.assertFalse(result)
        self.mock_maintenance_agent.send_engine_alert.assert_called_once()

    # --- CustomerTrackingRouter Tests (FR-GW-005) ---

    def test_customer_router_location_update_sent(self):
        """
        Test that a location update is sent when valid coordinates are present.
        """
        data = StandardSensorData(
            sensor_id="truck_006",
            timestamp=self.test_timestamp,
            manufacturer="BOSCH",
            latitude=34.123,
            longitude=-118.456,
            altitude=50.0,
            location_accuracy="HIGH"
        )
        self.mock_customer_tracking_agent.send_location_update.return_value = True

        result = self.customer_router.route_location_update(data)
        self.assertTrue(result)
        self.mock_customer_tracking_agent.send_location_update.assert_called_once()
        location_payload = self.mock_customer_tracking_agent.send_location_update.call_args[0][0]
        self.assertEqual(location_payload["sensor_id"], "truck_006")
        self.assertEqual(location_payload["latitude"], 34.123)
        self.assertEqual(location_payload["longitude"], -118.456)
        self.assertEqual(location_payload["altitude"], 50.0)
        self.assertEqual(location_payload["location_accuracy"], "HIGH")

    def test_customer_router_no_location_data(self):
        """
        Test that no location update is sent when latitude/longitude are missing.
        """
        data = StandardSensorData(
            sensor_id="truck_007",
            timestamp=self.test_timestamp,
            manufacturer="BOSCH"
            # No latitude or longitude
        )
        self.mock_customer_tracking_agent.send_location_update.return_value = True

        result = self.customer_router.route_location_update(data)
        self.assertFalse(result)
        self.mock_customer_tracking_agent.send_location_update.assert_not_called()

    def test_customer_router_agent_send_failure(self):
        """
        Test handling of a failure to send location update by the agent.
        """
        data = StandardSensorData(
            sensor_id="truck_008",
            timestamp=self.test_timestamp,
            manufacturer="BOSCH",
            latitude=34.123,
            longitude=-118.456
        )
        self.mock_customer_tracking_agent.send_location_update.return_value = False # Simulate failure

        result = self.customer_router.route_location_update(data)
        self.assertFalse(result)
        self.mock_customer_tracking_agent.send_location_update.assert_called_once()

    def test_customer_router_only_one_coordinate(self):
        """
        Test that no location update is sent if only one coordinate is present.
        """
        data_lat_only = StandardSensorData(
            sensor_id="truck_009",
            timestamp=self.test_timestamp,
            manufacturer="BOSCH",
            latitude=34.123
        )
        data_lon_only = StandardSensorData(
            sensor_id="truck_010",
            timestamp=self.test_timestamp,
            manufacturer="BOSCH",
            longitude=-118.456
        )

        self.assertFalse(self.customer_router.route_location_update(data_lat_only))
        self.assertFalse(self.customer_router.route_location_update(data_lon_only))
        self.mock_customer_tracking_agent.send_location_update.assert_not_called()


if __name__ == '__main__':
    unittest.main()
