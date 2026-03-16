"""
Module for routing normalized sensor data based on detected alerts and updates.
Corresponds to TR-IOT-003 (Engine Alerts) and TR-IOT-004 (Location Updates).
"""

import json
from datetime import datetime
from typing import Optional, Dict, Any

from src.models import StandardSensorData, EngineAlert, LocationUpdate
from src.config import (
    ENGINE_ALERT_CRITERIA, LOCATION_UPDATE_CRITERIA,
    MAINTENANCE_AGENT_FORMAT, CUSTOMER_TRACKING_AGENT_FORMAT,
    MOCK_MAINTENANCE_AGENT_ENDPOINT, MOCK_CUSTOMER_TRACKING_AGENT_ENDPOINT
)
from src.logger import app_logger

class AgentCommunicationError(Exception):
    """Custom exception for errors during agent communication."""
    pass

def detect_engine_alert(data: StandardSensorData) -> Optional[EngineAlert]:
    """
    TR-IOT-003, Stage 1: Detects "Engine Alerts" based on defined criteria.

    Args:
        data (StandardSensorData): The normalized sensor data.

    Returns:
        Optional[EngineAlert]: An EngineAlert object if an alert is detected, otherwise None.
    """
    alerts_detected = []
    current_location = None
    if data.latitude is not None and data.longitude is not None:
        current_location = {"latitude": data.latitude, "longitude": data.longitude}

    for alert_type, criteria in ENGINE_ALERT_CRITERIA.items():
        field_name = criteria["field"]
        threshold = criteria["threshold"]
        operator = criteria["operator"]
        current_value = getattr(data, field_name, None)

        if current_value is None:
            app_logger.debug(f"Device {data.device_id}: Field '{field_name}' is None, skipping alert check for '{alert_type}'.")
            continue

        is_alert = False
        if operator == ">" and current_value > threshold:
            is_alert = True
        elif operator == "<" and current_value < threshold:
            is_alert = True
        elif operator == "==" and current_value == threshold:
            is_alert = True
        # Add more operators as needed

        if is_alert:
            alert = EngineAlert(
                device_id=data.device_id,
                timestamp=data.timestamp,
                alert_type=alert_type,
                alert_value=current_value,
                threshold=threshold,
                current_location=current_location,
                normalized_data_ref=data
            )
            alerts_detected.append(alert)
            app_logger.warning(f"TR-IOT-003: Engine Alert detected for device '{data.device_id}': {alert_type} (Value: {current_value}, Threshold: {threshold}).")

    # For simplicity, return the first detected alert. In a real system,
    # multiple alerts might be aggregated or handled differently.
    return alerts_detected[0] if alerts_detected else None

def format_engine_alert(alert: EngineAlert) -> str:
    """
    TR-IOT-003, Stage 3: Formats the "Engine Alert" according to the Maintenance Agent\'s system requirements.

    Args:
        alert (EngineAlert): The detected engine alert object.

    Returns:
        str: The formatted alert string (e.g., JSON).
    """
    formatted_data: Dict[str, Any] = {}
    for field in MAINTENANCE_AGENT_FORMAT["fields"]:
        if field == "current_location":
            formatted_data[field] = alert.current_location
        elif hasattr(alert, field):
            value = getattr(alert, field)
            if isinstance(value, datetime):
                formatted_data[field] = value.isoformat()
            else:
                formatted_data[field] = value
        else:
            app_logger.warning(f"Field '{field}' requested by Maintenance Agent format not found in EngineAlert.")
            formatted_data[field] = None # Or handle as error

    if MAINTENANCE_AGENT_FORMAT["type"] == "json":
        return json.dumps(formatted_data)
    else:
        # Fallback or other formats
        return str(formatted_data)

def transmit_engine_alert(formatted_alert: str) -> bool:
    """
    TR-IOT-003, Stage 4: Transmits the formatted "Engine Alert" to the Maintenance Agent.

    This function simulates sending the alert to an external system.
    In a real system, this would involve an API call, message queue publish, etc.

    Args:
        formatted_alert (str): The alert data formatted for the Maintenance Agent.

    Returns:
        bool: True if transmission was successful, False otherwise.
    """
    app_logger.info(f"TR-IOT-003: Transmitting Engine Alert to Maintenance Agent (Endpoint: {MOCK_MAINTENANCE_AGENT_ENDPOINT}).")
    app_logger.debug(f"Alert Payload: {formatted_alert}")
    # Simulate network call / API interaction
    try:
        # In a real scenario, this would be requests.post(MOCK_MAINTENANCE_AGENT_ENDPOINT, data=formatted_alert)
        # For now, just log the action.
        if "CRITICAL" in formatted_alert: # Simulate a failure for critical alerts sometimes
            # raise AgentCommunicationError("Simulated network error for critical alert.")
            pass # For now, always succeed for simplicity in demo
        app_logger.info(f"TR-IOT-003: Engine Alert transmitted successfully.")
        return True
    except AgentCommunicationError as e:
        app_logger.error(f"TR-IOT-003: Failed to transmit Engine Alert: {e}")
        return False
    except Exception as e:
        app_logger.error(f"TR-IOT-003: Unexpected error during Engine Alert transmission: {e}")
        return False

def detect_location_update(data: StandardSensorData) -> Optional[LocationUpdate]:
    """
    TR-IOT-004, Stage 1: Detects "Location Updates" based on defined criteria.

    For simplicity, this function considers any valid location data in the
    StandardSensorData as a location update. In a real system, this might
    involve comparing with the last known location to detect significant movement.

    Args:
        data (StandardSensorData): The normalized sensor data.

    Returns:
        Optional[LocationUpdate]: A LocationUpdate object if valid location data is present,
                                  otherwise None.
    """
    lat = data.latitude
    lon = data.longitude

    if lat is None or lon is None:
        app_logger.debug(f"Device {data.device_id}: No valid location data for update detection.")
        return None

    # Apply basic validation from config
    if not (LOCATION_UPDATE_CRITERIA["min_latitude"] <= lat <= LOCATION_UPDATE_CRITERIA["max_latitude"] and
            LOCATION_UPDATE_CRITERIA["min_longitude"] <= lon <= LOCATION_UPDATE_CRITERIA["max_longitude"]):
        app_logger.warning(f"Device {data.device_id}: Invalid location coordinates ({lat}, {lon}), skipping update.")
        return None

    # In a more advanced system, you\'d compare with previous location:
    # if LOCATION_UPDATE_CRITERIA["require_change"]:
    #     last_location = get_last_known_location(data.device_id)
    #     if last_location and calculate_distance(lat, lon, last_location.lat, last_location.lon) < MIN_DISTANCE_CHANGE:
    #         return None

    location_update = LocationUpdate(
        device_id=data.device_id,
        timestamp=data.timestamp,
        latitude=lat,
        longitude=lon,
        normalized_data_ref=data
    )
    app_logger.info(f"TR-IOT-004: Location Update detected for device '{data.device_id}': ({lat}, {lon}).")
    return location_update

def format_location_update(update: LocationUpdate) -> str:
    """
    TR-IOT-004, Stage 3: Formats the "Location Update" according to the Customer Tracking Agent\'s system requirements.

    Args:
        update (LocationUpdate): The detected location update object.

    Returns:
        str: The formatted location update string (e.g., JSON).
    """
    formatted_data: Dict[str, Any] = {}
    for field in CUSTOMER_TRACKING_AGENT_FORMAT["fields"]:
        if hasattr(update, field):
            value = getattr(update, field)
            if isinstance(value, datetime):
                formatted_data[field] = value.isoformat()
            else:
                formatted_data[field] = value
        else:
            app_logger.warning(f"Field '{field}' requested by Customer Tracking Agent format not found in LocationUpdate.")
            formatted_data[field] = None

    if CUSTOMER_TRACKING_AGENT_FORMAT["type"] == "json":
        return json.dumps(formatted_data)
    else:
        # Fallback or other formats
        return str(formatted_data)

def transmit_location_update(formatted_update: str) -> bool:
    """
    TR-IOT-004, Stage 4: Transmits the formatted "Location Update" to the Customer Tracking Agent.

    This function simulates sending the update to an external system.

    Args:
        formatted_update (str): The location data formatted for the Customer Tracking Agent.

    Returns:
        bool: True if transmission was successful, False otherwise.
    """
    app_logger.info(f"TR-IOT-004: Transmitting Location Update to Customer Tracking Agent (Endpoint: {MOCK_CUSTOMER_TRACKING_AGENT_ENDPOINT}).")
    app_logger.debug(f"Location Payload: {formatted_update}")
    try:
        # Simulate network call / API interaction
        # For now, just log the action.
        app_logger.info(f"TR-IOT-004: Location Update transmitted successfully.")
        return True
    except Exception as e:
        app_logger.error(f"TR-IOT-004: Failed to transmit Location Update: {e}")
        return False

def route_normalized_data(data: StandardSensorData) -> Dict[str, bool]:
    """
    Orchestrates the routing of normalized sensor data to relevant agents.
    This function combines TR-IOT-003 and TR-IOT-004.

    Args:
        data (StandardSensorData): The normalized sensor data.

    Returns:
        Dict[str, bool]: A dictionary indicating the success status of each routing action.
    """
    routing_status = {
        "engine_alert_routed": False,
        "location_update_routed": False
    }
    device_id = data.device_id

    app_logger.info(f"Starting routing for normalized data from device '{device_id}'.")

    # TR-IOT-003: Engine Alert Routing
    engine_alert = detect_engine_alert(data)
    if engine_alert:
        formatted_alert = format_engine_alert(engine_alert)
        routing_status["engine_alert_routed"] = transmit_engine_alert(formatted_alert)
        app_logger.info(f"TR-IOT-003: Alert routing status for device '{device_id}': {routing_status['engine_alert_routed']}")
    else:
        app_logger.info(f"TR-IOT-003: No Engine Alert detected for device '{device_id}'.")

    # TR-IOT-004: Location Update Routing
    location_update = detect_location_update(data)
    if location_update:
        formatted_update = format_location_update(location_update)
        routing_status["location_update_routed"] = transmit_location_update(formatted_update)
        app_logger.info(f"TR-IOT-004: Location update routing status for device '{device_id}': {routing_status['location_update_routed']}")
    else:
        app_logger.info(f"TR-IOT-004: No Location Update detected for device '{device_id}'.")

    app_logger.info(f"Finished routing for device '{device_id}'. Status: {routing_status}")
    return routing_status

# Example usage (for demonstration, not part of the core pipeline logic)
if __name__ == "__main__":
    from src.data_processing import process_raw_sensor_data
    from src.data_ingestion import receive_raw_sensor_data

    app_logger.info("--- Demonstrating Data Routing (TR-IOT-003 & TR-IOT-004) ---")

    # Scenario 1: Data with high engine temperature (triggers alert) and location update
    raw_data_alert_loc = receive_raw_sensor_data("TRUCK_A,2023-10-27T10:05:00Z,34.1000,-118.3000,70,230,1800", "Gateway-001")
    normalized_data_alert_loc = process_raw_sensor_data(raw_data_alert_loc)
    if normalized_data_alert_loc:
        app_logger.info(f"\nRouting data for device {normalized_data_alert_loc.device_id} (High Temp, Location):")
        routing_results = route_normalized_data(normalized_data_alert_loc)
        app_logger.info(f"Routing Results: {routing_results}")
    else:
        app_logger.error("Failed to normalize data for alert/location scenario.")

    print("\n" + "="*50 + "\n")

    # Scenario 2: Data with low fuel level (triggers alert) and location update
    raw_data_low_fuel_loc = receive_raw_sensor_data("TRUCK_B,2023-10-27T10:06:00Z,LOC:34.1010,-118.3010;FUEL:5;ENG:190,1200", "Gateway-002")
    normalized_data_low_fuel_loc = process_raw_sensor_data(raw_data_low_fuel_loc)
    if normalized_data_low_fuel_loc:
        app_logger.info(f"\nRouting data for device {normalized_data_low_fuel_loc.device_id} (Low Fuel, Location):")
        routing_results = route_normalized_data(normalized_data_low_fuel_loc)
        app_logger.info(f"Routing Results: {routing_results}")
    else:
        app_logger.error("Failed to normalize data for low fuel/location scenario.")

    print("\n" + "="*50 + "\n")

    # Scenario 3: Normal data (no alerts, only location update)
    raw_data_normal_loc = receive_raw_sensor_data("TRUCK_A,2023-10-27T10:07:00Z,34.1020,-118.3020,60,190,1400", "Gateway-001")
    normalized_data_normal_loc = process_raw_sensor_data(raw_data_normal_loc)
    if normalized_data_normal_loc:
        app_logger.info(f"\nRouting data for device {normalized_data_normal_loc.device_id} (Normal, Location):")
        routing_results = route_normalized_data(normalized_data_normal_loc)
        app_logger.info(f"Routing Results: {routing_results}")
    else:
        app_logger.error("Failed to normalize data for normal/location scenario.")

    print("\n" + "="*50 + "\n")

    # Scenario 4: Data with invalid location (no location update, no alerts)
    raw_data_invalid_loc = receive_raw_sensor_data("TRUCK_A,2023-10-27T10:08:00Z,999.0,-118.3030,60,190,1400", "Gateway-001")
    normalized_data_invalid_loc = process_raw_sensor_data(raw_data_invalid_loc)
    if normalized_data_invalid_loc:
        app_logger.info(f"\nRouting data for device {normalized_data_invalid_loc.device_id} (Invalid Location):")
        routing_results = route_normalized_data(normalized_data_invalid_loc)
        app_logger.info(f"Routing Results: {routing_results}")
    else:
        app_logger.error("Failed to normalize data for invalid location scenario.")
