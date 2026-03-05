"""
Agent Interfaces and Mock Implementations for the IoT Sensor Data Gateway.

This module defines abstract interfaces for various external agents
(e.g., Maintenance Agent, Customer Tracking Agent) and provides
mock implementations for demonstration purposes.
"""

import logging
from abc import ABC, abstractmethod
from typing import Dict, Any

logger = logging.getLogger(__name__)

class AbstractMaintenanceAgent(ABC):
    """
    Abstract base class for Maintenance Agents.
    Defines the interface for routing engine alerts.
    """

    @abstractmethod
    def send_engine_alert(self, alert_data: Dict[str, Any]) -> bool:
        """
        Sends an engine alert to the Maintenance Agent.

        Args:
            alert_data: A dictionary containing formatted engine alert information.

        Returns:
            True if the alert was successfully sent, False otherwise.
        """
        pass

class MockMaintenanceAgent(AbstractMaintenanceAgent):
    """
    A mock implementation of the Maintenance Agent for testing and demonstration.
    Simply logs the received alert.
    """

    def __init__(self, endpoint: str = "mock_maintenance_endpoint"):
        self.endpoint = endpoint
        logger.info(f"MockMaintenanceAgent initialized for endpoint: {self.endpoint}")

    def send_engine_alert(self, alert_data: Dict[str, Any]) -> bool:
        """
        Simulates sending an engine alert by logging it.

        Args:
            alert_data: A dictionary containing formatted engine alert information.

        Returns:
            Always True in this mock implementation, simulating success.
        """
        logger.info(f"MockMaintenanceAgent: Sending Engine Alert to {self.endpoint}: {alert_data}")
        # In a real scenario, this would involve HTTP requests, message queue publishing, etc.
        return True


class AbstractCustomerTrackingAgent(ABC):
    """
    Abstract base class for Customer Tracking Agents.
    Defines the interface for routing location updates.
    """

    @abstractmethod
    def send_location_update(self, location_data: Dict[str, Any]) -> bool:
        """
        Sends a location update to the Customer Tracking Agent.

        Args:
            location_data: A dictionary containing formatted location update information.

        Returns:
            True if the update was successfully sent, False otherwise.
        """
        pass

class MockCustomerTrackingAgent(AbstractCustomerTrackingAgent):
    """
    A mock implementation of the Customer Tracking Agent for testing and demonstration.
    Simply logs the received location update.
    """

    def __init__(self, endpoint: str = "mock_customer_tracking_endpoint"):
        self.endpoint = endpoint
        logger.info(f"MockCustomerTrackingAgent initialized for endpoint: {self.endpoint}")

    def send_location_update(self, location_data: Dict[str, Any]) -> bool:
        """
        Simulates sending a location update by logging it.

        Args:
            location_data: A dictionary containing formatted location update information.

        Returns:
            Always True in this mock implementation, simulating success.
        """
        logger.info(f"MockCustomerTrackingAgent: Sending Location Update to {self.endpoint}: {location_data}")
        # In a real scenario, this would involve HTTP requests, message queue publishing, etc.
        return True
