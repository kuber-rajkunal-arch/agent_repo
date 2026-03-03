"""
Main entry point for the IoT Sensor Data Gateway demonstration.
This script orchestrates the data processing pipeline: Ingest -> Cleanse -> Normalize -> Route.
"""

import logging
import time
from typing import List

from project_name.src.gateway_ingest import SensorDataIngestor
from project_name.src.gateway_cleanse import SensorDataCleanser
from project_name.src.gateway_normalize import SensorDataNormalizer
from project_name.src.gateway_router import GatewayRouter
from project_name.src.gateway_schemas import RawSensorData, CleansedSensorData, StandardSensorData

# --- Configure Logging ---
logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def run_gateway_pipeline(raw_sensor_data_stream: List[str]):
    """
    Orchestrates the IoT Gateway data processing pipeline for a given stream of raw data.

    Args:
        raw_sensor_data_stream (List[str]): A list of raw sensor data strings to process.
    """
    logger.info("Starting IoT Gateway pipeline.")

    # 1. Initialize Gateway Components
    ingestor = SensorDataIngestor(buffer_max_size=10)
    cleanser = SensorDataCleanser()
    normalizer = SensorDataNormalizer()
    router = GatewayRouter()

    processed_count = 0
    errors_count = 0

    for i, raw_data in enumerate(raw_sensor_data_stream):
        logger.info(f"\n--- Processing data point {i+1}/{len(raw_sensor_data_stream)} ---")
        try:
            # Ingest
            ingestor.ingest_raw_data(raw_data)
            buffered_data = ingestor.get_buffered_data(count=1) # Process one by one

            if not buffered_data:
                logger.warning(f"Ingestor returned no data for raw input: {raw_data}")
                errors_count += 1
                continue
            
            current_raw_data = buffered_data[0]
            logger.debug(f"Ingested: {current_raw_data[:70]}...")

            # Cleanse
            cleansed_data: CleansedSensorData = cleanser.cleanse(current_raw_data)
            logger.debug(f"Cleansed Data: {cleansed_data}")

            # Normalize
            normalized_data: StandardSensorData = normalizer.normalize(cleansed_data)
            logger.debug(f"Normalized Data: {normalized_data}")

            # Route
            router.route_data(normalized_data)
            processed_count += 1

        except Exception as e:
            logger.error(f"Error processing raw data '{raw_data[:70]}...': {e}", exc_info=True)
            errors_count += 1
            # In a real system, problematic data would be sent to a dead-letter queue.
        
        # Simulate a small delay between processing records
        # time.sleep(0.01)

    logger.info(f"\n--- IoT Gateway Pipeline Finished ---")
    logger.info(f"Total records processed successfully: {processed_count}")
    logger.info(f"Total records with errors: {errors_count}")


if __name__ == "__main__":
    # Example raw sensor data streams
    example_raw_data = [
        # Normal Bosch data
        "BOSCH,2023-10-27T10:00:00Z,TRUCK001,40.7128,-74.0060,55.2,85.1,NORMAL",
        # Garmin with a low oil pressure alert
        "GARMIN,2023-10-27T10:00:05Z,TRUCK002,34.0522,-118.2437,40.1,90.5,LOW_OIL_PRESSURE",
        # Bosch with zeroed GPS (noisy)
        "BOSCH,2023-10-27T10:00:10Z,TRUCK001,0.0,0.0,55.1,85.0,NORMAL",
        # Garmin with invalid fuel level and high engine temperature alert
        "GARMIN,2023-10-27T10:00:15Z,TRUCK003,33.0,-117.0,105.0,120.0,TEMP_EXCEEDED",
        # Bosch with critical battery alert, missing timestamp
        "BOSCH,,TRUCK004,38.0,-97.0,70.0,75.0,BATT_CRIT",
        # Malformed data (too few fields)
        "MALFORMED_SENSOR,2023-10-27T10:00:25Z,TRUCK005,10.0,20.0",
        # Another normal Bosch, after the noisy one
        "BOSCH,2023-10-27T10:00:30Z,TRUCK001,40.7129,-74.0061,54.9,84.9,NORMAL",
        # Garmin, with valid data, but non-critical alert "INSPECT_ENGINE" (will be routed if include_all_alerts=True in router config)
        "GARMIN,2023-10-27T10:00:35Z,TRUCK006,35.1,-80.8,60.0,92.0,INSPECT_ENGINE",
        # Bosch, with an alert code not mapped, will become UNKNOWN_ALERT
        "BOSCH,2023-10-27T10:00:40Z,TRUCK007,32.0,-111.0,65.0,88.0,UNIDENTIFIED_ISSUE"
    ]

    run_gateway_pipeline(example_raw_data)

