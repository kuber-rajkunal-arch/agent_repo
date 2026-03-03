"""
Module for routing normalized sensor data to various agents.
Implements FR-GW-004, FR-GW-005, TR-GW-004, TR-GW-005.
"""

import logging
import json
import datetime
from typing import Dict, Any, Optional, Callable

from project_name.src.gateway_schemas import StandardSensorData, EngineAlertCode

logger = logging.getLogger(__name__)

class GatewayRouter:
    """
    Analyzes normalized sensor data and routes specific updates (e.g., engine alerts,
    location updates) to their designated external agents.
    """

    def __init__(self,
                 alert_detection_config: Optional[Dict[str, Any]] = None,
                 location_detection_config: Optional[Dict[str, Any]] = None,
                 maintenance_agent_config: Optional[Dict[str, Any]] = None,
                 customer_tracking_agent_config: Optional[Dict[str, Any]] = None):
        """
        Initializes the GatewayRouter with configurations for detection and agents.

        Args:
            alert_detection_config (Optional[Dict[str, Any]]): Rules for identifying engine alerts.
            location_detection_config (Optional[Dict[str, Any]]): Rules for identifying location updates.
            maintenance_agent_config (Optional[Dict[str, Any]]): Configuration for the maintenance agent (e.g., endpoint, format).
            customer_tracking_agent_config (Optional[Dict[str, Any]]): Configuration for the customer tracking agent.
        """
        self.alert_detection_config = alert_detection_config if alert_detection_config is not None else self._default_alert_detection_config()
        self.location_detection_config = location_detection_config if location_detection_config is not None else self._default_location_detection_config()
        self.maintenance_agent_config = maintenance_agent_config if maintenance_agent_config is not None else self._default_maintenance_agent_config()
        self.customer_tracking_agent_config = customer_tracking_agent_config if customer_tracking_agent_config is not None else self._default_customer_tracking_agent_config()
        logger.info("GatewayRouter initialized.")

        # In a real system, these would be HTTP client instances, MQTT clients etc.
        # Here, they are simulated callback functions.
        self._maintenance_agent_transmitter: Callable[[Dict[str, Any]], None] = self._simulate_transmission_maintenance
        self._customer_tracking_agent_transmitter: Callable[[Dict[str, Any]], None] = self._simulate_transmission_customer_tracking

    def _default_alert_detection_config(self) -> Dict[str, Any]:
        """Default rules for detecting engine alerts."""
        return {
            "critical_alert_codes": [
                EngineAlertCode.LOW_OIL_PRESSURE,
                EngineAlertCode.HIGH_ENGINE_TEMPERATURE,
                EngineAlertCode.CRITICAL_BATTERY
            ],
            "include_all_alerts": True # Whether to route all non-None engine_alert_code or only critical
        }

    def _default_location_detection_config(self) -> Dict[str, Any]:
        """Default rules for detecting location updates."""
        return {
            "require_movement": False, # For simplicity, any non-null GPS is an update
            "min_distance_meters": 5,  # Future: require actual movement, would need state
        }

    def _default_maintenance_agent_config(self) -> Dict[str, Any]:
        """Default configuration for the Maintenance Agent."""
        return {
            "endpoint": "http://mock-maintenance-agent.com/alerts",
            "format": "JSON",
            "required_fields": ["truckId", "alertCode", "timestamp", "sensorId", "severity"]
        }

    def _default_customer_tracking_agent_config(self) -> Dict[str, Any]:
        """Default configuration for the Customer Tracking Agent."""
        return {
            "endpoint": "http://mock-customer-tracking.com/location",
            "format": "JSON",
            "required_fields": ["truckId", "latitude", "longitude", "timestamp"]
        }

    def _check_engine_alert(self, data: StandardSensorData) -> Optional[Dict[str, Any]]:
        """
        Analyzes normalized sensor data for indicators of "Engine Alerts".

        Args:
            data (StandardSensorData): The normalized sensor data.

        Returns:
            Optional[Dict[str, Any]]: A dictionary of extracted alert details
                                      if an alert is detected, otherwise None.
        """
        if not data["is_engine_alert"] and not data.get("engine_alert_code"):
            return None

        alert_code = data["engine_alert_code"]
        if not alert_code: # Should be caught by is_engine_alert, but defensive
            return None
        
        # Apply specific alert filtering if required by config
        if not self.alert_detection_config["include_all_alerts"] and \
           alert_code not in self.alert_detection_config["critical_alert_codes"]:
            logger.debug(f"Non-critical engine alert '{alert_code}' for truck {data['truck_id']} ignored based on config.")
            return None

        alert_details = {
            "sensor_id": data["sensor_id"],
            "truck_id": data["truck_id"],
            "timestamp": data["timestamp_utc"],
            "alert_code": alert_code,
            "engine_temp_celsius": data["engine_temp_celsius"],
            "fuel_level_percent": data["fuel_level_percent"],
            "manufacturer": data["manufacturer"],
            "cleansing_flags": data["cleansing_flags"]
        }
        logger.debug(f"Detected engine alert '{alert_code}' for truck {data['truck_id']}.")
        return alert_details

    def _check_location_update(self, data: StandardSensorData) -> Optional[Dict[str, Any]]:
        """
        Analyzes normalized sensor data for indicators of "Location Updates".

        Args:
            data (StandardSensorData): The normalized sensor data.

        Returns:
            Optional[Dict[str, Any]]: A dictionary of extracted location details
                                      if an update is detected, otherwise None.
        """
        if not data["is_location_update"]:
            return None
        
        # For simplicity, any valid (non-noisy) location data is an update.
        # More complex logic could involve checking for significant movement
        # from the last known position (requires state management).
        
        location_details = {
            "sensor_id": data["sensor_id"],
            "truck_id": data["truck_id"],
            "timestamp": data["timestamp"],
            "latitude": data["latitude"],
            "longitude": data["longitude"],
            "manufacturer": data["manufacturer"],
            "cleansing_flags": data["cleansing_flags"]
        }
        logger.debug(f"Detected location update for truck {data['truck_id']} at ({data['latitude']},{data['longitude']}).")
        return location_details

    def _format_for_maintenance_agent(self, alert_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Formats the engine alert message according to the Maintenance Agent's requirements.

        Args:
            alert_data (Dict[str, Any]): Extracted alert details.

        Returns:
            Dict[str, Any]: Formatted message for the Maintenance Agent.
        """
        formatted_alert = {
            "truckId": alert_data["truck_id"],
            "alertCode": alert_data["alert_code"],
            "timestamp": alert_data["timestamp"].isoformat(), # ISO 8601 string
            "sensorId": alert_data["sensor_id"],
            "severity": "CRITICAL" if alert_data["alert_code"] in self.alert_detection_config["critical_alert_codes"] else "WARNING",
            "details": {
                "engineTempCelsius": alert_data["engine_temp_celsius"],
                "fuelLevelPercent": alert_data["fuel_level_percent"],
                "manufacturer": alert_data["manufacturer"],
                "cleansingFlags": alert_data["cleansing_flags"]
            }
        }
        # Ensure all required fields are present (optional, for robustness)
        for field in self.maintenance_agent_config["required_fields"]:
            if field not in formatted_alert and field not in formatted_alert.get("details", {}):
                logger.warning(f"Maintenance Agent format: Missing required field '{field}'. Payload: {formatted_alert}")
        return formatted_alert

    def _format_for_customer_tracking_agent(self, location_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Formats the location update message according to the Customer Tracking Agent's requirements.

        Args:
            location_data (Dict[str, Any]): Extracted location details.

        Returns:
            Dict[str, Any]: Formatted message for the Customer Tracking Agent.
        """
        formatted_location = {
            "truckId": location_data["truck_id"],
            "latitude": location_data["latitude"],
            "longitude": location_data["longitude"],
            "timestamp": location_data["timestamp"].isoformat(), # ISO 8601 string
            "sensorId": location_data["sensor_id"],
            "sourceManufacturer": location_data["manufacturer"],
            "cleansingFlags": location_data["cleansing_flags"]
        }
        # Ensure all required fields are present (optional, for robustness)
        for field in self.customer_tracking_agent_config["required_fields"]:
            if field not in formatted_location:
                logger.warning(f"Customer Tracking Agent format: Missing required field '{field}'. Payload: {formatted_location}")
        return formatted_location

    def _simulate_transmission_maintenance(self, payload: Dict[str, Any]) -> None:
        """Simulates sending data to the Maintenance Agent."""
        try:
            # In a real system, this would be an HTTP POST, MQTT publish, etc.
            # requests.post(self.maintenance_agent_config["endpoint"], json=payload)
            logger.info(f"Simulating sending Engine Alert to Maintenance Agent ({self.maintenance_agent_config['endpoint']}): {json.dumps(payload, indent=2)}")
        except Exception as e:
            logger.error(f"Failed to transmit alert to Maintenance Agent for truck {payload.get('truckId')}: {e}")
            # Real system would have retry logic, dead-letter queue, etc.

    def _simulate_transmission_customer_tracking(self, payload: Dict[str, Any]) -> None:
        """Simulates sending data to the Customer Tracking Agent."""
        try:
            # In a real system, this would be an HTTP POST, MQTT publish, etc.
            # requests.post(self.customer_tracking_agent_config["endpoint"], json=payload)
            logger.info(f"Simulating sending Location Update to Customer Tracking Agent ({self.customer_tracking_agent_config['endpoint']}): {json.dumps(payload, indent=2)}")
        except Exception as e:
            logger.error(f"Failed to transmit location update to Customer Tracking Agent for truck {payload.get('truckId')}: {e}")
            # Real system would have retry logic, dead-letter queue, etc.

    def route_data(self, normalized_data: StandardSensorData) -> None:
        """
        Routes the normalized sensor data based on its content.

        Args:
            normalized_data (StandardSensorData): The fully normalized sensor data.
        """
        logger.debug(f"Routing normalized data for truck {normalized_data['truck_id']}")

        # Attempt to route Engine Alerts
        alert_payload = self._check_engine_alert(normalized_data)
        if alert_payload:
            formatted_alert = self._format_for_maintenance_agent(alert_payload)
            self._maintenance_agent_transmitter(formatted_alert)

        # Attempt to route Location Updates
        location_payload = self._check_location_update(normalized_data)
        if location_payload:
            formatted_location = self._format_for_customer_tracking_agent(location_payload)
            self._customer_tracking_agent_transmitter(formatted_location)

