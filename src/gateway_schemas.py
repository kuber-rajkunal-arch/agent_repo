"""
Defines the standard data schema and helper types for the IoT Gateway project.
This module consolidates common data structures and constants.
"""

from typing import TypedDict, List, Optional, Any
import datetime

# --- Data Structures ---

class RawSensorData(TypedDict):
    """
    Represents the parsed, but not yet cleansed or normalized, sensor data.
    This intermediate format is used after initial parsing of raw text.
    """
    manufacturer: str
    timestamp_str: str  # Original timestamp string
    truck_id: str
    latitude_str: str
    longitude_str: str
    fuel_level_str: str
    engine_temp_str: str
    alert_code_str: str
    # Add other raw fields as necessary from specific sensor types

class CleansedSensorData(TypedDict):
    """
    Represents sensor data after the cleansing stage.
    Contains parsed values and flags indicating any issues or cleansing actions.
    """
    manufacturer: str
    timestamp: datetime.datetime
    truck_id: str
    latitude: float
    longitude: float
    fuel_level_percent: float
    engine_temp_celsius: float
    engine_alert_code: Optional[str]
    cleansing_flags: List[str] # List of `CleansingFlag` values
    original_raw_data: str # For debugging/auditing purposes

class StandardSensorData(TypedDict):
    """
    Represents the final standardized sensor data conforming to the company's schema.
    This is the format used for routing to various agents.
    """
    sensor_id: str # A unique ID, could be truck_id + timestamp, or from sensor
    truck_id: str
    timestamp_utc: datetime.datetime
    latitude: float
    longitude: float
    fuel_level_percent: float
    engine_temp_celsius: float
    engine_alert_code: Optional[str] # e.g., "LOW_OIL_PRESSURE", "HIGH_TEMP"
    manufacturer: str
    is_engine_alert: bool
    is_location_update: bool
    cleansing_flags: List[str] # Carries forward any flags from cleansing stage

# --- Constants / Enums (for Cleansing and Alert Flags) ---

class CleansingFlag:
    """Constants for common cleansing flags."""
    GPS_ZEROED = "GPS_ZEROED"
    GPS_INVALID_RANGE = "GPS_INVALID_RANGE"
    GPS_TEMPORARY_LOSS = "GPS_TEMPORARY_LOSS" # Placeholder for future interpolation
    FUEL_LEVEL_INVALID = "FUEL_LEVEL_INVALID"
    ENGINE_TEMP_INVALID = "ENGINE_TEMP_INVALID"
    PARSE_ERROR = "PARSE_ERROR"
    INVALID_TIMESTAMP = "INVALID_TIMESTAMP"
    MISSING_FIELD = "MISSING_FIELD"

class EngineAlertCode:
    """Constants for standardized engine alert codes."""
    LOW_OIL_PRESSURE = "LOW_OIL_PRESSURE"
    HIGH_ENGINE_TEMPERATURE = "HIGH_ENGINE_TEMPERATURE"
    CRITICAL_BATTERY = "CRITICAL_BATTERY"
    MAINTENANCE_REQUIRED = "MAINTENANCE_REQUIRED"
    UNKNOWN_ALERT = "UNKNOWN_ALERT"

# --- Configuration Schemas (for readability, not strictly enforced types) ---
# These would be defined as Pydantic models in a real project
# but for "standard Python" and simplicity, kept as Dict[str, Any] in modules.

STANDARD_SCHEMA_DEFINITION: Dict[str, Any] = {
    "sensor_id": str,
    "truck_id": str,
    "timestamp_utc": datetime.datetime,
    "latitude": float,
    "longitude": float,
    "fuel_level_percent": float,
    "engine_temp_celsius": float,
    "engine_alert_code": Optional[str],
    "manufacturer": str,
    "is_engine_alert": bool,
    "is_location_update": bool,
    "cleansing_flags": List[str]
}

# Example of expected raw data format (for parsing)
# For this exercise, we assume a common CSV-like format for ALL raw sensors,
# where the first field is the manufacturer, and order is consistent.
# In a real scenario, `_parse_raw_text` would be more sophisticated.
RAW_DATA_FIELDS_ORDER: List[str] = [
    "manufacturer",
    "timestamp_str",
    "truck_id",
    "latitude_str",
    "longitude_str",
    "fuel_level_str",
    "engine_temp_str",
    "alert_code_str"
]
