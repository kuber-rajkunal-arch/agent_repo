"""
Module for handling raw IoT sensor data ingestion.
Corresponds to TR-IOT-001: Receive raw text data from IoT sensors.
"""

from datetime import datetime
from typing import Tuple

from src.models import RawSensorData
from src.logger import app_logger

def receive_raw_sensor_data(raw_text_data: str, source_identifier: str = "unknown") -> RawSensorData:
    """
    TR-IOT-001: Implements the mechanism to receive raw text data from IoT sensors.

    This function simulates the reception of raw data. In a real-time system,
    this would typically involve listening to a message queue (e.g., Kafka, MQTT),
    an HTTP endpoint, or a direct socket connection.

    The system acknowledges receipt by creating a RawSensorData object with a
    timestamp of reception.

    Args:
        raw_text_data (str): The raw text string received from an IoT sensor.
        source_identifier (str, optional): An identifier for the source of the data
                                           (e.g., gateway ID, IP address). Defaults to "unknown".

    Returns:
        RawSensorData: An object representing the acknowledged raw data, including
                       the original data and its reception timestamp.
    """
    received_timestamp = datetime.utcnow()
    acknowledged_data = RawSensorData(
        data=raw_text_data,
        received_timestamp=received_timestamp,
        source_identifier=source_identifier
    )

    app_logger.info(
        f"TR-IOT-001: Received and acknowledged raw data from '{source_identifier}': "
        f"'{raw_text_data[:100]}...' (at {received_timestamp.isoformat()})"
    )

    return acknowledged_data

def simulate_sensor_transmission(sensor_id: str, data_payload: str) -> Tuple[str, str]:
    """
    A helper function to simulate an IoT sensor transmitting data.
    This is purely for demonstration and testing purposes.

    Args:
        sensor_id (str): The ID of the sensor transmitting data.
        data_payload (str): The raw text data payload from the sensor.

    Returns:
        Tuple[str, str]: A tuple containing the sensor_id and the data_payload.
    """
    app_logger.debug(f"Simulating transmission from {sensor_id}: {data_payload[:100]}...")
    return sensor_id, data_payload

# Example usage (for demonstration, not part of the core pipeline logic)
if __name__ == "__main__":
    sample_raw_data_1 = "TRUCK_A,2023-10-27T10:00:00Z,34.0522,-118.2437,85,200,1500"
    sample_raw_data_2 = "TRUCK_B,2023-10-27T10:00:05Z,LOC:34.0525,-118.2440;FUEL:84;ENG:201,1510"

    app_logger.info("--- Demonstrating Data Ingestion (TR-IOT-001) ---")

    # Simulate transmission and reception for TRUCK_A
    source_id_a, payload_a = simulate_sensor_transmission("Gateway-001", sample_raw_data_1)
    acknowledged_data_a = receive_raw_sensor_data(payload_a, source_id_a)
    app_logger.info(f"Acknowledged Data A: {acknowledged_data_a.data}")

    # Simulate transmission and reception for TRUCK_B
    source_id_b, payload_b = simulate_sensor_transmission("Gateway-002", sample_raw_data_2)
    acknowledged_data_b = receive_raw_sensor_data(payload_b, source_id_b)
    app_logger.info(f"Acknowledged Data B: {acknowledged_data_b.data}")
