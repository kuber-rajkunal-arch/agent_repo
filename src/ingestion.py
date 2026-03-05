"""
Ingestion module for the IoT Sensor Data Gateway.

This module handles the reception and initial capture of raw sensor data
from various IoT sensors, as per FR-GW-001.
"""

import logging
from typing import Optional

logger = logging.getLogger(__name__)

class IngestionService:
    """
    Manages the ingestion of raw sensor data.

    Capable of receiving raw sensor data text and temporarily storing it
    for subsequent processing.
    """

    def __init__(self):
        """
        Initializes the IngestionService.
        """
        logger.info("IngestionService initialized.")

    def ingest_raw_data(self, raw_sensor_text: str) -> Optional[str]:
        """
        Ingests a single raw sensor data text string.

        Simulates continuous listening and captures the incoming text.
        In a real-world scenario, this method would be called by a listener
        thread/process receiving data from a message queue, MQTT broker,
        or direct TCP/UDP connection.

        Args:
            raw_sensor_text: The raw text string received from an IoT sensor.

        Returns:
            The raw sensor text if successfully ingested, otherwise None.
        """
        if not isinstance(raw_sensor_text, str) or not raw_sensor_text.strip():
            logger.warning("Attempted to ingest empty or invalid raw sensor data.")
            return None

        # Simulate capturing and temporary storage.
        # In a real system, this might involve writing to a temporary buffer,
        # a short-term queue (e.g., Kafka, Redis stream), or a memory-backed
        # data structure. For this exercise, returning the string implies
        # it's "temporarily stored" and immediately available for the next stage.
        logger.debug(f"Successfully ingested raw data: {raw_sensor_text[:100]}...")
        return raw_sensor_text
