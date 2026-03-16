import unittest
from datetime import datetime
from unittest.mock import patch, MagicMock

from src.data_routing import (
    detect_engine_alert,
    format_engine_alert,
    transmit_engine_alert,
    detect_location_update,
    format_location_update,
    transmit_location_update,
    route_normalized_data,
    AgentCommunicationError
)
from src.models import StandardSensorData, EngineAlert, LocationUpdate
from src.config import (
    ENGINE_ALERT_CRITERIA, MAINTENANCE_AGENT_FORMAT,
    CUSTOMER_TRACKING_AGENT_FORMAT, MOCK_MAINTENANCE_AGENT_ENDPOINT,
    MOCK_CUSTOMER_TRACKING_AGENT_ENDPOINT
)
from src.logger import app_logger

class TestDataRouting(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        # Suppress logging output during tests for cleaner console, but keep it for debugging if needed
        app_logger.setLevel(100) # CRITICAL + 1 to effectively disable

    @classmethod
    def tearDownClass(cls):
        app_logger.setLevel(10) # Reset to DEBUG or INFO after tests

    def setUp(self):
        self.mock_timestamp = datetime(2023, 10, 27, 10, 0, 0)
        self.mock_standard_data_normal = StandardSensorData(
            device_id="TRUCK_001",
            timestamp=self.mock_timestamp,
            latitude=34.0522,
            longitude=-118.2437,
            fuel_level=80,
            engine_temperature=190,
            engine_rpm=1500
        )
        self.mock_standard_data_high_temp = StandardSensorData(
            device_id="TRUCK_002",
            timestamp=self.mock_timestamp,
            latitude=34.0523,
            longitude=-118.2438,
            fuel_level=70,
            engine_temperature=230, # Above threshold
            engine_rpm=1600
        )
        self.mock_standard_data_low_fuel = StandardSensorData(
            device_id="TRUCK_003",
            timestamp=self.mock_timestamp,
            latitude=34.0524,
            longitude=-118.2439,
            fuel_level=5, # Below threshold
            engine_temperature=180,
            engine_rpm=1400
        )
        self.mock_standard_data_no_location = StandardSensorData(
            device_id="TRUCK_004",
            timestamp=self.mock_timestamp,
            fuel_level=50,
            engine_temperature=200,
            engine_rpm=1500
        )

    # --- TR-IOT-003: Engine Alert Detection and Routing ---

    def test_detect_engine_alert_no_alert(self):
        """
        Test TR-IOT-003, Stage 1: No engine alert detected for normal data.
        """
        alert = detect_engine_alert(self.mock_standard_data_normal)
        self.assertIsNone(alert)

    def test_detect_engine_alert_high_temperature(self):
        """
        Test TR-IOT-003, Stage 1: Engine alert detected for high temperature.
        """
        alert = detect_engine_alert(self.mock_standard_data_high_temp)
        self.assertIsInstance(alert, EngineAlert)
        self.assertEqual(alert.device_id, "TRUCK_002")
        self.assertEqual(alert.alert_type, "engine_temperature_high")
        self.assertEqual(alert.alert_value, 230)
        self.assertEqual(alert.threshold, ENGINE_ALERT_CRITERIA["engine_temperature_high"]["threshold"])
        self.assertEqual(alert.current_location, {"latitude": 34.0523, "longitude": -118.2438})

    def test_detect_engine_alert_low_fuel(self):
        """
        Test TR-IOT-003, Stage 1: Engine alert detected for low fuel.
        """
        alert = detect_engine_alert(self.mock_standard_data_low_fuel)
        self.assertIsInstance(alert, EngineAlert)
        self.assertEqual(alert.device_id, "TRUCK_003")
        self.assertEqual(alert.alert_type, "fuel_level_low")
        self.assertEqual(alert.alert_value, 5)
        self.assertEqual(alert.threshold, ENGINE_ALERT_CRITERIA["fuel_level_low"]["threshold"])

    def test_format_engine_alert(self):
        """
        Test TR-IOT-003, Stage 3: Formatting engine alert for Maintenance Agent.
        """
        alert = EngineAlert(
            device_id="TRUCK_002",
            timestamp=self.mock_timestamp,
            alert_type="engine_temperature_high",
            alert_value=230,
            threshold=220,
            current_location={"latitude": 34.0523, "longitude": -118.2438}
        )
        formatted_alert = format_engine_alert(alert)
        expected_json = {
            "device_id": "TRUCK_002",
            "timestamp": self.mock_timestamp.isoformat(),
            "alert_type": "engine_temperature_high",
            "alert_value": 230,
            "current_location": {"latitude": 34.0523, "longitude": -118.2438}
        }
        self.assertIsInstance(formatted_alert, str)
        self.assertIn('"device_id": "TRUCK_002"', formatted_alert)
        self.assertIn('"alert_type": "engine_temperature_high"', formatted_alert)
        self.assertIn('"alert_value": 230', formatted_alert)
        self.assertIn('"current_location": {"latitude": 34.0523, "longitude": -118.2438}', formatted_alert)

    @patch('src.data_routing.app_logger.info')
    @patch('src.data_routing.app_logger.error')
    def test_transmit_engine_alert_success(self, mock_error, mock_info):
        """
        Test TR-IOT-003, Stage 4: Successful transmission of engine alert.
        """
        formatted_alert = '{"device_id": "TRUCK_002", "alert_type": "engine_temperature_high"}'
        success = transmit_engine_alert(formatted_alert)
        self.assertTrue(success)
        mock_info.assert_any_call(f"TR-IOT-003: Transmitting Engine Alert to Maintenance Agent (Endpoint: {MOCK_MAINTENANCE_AGENT_ENDPOINT}).")
        mock_info.assert_any_call("TR-IOT-003: Engine Alert transmitted successfully.")
        mock_error.assert_not_called()

    # --- TR-IOT-004: Location Update Detection and Routing ---

    def test_detect_location_update_valid(self):
        """
        Test TR-IOT-004, Stage 1: Location update detected for valid data.
        """
        update = detect_location_update(self.mock_standard_data_normal)
        self.assertIsInstance(update, LocationUpdate)
        self.assertEqual(update.device_id, "TRUCK_001")
        self.assertEqual(update.latitude, 34.0522)
        self.assertEqual(update.longitude, -118.2437)

    def test_detect_location_update_no_location_data(self):
        """
        Test TR-IOT-004, Stage 1: No location update when data is missing.
        """
        update = detect_location_update(self.mock_standard_data_no_location)
        self.assertIsNone(update)

    def test_detect_location_update_invalid_coordinates(self):
        """
        Test TR-IOT-004, Stage 1: No location update for invalid coordinates.
        """
        invalid_data = StandardSensorData(
            device_id="TRUCK_005",
            timestamp=self.mock_timestamp,
            latitude=999.0, # Invalid
            longitude=-118.2437,
            fuel_level=80,
            engine_temperature=190,
            engine_rpm=1500
        )
        update = detect_location_update(invalid_data)
        self.assertIsNone(update)

    def test_format_location_update(self):
        """
        Test TR-IOT-004, Stage 3: Formatting location update for Customer Tracking Agent.
        """
        update = LocationUpdate(
            device_id="TRUCK_001",
            timestamp=self.mock_timestamp,
            latitude=34.0522,
            longitude=-118.2437
        )
        formatted_update = format_location_update(update)
        expected_json = {
            "device_id": "TRUCK_001",
            "timestamp": self.mock_timestamp.isoformat(),
            "latitude": 34.0522,
            "longitude": -118.2437
        }
        self.assertIsInstance(formatted_update, str)
        self.assertIn('"device_id": "TRUCK_001"', formatted_update)
        self.assertIn('"latitude": 34.0522', formatted_update)
        self.assertIn('"longitude": -118.2437', formatted_update)

    @patch('src.data_routing.app_logger.info')
    @patch('src.data_routing.app_logger.error')
    def test_transmit_location_update_success(self, mock_error, mock_info):
        """
        Test TR-IOT-004, Stage 4: Successful transmission of location update.
        """
        formatted_update = '{"device_id": "TRUCK_001", "latitude": 34.0522}'
        success = transmit_location_update(formatted_update)
        self.assertTrue(success)
        mock_info.assert_any_call(f"TR-IOT-004: Transmitting Location Update to Customer Tracking Agent (Endpoint: {MOCK_CUSTOMER_TRACKING_AGENT_ENDPOINT}).")
        mock_info.assert_any_call("TR-IOT-004: Location Update transmitted successfully.")
        mock_error.assert_not_called()

    # --- Combined Routing ---

    @patch('src.data_routing.transmit_engine_alert', return_value=True)
    @patch('src.data_routing.transmit_location_update', return_value=True)
    def test_route_normalized_data_alert_and_location(self, mock_transmit_location, mock_transmit_alert):
        """
        Test combined routing for data triggering both an alert and a location update.
        """
        results = route_normalized_data(self.mock_standard_data_high_temp)
        self.assertTrue(results["engine_alert_routed"])
        self.assertTrue(results["location_update_routed"])
        mock_transmit_alert.assert_called_once()
        mock_transmit_location.assert_called_once()

    @patch('src.data_routing.transmit_engine_alert', return_value=False) # Simulate failure
    @patch('src.data_routing.transmit_location_update', return_value=True)
    def test_route_normalized_data_alert_failure_location_success(self, mock_transmit_location, mock_transmit_alert):
        """
        Test combined routing where alert transmission fails but location succeeds.
        """
        results = route_normalized_data(self.mock_standard_data_high_temp)
        self.assertFalse(results["engine_alert_routed"])
        self.assertTrue(results["location_update_routed"])
        mock_transmit_alert.assert_called_once()
        mock_transmit_location.assert_called_once()

    @patch('src.data_routing.transmit_engine_alert')
    @patch('src.data_routing.transmit_location_update')
    def test_route_normalized_data_no_alert_only_location(self, mock_transmit_location, mock_transmit_alert):
        """
        Test combined routing for data with no alerts, only a location update.
        """
        results = route_normalized_data(self.mock_standard_data_normal)
        self.assertFalse(results["engine_alert_routed"])
        self.assertTrue(results["location_update_routed"])
        mock_transmit_alert.assert_not_called()
        mock_transmit_location.assert_called_once()

    @patch('src.data_routing.transmit_engine_alert')
    @patch('src.data_routing.transmit_location_update')
    def test_route_normalized_data_no_location_no_alert(self, mock_transmit_location, mock_transmit_alert):
        """
        Test combined routing for data with no location and no alerts.
        """
        results = route_normalized_data(self.mock_standard_data_no_location)
        self.assertFalse(results["engine_alert_routed"])
        self.assertFalse(results["location_update_routed"])
        mock_transmit_alert.assert_not_called()
        mock_transmit_location.assert_not_called()

if __name__ == '__main__':
    unittest.main()
