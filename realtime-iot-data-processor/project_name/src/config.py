"""
Configuration settings for the IoT Data Processing system.
This module centralizes parameters for data parsing, cleaning, and alert detection.
"""

from typing import Dict, Any, List

# --- General Configuration ---
SYSTEM_NAME: str = "IoT_Logistics_Processor"
DEFAULT_TIMEZONE: str = "UTC"

# --- Sensor Data Formats (for TR-IOT-002: Source Identification) ---
# Defines how to parse raw text data for different sensor types.
# In a real-world scenario, this might be loaded from a database or external configuration.
# For this example, we assume two simple formats: CSV-like and Key-Value pair.
SENSOR_FORMATS: Dict[str, Dict[str, Any]] = {
    "TRUCK_A": {
        "type": "csv",
        "delimiter": ",",
        "fields": [
            "device_id", "timestamp", "latitude", "longitude",
            "fuel_level", "engine_temperature", "engine_rpm"
        ],
        "field_types": {
            "timestamp": "datetime",
            "latitude": "float",
            "longitude": "float",
            "fuel_level": "int",
            "engine_temperature": "int",
            "engine_rpm": "int"
        }
    },
    "TRUCK_B": {
        "type": "key_value",
        "delimiter": ";",
        "kv_separator": ":",
        "prefix_map": {
            "LOC": ["latitude", "longitude"],
            "FUEL": ["fuel_level"],
            "ENG": ["engine_temperature", "engine_rpm"]
        },
        "fixed_fields": ["device_id", "timestamp"],
        "field_types": {
            "timestamp": "datetime",
            "latitude": "float",
            "longitude": "float",
            "fuel_level": "int",
            "engine_temperature": "int",
            "engine_rpm": "int"
        }
    }
}

# --- Data Cleaning Rules (for TR-IOT-002: Data Cleaning) ---
# Defines validation rules for various sensor data fields.
CLEANING_RULES: Dict[str, Dict[str, Any]] = {
    "latitude": {"min": -90.0, "max": 90.0, "default_on_invalid": None},
    "longitude": {"min": -180.0, "max": 180.0, "default_on_invalid": None},
    "fuel_level": {"min": 0, "max": 100, "default_on_invalid": 0}, # Assume percentage
    "engine_temperature": {"min": 0, "max": 300, "default_on_invalid": 100}, # Celsius or Fahrenheit, reasonable range
    "engine_rpm": {"min": 0, "max": 5000, "default_on_invalid": 0},
    "timestamp": {"format": "%Y-%m-%dT%H:%M:%SZ", "default_on_invalid": None} # ISO 8601
}

# --- Engine Alert Detection Criteria (for TR-IOT-003) ---
ENGINE_ALERT_CRITERIA: Dict[str, Any] = {
    "engine_temperature_high": {"field": "engine_temperature", "threshold": 220, "operator": ">"}, # e.g., Fahrenheit
    "fuel_level_low": {"field": "fuel_level", "threshold": 10, "operator": "<"}, # e.g., percentage
    "engine_rpm_high": {"field": "engine_rpm", "threshold": 3500, "operator": ">"}
}

# --- Location Update Detection Criteria (for TR-IOT-004) ---
# For simplicity, we'll assume any valid location data is an update.
# In a real system, this might involve checking distance moved, time elapsed, etc.
LOCATION_UPDATE_CRITERIA: Dict[str, Any] = {
    "min_latitude": -90.0,
    "max_latitude": 90.0,
    "min_longitude": -180.0,
    "max_longitude": 180.0,
    "require_change": False # If True, would need to compare with last known location
}

# --- Agent System Requirements (for TR-IOT-003 & TR-IOT-004) ---
# Defines the output format for different agents.
MAINTENANCE_AGENT_FORMAT: Dict[str, Any] = {
    "type": "json",
    "fields": ["device_id", "timestamp", "alert_type", "alert_value", "current_location"]
}

CUSTOMER_TRACKING_AGENT_FORMAT: Dict[str, Any] = {
    "type": "json",
    "fields": ["device_id", "timestamp", "latitude", "longitude"]
}

# --- Mock Transmission Endpoints ---
# In a real system, these would be actual API endpoints, message queues, etc.
MOCK_MAINTENANCE_AGENT_ENDPOINT: str = "http://mock-maintenance-agent.com/alerts"
MOCK_CUSTOMER_TRACKING_AGENT_ENDPOINT: str = "http://mock-customer-tracking.com/locations"

# --- Logging Configuration ---
LOG_LEVEL: str = "INFO" # DEBUG, INFO, WARNING, ERROR, CRITICAL
LOG_FILE_ENABLED: bool = True
LOG_FILE_NAME: str = "iot_processor.log"
