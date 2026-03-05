"""
Configuration settings for the IoT Sensor Data Gateway.

This module centralizes various configurations such as cleaning rules,
normalization mappings, agent communication endpoints, and logging settings.
"""

import logging
from typing import Dict, Any, List, Pattern
import re

class AppConfig:
    """
    Centralized configuration class for the IoT Sensor Data Gateway.
    """

    # --- General Settings ---
    LOG_LEVEL: int = logging.INFO
    LOG_FORMAT: str = (
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )

    # --- Data Cleaning Rules (FR-GW-002) ---
    # These rules are applied to raw text data.
    # Example: patterns for identifying noisy GPS data
    NOISE_PATTERNS: Dict[str, List[Pattern[str]]] = {
        "gps_noise": [
            re.compile(r"GPS:(?:LOST|INVALID|NO_SIGNAL)", re.IGNORECASE),
            re.compile(r"LAT:(?:-?999\.?9*)|LON:(?:-?999\.?9*)", re.IGNORECASE) # e.g. -999.0 for invalid
        ],
        "erratic_temp": [
            re.compile(r"ENGINE_TEMP:(\d+\.?\d*)"), # Capture temp value
        ]
    }
    # Default values to use for "interpolation" or correction
    CLEANING_DEFAULTS: Dict[str, Any] = {
        "default_latitude": 34.0522,  # Example: Los Angeles
        "default_longitude": -118.2437,
        "default_engine_temp": 80.0, # Default if erratic temp detected
    }
    # Thresholds for erratic readings (example for engine temperature)
    ENGINE_TEMP_MIN_C: float = -20.0
    ENGINE_TEMP_MAX_C: float = 150.0 # Arbitrary high temperature

    # --- Data Normalization Mappings (FR-GW-003) ---
    # This defines how raw fields from different manufacturers map
    # to the StandardSensorData fields.
    # Each manufacturer has a dictionary of mappings from their raw field names
    # (or regex patterns to extract values) to the standard schema fields.
    # The `_parser` key can specify a custom parsing function if needed.
    MANUFACTURER_MAPPINGS: Dict[str, Dict[str, Any]] = {
        "BOSCH": {
            "sensor_id": r"SENSOR_ID:([^|]+)",
            "timestamp": r"TS:(\d{10})", # Unix timestamp
            "latitude": r"LAT:(-?\d+\.\d+)",
            "longitude": r"LON:(-?\d+\.\d+)",
            "engine_temp_celsius": r"ET:(\d+\.\d+)",
            "oil_pressure_psi": r"OP:(\d+\.?\d*)",
            "fuel_level_percent": r"FL:(\d+)",
            "engine_status": r"ES:([A-Z_]+)",
            "_parser": { # Optional custom parsers for specific fields
                "timestamp": lambda x: datetime.fromtimestamp(int(x))
            }
        },
        "GARMIN": {
            "sensor_id": r"DEVICE_ID:([^|]+)",
            "timestamp": r"DATETIME:(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)", # ISO format
            "latitude": r"GPS_LAT:(-?\d+\.\d+)",
            "longitude": r"GPS_LON:(-?\d+\.\d+)",
            "altitude": r"ALT:(\d+\.?\d*)",
            "location_accuracy": r"ACCURACY:(HIGH|MEDIUM|LOW)",
            "engine_rpm": r"RPM:(\d+)",
            "engine_status": r"ENG_STAT:(OK|ALERT|WARN)",
            "_parser": {
                "timestamp": lambda x: datetime.strptime(x, "%Y-%m-%dT%H:%M:%SZ")
            }
        },
        "GENERIC": { # A fallback for unknown or generic sensor types
            "sensor_id": r"ID:([^|]+)",
            "timestamp": r"TIME:(\d{10})",
            "latitude": r"LAT:(-?\d+\.\d+)",
            "longitude": r"LON:(-?\d+\.\d+)",
            "_parser": {
                "timestamp": lambda x: datetime.fromtimestamp(int(x))
            }
        }
    }

    # --- Agent Communication Endpoints (FR-GW-004, FR-GW-005) ---
    # In a real system, these would be URLs, Kafka topics, queue names, etc.
    # Here, they are placeholders for simulation.
    MAINTENANCE_AGENT_ENDPOINT: str = "http://maintenance-api.example.com/alerts"
    CUSTOMER_TRACKING_AGENT_ENDPOINT: str = "kafka://customer-tracking-topic"

    # --- Alerting Rules (FR-GW-004) ---
    ENGINE_ALERT_RULES: Dict[str, Any] = {
        "engine_temp_threshold": 100.0, # Celsius
        "oil_pressure_min_psi": 10.0,
        "engine_status_keywords": ["ALERT", "WARNING", "CRITICAL"]
    }


# Initialize basic logging
logging.basicConfig(level=AppConfig.LOG_LEVEL, format=AppConfig.LOG_FORMAT)
logger = logging.getLogger(__name__)
