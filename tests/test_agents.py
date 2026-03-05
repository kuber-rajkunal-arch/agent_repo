"""
Unit tests for the agents module.
"""

import unittest
import logging
from unittest.mock import patch, MagicMock

from project_name.src.agents import MockMaintenanceAgent, MockCustomerTrackingAgent, \
    AbstractMaintenanceAgent, AbstractCustomerTrackingAgent

class TestAgents(unittest.TestCase):

    def setUp(self):
        # Suppress logging during tests to keep console clean, unless needed for debugging
        logging.disable(logging.CRITICAL)

    def tearDown(self):
        logging.disable(logging.NOTSET) # Re-enable logging after tests

    def test_mock_maintenance_agent_send_alert(self):
        """
        Test that MockMaintenanceAgent correctly simulates sending an alert
        and returns True.
        """
        agent = MockMaintenanceAgent("test_maintenance_endpoint")
        alert_data = {"sensor_id": "test_001", "alert_type": "HIGH_TEMP"}

        with self.assertLogs('project_name.src.agents', level='INFO') as cm:
            result = agent.send_engine_alert(alert_data)
            self.assertTrue(result)
            self.assertIn(f"MockMaintenanceAgent: Sending Engine Alert to {agent.endpoint}: {alert_data}", cm.output[0])

    def test_mock_customer_tracking_agent_send_update(self):
        """
        Test that MockCustomerTrackingAgent correctly simulates sending a location
        update and returns True.
        """
        agent = MockCustomerTrackingAgent("test_tracking_endpoint")
        location_data = {"sensor_id": "test_001", "latitude": 10.0, "longitude": 20.0}

        with self.assertLogs('project_name.src.agents', level='INFO') as cm:
            result = agent.send_location_update(location_data)
            self.assertTrue(result)
            self.assertIn(f"MockCustomerTrackingAgent: Sending Location Update to {agent.endpoint}: {location_data}", cm.output[0])

    def test_abstract_maintenance_agent_interface(self):
        """
        Test that AbstractMaintenanceAgent cannot be instantiated directly
        and requires implementation of its abstract methods.
        """
        with self.assertRaises(TypeError):
            AbstractMaintenanceAgent() # Should raise TypeError because it's abstract

        class ConcreteMaintenanceAgent(AbstractMaintenanceAgent):
            def send_engine_alert(self, alert_data):
                return True
        
        # Should be instantiable
        agent = ConcreteMaintenanceAgent()
        self.assertIsInstance(agent, AbstractMaintenanceAgent)
        self.assertTrue(agent.send_engine_alert({"test": "data"}))


    def test_abstract_customer_tracking_agent_interface(self):
        """
        Test that AbstractCustomerTrackingAgent cannot be instantiated directly
        and requires implementation of its abstract methods.
        """
        with self.assertRaises(TypeError):
            AbstractCustomerTrackingAgent() # Should raise TypeError because it's abstract

        class ConcreteCustomerTrackingAgent(AbstractCustomerTrackingAgent):
            def send_location_update(self, location_data):
                return True
        
        # Should be instantiable
        agent = ConcreteCustomerTrackingAgent()
        self.assertIsInstance(agent, AbstractCustomerTrackingAgent)
        self.assertTrue(agent.send_location_update({"test": "data"}))


if __name__ == '__main__':
    unittest.main()
