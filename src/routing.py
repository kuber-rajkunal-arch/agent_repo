"""
Routing module for the IoT Sensor Data Gateway.

This module handles routing of specific types of normalized sensor data
to designated external agents, as per FR-GW-004 and FR-GW-005.
"""

import logging
from typing import Dict, Any, Optional

from project_name.src.config import AppConfig
from project_name.src.data_models import StandardSensorData
from project_name.src.agents import AbstractMaintenanceAgent, AbstractCustomerTrackingAgent

logger = logging.getLogger(__name__)

class MaintenanceAlertRouter:
    """
    Identifies 'Engine Alerts' from normalized sensor data and routes them
    to the designated Maintenance Agent. (FR-GW-004)
    """

    def __init__(self, maintenance_agent: AbstractMaintenanceAgent):
        """
        Initializes the MaintenanceAlertRouter.

        Args:
            maintenance_agent: An instance of an AbstractMaintenanceAgent
                               implementation for sending alerts.
        """
        self.maintenance_agent = maintenance_agent
        self.engine_alert_rules = AppConfig.ENGINE_ALERT_RULES
        logger.info("MaintenanceAlertRouter initialized.")

    def _is_engine_alert(self, data: StandardSensorData) -> bool:
        """
        Checks if the normalized sensor data indicates an "Engine Alert".
        """
        # Rule 1: Engine temperature exceeds threshold
        if data.engine_temp_celsius is not None and \
           data.engine_temp_celsius > self.engine_alert_rules["engine_temp_threshold"]:
            logger.debug(f"Engine temp alert: {data.engine_temp_celsius}°C > "
                         f"{self.engine_alert_rules['engine_temp_threshold']}°C")
            return True

        # Rule 2: Oil pressure is below minimum threshold
        if data.oil_pressure_psi is not None and \
           data.oil_pressure_psi < self.engine_alert_rules["oil_pressure_min_psi"]:
            logger.debug(f"Oil pressure alert: {data.oil_pressure_psi} psi < "
                         f"{self.engine_alert_rules['oil_pressure_min_psi']} psi")
            return True

        # Rule 3: Engine status indicates an alert condition
        if data.engine_status and \
           data.engine_status.upper() in [s.upper() for s in self.engine_alert_rules["engine_status_keywords"]]:
            logger.debug(f"Engine status alert: {data.engine_status}")
            return True

        return False

    def route_engine_alert(self, normalized_data: StandardSensorData) -> bool:
        """
        Monitors normalized sensor data for engine alerts and routes them.

        Args:
            normalized_data: A StandardSensorData object.

        Returns:
            True if an alert was detected and sent, False otherwise.
        """
        if self._is_engine_alert(normalized_data):
            logger.info(f"Engine Alert detected for sensor_id: {normalized_data.sensor_id}")

            # Extract relevant details
            alert_details = {
                "sensor_id": normalized_data.sensor_id,
                "timestamp": normalized_data.timestamp.isoformat(),
                "manufacturer": normalized_data.manufacturer,
                "alert_type": "Engine_Malfunction", # Generic type
                "details": {
                    "engine_temp_celsius": normalized_data.engine_temp_celsius,
                    "oil_pressure_psi": normalized_data.oil_pressure_psi,
                    "fuel_level_percent": normalized_data.fuel_level_percent,
                    "engine_rpm": normalized_data.engine_rpm,
                    "engine_status": normalized_data.engine_status,
                    "current_location": {
                        "latitude": normalized_data.latitude,
                        "longitude": normalized_data.longitude
                    }
                }
            }
            # Remove None values for cleaner output
            alert_details["details"] = {k: v for k, v in alert_details["details"].items() if v is not None}
            alert_details["details"]["current_location"] = {
                k: v for k, v in alert_details["details"]["current_location"].items() if v is not None
            }
            if not alert_details["details"]["current_location"]:
                del alert_details["details"]["current_location"]

            # Send the formatted alert message
            if self.maintenance_agent.send_engine_alert(alert_details):
                logger.debug(f"Engine alert for {normalized_data.sensor_id} sent to Maintenance Agent.")
                return True
            else:
                logger.error(f"Failed to send engine alert for {normalized_data.sensor_id} to Maintenance Agent.")
                return False
        else:
            logger.debug(f"No Engine Alert detected for sensor_id: {normalized_data.sensor_id}")
            return False


class CustomerTrackingRouter:
    """
    Identifies 'Location Updates' from normalized sensor data and routes them
    to the designated Customer Tracking Agent. (FR-GW-005)
    """

    def __init__(self, customer_tracking_agent: AbstractCustomerTrackingAgent):
        """
        Initializes the CustomerTrackingRouter.

        Args:
            customer_tracking_agent: An instance of an AbstractCustomerTrackingAgent
                                     implementation for sending location updates.
        """
        self.customer_tracking_agent = customer_tracking_agent
        logger.info("CustomerTrackingRouter initialized.")

    def _is_location_update_relevant(self, data: StandardSensorData) -> bool:
        """
        Checks if the normalized sensor data contains valid location information.
        """
        return data.latitude is not None and data.longitude is not None

    def route_location_update(self, normalized_data: StandardSensorData) -> bool:
        """
        Monitors normalized sensor data for location updates and routes them.

        Args:
            normalized_data: A StandardSensorData object.

        Returns:
            True if a relevant location update was detected and sent, False otherwise.
        """
        if self._is_location_update_relevant(normalized_data):
            logger.info(f"Location Update detected for sensor_id: {normalized_data.sensor_id}")

            # Extract relevant location details
            location_details = {
                "sensor_id": normalized_data.sensor_id,
                "timestamp": normalized_data.timestamp.isoformat(),
                "latitude": normalized_data.latitude,
                "longitude": normalized_data.longitude,
                "altitude": normalized_data.altitude,
                "location_accuracy": normalized_data.location_accuracy,
                "manufacturer": normalized_data.manufacturer
            }
            # Remove None values for cleaner output
            location_details = {k: v for k, v in location_details.items() if v is not None}

            # Send the formatted location update message
            if self.customer_tracking_agent.send_location_update(location_details):
                logger.debug(f"Location update for {normalized_data.sensor_id} sent to Customer Tracking Agent.")
                return True
            else:
                logger.error(f"Failed to send location update for {normalized_data.sensor_id} to Customer Tracking Agent.")
                return False
        else:
            logger.debug(f"No relevant Location Update data for sensor_id: {normalized_data.sensor_id}")
            return False
