"""
Main Gateway Orchestration for the IoT Sensor Data Gateway.

This module integrates all processing stages: ingestion, cleaning, normalization,
and routing, to form the complete data processing pipeline.
"""

import logging
from typing import Optional

from project_name.src.ingestion import IngestionService
from project_name.src.cleaning import DataCleaner
from project_name.src.normalization import Normalizer
from project_name.src.routing import MaintenanceAlertRouter, CustomerTrackingRouter
from project_name.src.agents import MockMaintenanceAgent, MockCustomerTrackingAgent
from project_name.src.data_models import StandardSensorData
from project_name.src.config import AppConfig # For agent endpoints

logger = logging.getLogger(__name__)

class IoTDataGateway:
    """
    Orchestrates the entire IoT sensor data processing pipeline.

    Includes services for ingestion, cleaning, normalization, and routing
    data to appropriate agents.
    """

    def __init__(self):
        """
        Initializes the IoTDataGateway by setting up all its components.
        """
        self.ingestion_service = IngestionService()
        self.data_cleaner = DataCleaner()
        self.normalizer = Normalizer()

        # Initialize mock agents
        maintenance_agent = MockMaintenanceAgent(AppConfig.MAINTENANCE_AGENT_ENDPOINT)
        customer_tracking_agent = MockCustomerTrackingAgent(AppConfig.CUSTOMER_TRACKING_AGENT_ENDPOINT)

        self.maintenance_router = MaintenanceAlertRouter(maintenance_agent)
        self.customer_router = CustomerTrackingRouter(customer_tracking_agent)

        logger.info("IoTDataGateway initialized and ready to process sensor data.")

    def process_sensor_data(self, raw_sensor_text: str) -> Optional[StandardSensorData]:
        """
        Executes the full pipeline for a single raw sensor data string.

        1. Ingests raw data.
        2. Cleans the ingested data.
        3. Normalizes the cleaned data to a standard schema.
        4. Routes alerts and location updates to respective agents.

        Args:
            raw_sensor_text: The raw text string from an IoT sensor.

        Returns:
            The final StandardSensorData object if processing is successful,
            otherwise None.
        """
        logger.info(f"Starting processing for raw data: {raw_sensor_text[:50]}...")

        # FR-GW-001: Ingest Raw Sensor Data
        ingested_data = self.ingestion_service.ingest_raw_data(raw_sensor_text)
        if not ingested_data:
            logger.error("Data ingestion failed. Aborting processing.")
            return None
        logger.debug("Raw data ingested successfully.")

        # FR-GW-002: Clean Raw Sensor Data
        cleaned_data = self.data_cleaner.clean_raw_data(ingested_data)
        if not cleaned_data:
            logger.error("Data cleaning resulted in empty data. Aborting processing.")
            return None
        logger.debug("Data cleaned successfully.")

        # FR-GW-003: Normalize Data to Standard Schema
        normalized_data = self.normalizer.normalize_data(cleaned_data)
        if not normalized_data:
            logger.error("Data normalization failed. Aborting processing.")
            return None
        logger.debug(f"Data normalized successfully for sensor_id: {normalized_data.sensor_id}")

        # FR-GW-004: Route Engine Alerts to Maintenance Agent
        self.maintenance_router.route_engine_alert(normalized_data)

        # FR-GW-005: Route Location Updates to Customer Tracking Agent
        self.customer_router.route_location_update(normalized_data)

        logger.info(f"Finished processing for sensor_id: {normalized_data.sensor_id}")
        return normalized_data

    def run_simulation(self, raw_data_samples: list[str]):
        """
        Runs a simulation of the gateway processing multiple data samples.

        Args:
            raw_data_samples: A list of raw sensor data strings.
        """
        logger.info("Starting IoT Data Gateway simulation...")
        processed_count = 0
        failed_count = 0

        for i, raw_sample in enumerate(raw_data_samples):
            logger.info(f"\n--- Processing Sample {i+1}/{len(raw_data_samples)} ---")
            try:
                result = self.process_sensor_data(raw_sample)
                if result:
                    processed_count += 1
                else:
                    failed_count += 1
            except Exception as e:
                logger.critical(f"Unhandled exception during processing of sample {i+1}: {e}", exc_info=True)
                failed_count += 1
        
        logger.info(f"\n--- Simulation Finished ---")
        logger.info(f"Total samples: {len(raw_data_samples)}")
        logger.info(f"Successfully processed: {processed_count}")
        logger.info(f"Failed to process: {failed_count}")


if __name__ == '__main__':
    # Example usage and simulation
    # Ensure project_name is added to sys.path if running directly from 'src'
    import sys
    import os
    sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

    gateway = IoTDataGateway()

    # --- Realistic Example Input Data ---
    # Data is simulated as pipe-separated key-value pairs for demonstration.
    # The manufacturer prefix (e.g., BOSCH, GARMIN) helps in routing to correct parsing logic.
    # TS and DATETIME are used for timestamps, showing different formats.
    # LAT/LON values might include specific noise patterns or extreme values for cleaning tests.

    sample_raw_data = [
        # Sample 1: Bosch sensor, normal operation
        "BOSCH|SENSOR_ID:truck_001|TS:1678886400|LAT:34.0522|LON:-118.2437|ET:85.5|OP:45.0|FL:75|ES:OK",

        # Sample 2: Garmin sensor, location update only, different timestamp format
        "GARMIN|DEVICE_ID:truck_002|DATETIME:2023-03-15T10:30:00Z|GPS_LAT:34.1000|GPS_LON:-118.3000|ALT:100.5|ACCURACY:HIGH|RPM:1500|ENG_STAT:OK",

        # Sample 3: Bosch sensor, with GPS noise (LOST) - expected to be cleaned
        "BOSCH|SENSOR_ID:truck_003|TS:1678886460|LAT:GPS:LOST|LON:INVALID|ET:88.0|OP:46.2|FL:60|ES:OK",

        # Sample 4: Garmin sensor, engine alert (high temperature & low oil pressure)
        # Temp is also slightly above threshold defined in config.py (100.0)
        "GARMIN|DEVICE_ID:truck_004|DATETIME:2023-03-15T10:31:00Z|GPS_LAT:34.1500|GPS_LON:-118.3500|ALT:110.0|ACCURACY:MEDIUM|RPM:2200|ENG_STAT:ALERT|ET:101.5|OP:9.5",

        # Sample 5: Bosch sensor, with erratic temperature (out of defined range) - expected to be cleaned
        "BOSCH|SENSOR_ID:truck_005|TS:1678886520|LAT:34.2000|LON:-118.4000|ET:999.0|OP:40.0|FL:50|ES:WARNING",

        # Sample 6: Generic sensor, minimal data
        "GENERIC|ID:truck_006|TIME:1678886580|LAT:34.2500|LON:-118.4500",

        # Sample 7: Bosch sensor, with engine warning status
        "BOSCH|SENSOR_ID:truck_007|TS:1678886640|LAT:34.3000|LON:-118.5000|ET:90.0|OP:42.0|FL:80|ES:WARNING",

        # Sample 8: Empty/invalid raw data (should be handled gracefully)
        "",

        # Sample 9: Garmin sensor, normal operation, slightly different fields
        "GARMIN|DEVICE_ID:truck_008|DATETIME:2023-03-15T10:33:00Z|GPS_LAT:34.3500|GPS_LON:-118.5500|RPM:1800|ACCURACY:LOW|ENG_STAT:OK",
    ]

    gateway.run_simulation(raw_data_samples)

    # You can also process individual samples:
    # print("\n--- Processing single sample ---")
    # specific_raw_data = "BOSCH|SENSOR_ID:truck_test|TS:1678887000|LAT:33.9000|LON:-118.0000|ET:95.0|OP:48.0|FL:90|ES:OK"
    # processed_item = gateway.process_sensor_data(specific_raw_data)
    # if processed_item:
    #     logger.info(f"Single processed item: {processed_item.to_dict()}")
