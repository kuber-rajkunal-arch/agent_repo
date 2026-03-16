"""
Main orchestration script for the Real-time IoT Data Processing system.
This script demonstrates the end-to-end flow of data from ingestion to routing.
"""

import time
from datetime import datetime
from typing import List, Dict, Any

from src.logger import app_logger
from src.data_ingestion import receive_raw_sensor_data
from src.data_processing import process_raw_sensor_data
from src.data_routing import route_normalized_data
from src.models import RawSensorData, StandardSensorData

def run_iot_pipeline(raw_data_payloads: List[Dict[str, str]]) -> List[Dict[str, Any]]:
    """
    Executes the full IoT data processing pipeline for a list of raw data payloads.

    Args:
        raw_data_payloads (List[Dict[str, str]]): A list of dictionaries, each containing
                                                  'source_id' and 'data' for a sensor reading.

    Returns:
        List[Dict[str, Any]]: A list of dictionaries, each containing the processing
                              and routing results for a given raw data payload.
    """
    pipeline_results: List[Dict[str, Any]] = []

    app_logger.info("--- Starting IoT Data Processing Pipeline ---")

    for i, payload_info in enumerate(raw_data_payloads):
        source_id = payload_info["source_id"]
        raw_data_str = payload_info["data"]
        device_id_hint = raw_data_str.split(',')[0] if ',' in raw_data_str else raw_data_str.split(';')[0]

        app_logger.info(f"\nProcessing payload {i+1}/{len(raw_data_payloads)} for device '{device_id_hint}' from '{source_id}'...")

        # Stage 1: Sensor Data Transmission & Gateway Reception (TR-IOT-001)
        # In a real system, this would be an event trigger. Here, we simulate it.
        acknowledged_raw_data: RawSensorData = receive_raw_sensor_data(raw_data_str, source_id)
        current_result: Dict[str, Any] = {
            "payload_index": i,
            "source_id": source_id,
            "raw_data_received": acknowledged_raw_data.data,
            "ingestion_timestamp": acknowledged_raw_data.received_timestamp.isoformat(),
            "processing_successful": False,
            "routing_results": {}
        }

        # Stage 2: Data Cleaning & Transformation (TR-IOT-002)
        normalized_data: Optional[StandardSensorData] = process_raw_sensor_data(acknowledged_raw_data)

        if normalized_data:
            current_result["processing_successful"] = True
            current_result["normalized_data"] = normalized_data.to_dict()

            # Stage 3 & 4: Data Routing (TR-IOT-003 & TR-IOT-004)
            routing_status = route_normalized_data(normalized_data)
            current_result["routing_results"] = routing_status
        else:
            app_logger.error(f"Pipeline failed at processing stage for payload {i+1} (device '{device_id_hint}').")
            current_result["processing_successful"] = False
            current_result["error_message"] = "Data processing failed."

        pipeline_results.append(current_result)
        time.sleep(0.1) # Simulate some processing time

    app_logger.info("--- IoT Data Processing Pipeline Finished ---")
    return pipeline_results

if __name__ == "__main__":
    # Example raw data payloads simulating different sensor types and scenarios
    example_payloads = [
        # TRUCK_A: Normal operation, location update
        {"source_id": "Gateway-001", "data": "TRUCK_A,2023-10-27T10:00:00Z,34.0522,-118.2437,85,200,1500"},
        # TRUCK_B: Normal operation, location update
        {"source_id": "Gateway-002", "data": "TRUCK_B,2023-10-27T10:00:05Z,LOC:34.0525,-118.2440;FUEL:84;ENG:201,1510"},
        # TRUCK_A: High engine temperature alert, location update
        {"source_id": "Gateway-001", "data": "TRUCK_A,2023-10-27T10:01:00Z,34.0530,-118.2445,80,235,1600"},
        # TRUCK_B: Low fuel level alert, location update
        {"source_id": "Gateway-002", "data": "TRUCK_B,2023-10-27T10:01:05Z,LOC:34.0535,-118.2450;FUEL:8;ENG:195,1450"},
        # TRUCK_A: Invalid fuel level (will be cleaned to default), location update
        {"source_id": "Gateway-001", "data": "TRUCK_A,2023-10-27T10:02:00Z,34.0540,-118.2455,110,200,1500"},
        # TRUCK_B: Missing engine data (will be None), location update
        {"source_id": "Gateway-002", "data": "TRUCK_B,2023-10-27T10:02:05Z,LOC:34.0545,-118.2460;FUEL:75"},
        # TRUCK_A: Invalid latitude (will be None), no alerts
        {"source_id": "Gateway-001", "data": "TRUCK_A,2023-10-27T10:03:00Z,999.0,-118.2465,80,200,1500"},
        # UNKNOWN_TRUCK: Unknown format (will fail processing)
        {"source_id": "Gateway-003", "data": "UNKNOWN_TRUCK,2023-10-27T10:03:05Z,10,20,30,40,50"},
    ]

    results = run_iot_pipeline(example_payloads)

    app_logger.info("\n--- Summary of Pipeline Execution ---")
    for res in results:
        app_logger.info(f"Payload {res['payload_index']+1} (Device: {res['normalized_data']['device_id'] if res.get('normalized_data') else 'N/A'}):")
        app_logger.info(f"  Processing Successful: {res['processing_successful']}")
        if res["processing_successful"]:
            app_logger.info(f"  Normalized Data (partial): Device ID={res['normalized_data']['device_id']}, Timestamp={res['normalized_data']['timestamp']}, Lat={res['normalized_data']['latitude']}, Lon={res['normalized_data']['longitude']}, Fuel={res['normalized_data']['fuel_level']}, Temp={res['normalized_data']['engine_temperature']}")
            app_logger.info(f"  Routing Results: Engine Alert={res['routing_results']['engine_alert_routed']}, Location Update={res['routing_results']['location_update_routed']}")
        else:
            app_logger.error(f"  Error: {res.get('error_message', 'Unknown error')}")
