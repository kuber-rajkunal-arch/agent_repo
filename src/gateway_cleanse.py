"""
Module for cleansing raw sensor data.
Implements FR-GW-002 and TR-GW-002.
"""

import logging
import datetime
import math
from typing import Dict, Any, List, Optional, Callable

from project_name.src.gateway_schemas import RawSensorData, CleansedSensorData, CleansingFlag, RAW_DATA_FIELDS_ORDER

logger = logging.getLogger(__name__)

class SensorDataCleanser:
    """
    Processes ingested raw sensor text to identify and clean "noisy" data.
    It parses raw text into a structured format and applies predefined
    cleansing rules.
    """

    def __init__(self, cleansing_rules: Optional[Dict[str, Any]] = None):
        """
        Initializes the SensorDataCleanser with optional custom cleansing rules.

        Args:
            cleansing_rules (Optional[Dict[str, Any]]): A dictionary of rules
                                                        to apply during cleansing.
        """
        self.cleansing_rules = cleansing_rules if cleansing_rules is not None else self._default_cleansing_rules()
        logger.info("SensorDataCleanser initialized.")

    def _default_cleansing_rules(self) -> Dict[str, Any]:
        """
        Defines default rules for identifying and handling noisy data.
        """
        return {
            "gps_zero_threshold_lat": 0.0001,  # Latitude near 0
            "gps_zero_threshold_lon": 0.0001,  # Longitude near 0
            "fuel_level_min": 0.0,
            "fuel_level_max": 100.0,
            "engine_temp_min_c": -20.0,
            "engine_temp_max_c": 150.0,
            "missing_field_placeholder": "N/A"
        }

    def _parse_raw_text(self, raw_text: str) -> RawSensorData:
        """
        Parses a raw sensor data string into a RawSensorData dictionary.
        Assumes a comma-separated format.

        Args:
            raw_text (str): The raw text string from a sensor.

        Returns:
            RawSensorData: A dictionary containing parsed raw fields.
        """
        parts = raw_text.strip().split(',')
        if len(parts) != len(RAW_DATA_FIELDS_ORDER):
            logger.warning(f"Raw data format mismatch. Expected {len(RAW_DATA_FIELDS_ORDER)} fields, got {len(parts)}. Raw: {raw_text}")
            # Pad with empty strings or raise error, depending on robustness needed.
            # For now, pad, and cleanser will flag missing fields.
            padded_parts = parts + [''] * (len(RAW_DATA_FIELDS_ORDER) - len(parts))
            return RawSensorData(**dict(zip(RAW_DATA_FIELDS_ORDER, padded_parts)))
        return RawSensorData(**dict(zip(RAW_DATA_FIELDS_ORDER, parts)))

    def cleanse(self, raw_text: str) -> CleansedSensorData:
        """
        Cleanses a single raw sensor data string.

        Args:
            raw_text (str): The raw text string to cleanse.

        Returns:
            CleansedSensorData: A dictionary with cleansed data and flags.
        """
        cleansing_flags: List[str] = []
        parsed_raw_data: RawSensorData = self._parse_raw_text(raw_text)

        # Initialize cleansed_data with default values or extracted known fields
        cleansed_data: CleansedSensorData = {
            "manufacturer": parsed_raw_data.get("manufacturer", "UNKNOWN"),
            "timestamp": datetime.datetime.min, # Placeholder, will be parsed
            "truck_id": parsed_raw_data.get("truck_id", "UNKNOWN_TRUCK"),
            "latitude": 0.0,
            "longitude": 0.0,
            "fuel_level_percent": 0.0,
            "engine_temp_celsius": 0.0,
            "engine_alert_code": None,
            "cleansing_flags": cleansing_flags,
            "original_raw_data": raw_text
        }

        # --- Parse and Validate Timestamp ---
        try:
            # Assuming ISO 8601 format like "2023-10-27T10:00:00Z"
            cleansed_data["timestamp"] = datetime.datetime.fromisoformat(
                parsed_raw_data.get("timestamp_str", "").replace("Z", "+00:00")
            )
        except (ValueError, TypeError):
            cleansing_flags.append(CleansingFlag.INVALID_TIMESTAMP)
            logger.warning(f"Invalid timestamp '{parsed_raw_data.get('timestamp_str')}' for truck {parsed_raw_data.get('truck_id')}. Flagged.")
            # Default to current UTC time or min datetime if parsing fails

        # --- Parse and Validate GPS (Latitude, Longitude) ---
        try:
            lat = float(parsed_raw_data.get("latitude_str", "0.0"))
            lon = float(parsed_raw_data.get("longitude_str", "0.0"))

            # Check for "noisy" GPS data (e.g., 0,0 from signal loss)
            if (abs(lat) < self.cleansing_rules["gps_zero_threshold_lat"] and
                abs(lon) < self.cleansing_rules["gps_zero_threshold_lon"]):
                cleansing_flags.append(CleansingFlag.GPS_ZEROED)
                # Option: interpolate, or set to None, or use last known good.
                # For this exercise, we flag it and keep the 0.0, 0.0.
                logger.debug(f"GPS zeroed detected for {cleansed_data['truck_id']} at {cleansed_data['timestamp']}. Flagged.")
            
            # Check for general invalid range (e.g., >90 lat or >180 lon)
            if not (-90 <= lat <= 90 and -180 <= lon <= 180):
                cleansing_flags.append(CleansingFlag.GPS_INVALID_RANGE)
                logger.warning(f"Invalid GPS range ({lat}, {lon}) for truck {cleansed_data['truck_id']}. Flagged.")
                # Option: Replace with previous valid, or None
                lat, lon = 0.0, 0.0 # Default to 0,0 if invalid range

            cleansed_data["latitude"] = lat
            cleansed_data["longitude"] = lon

        except (ValueError, TypeError):
            cleansing_flags.append(CleansingFlag.MISSING_FIELD)
            cleansing_flags.append(CleansingFlag.GPS_INVALID_RANGE)
            logger.warning(f"Invalid GPS data '{parsed_raw_data.get('latitude_str')}, {parsed_raw_data.get('longitude_str')}' for truck {cleansed_data['truck_id']}. Flagged.")


        # --- Parse and Validate Fuel Level ---
        try:
            fuel = float(parsed_raw_data.get("fuel_level_str", "0.0"))
            if not (self.cleansing_rules["fuel_level_min"] <= fuel <= self.cleansing_rules["fuel_level_max"]):
                cleansing_flags.append(CleansingFlag.FUEL_LEVEL_INVALID)
                logger.warning(f"Invalid fuel level '{fuel}' for truck {cleansed_data['truck_id']}. Flagged.")
                fuel = max(self.cleansing_rules["fuel_level_min"], min(fuel, self.cleansing_rules["fuel_level_max"])) # Clamp
            cleansed_data["fuel_level_percent"] = fuel
        except (ValueError, TypeError):
            cleansing_flags.append(CleansingFlag.MISSING_FIELD)
            cleansing_flags.append(CleansingFlag.FUEL_LEVEL_INVALID)
            logger.warning(f"Invalid fuel level data '{parsed_raw_data.get('fuel_level_str')}' for truck {cleansed_data['truck_id']}. Flagged.")


        # --- Parse and Validate Engine Temperature ---
        try:
            temp = float(parsed_raw_data.get("engine_temp_str", "0.0"))
            if not (self.cleansing_rules["engine_temp_min_c"] <= temp <= self.cleansing_rules["engine_temp_max_c"]):
                cleansing_flags.append(CleansingFlag.ENGINE_TEMP_INVALID)
                logger.warning(f"Invalid engine temp '{temp}' for truck {cleansed_data['truck_id']}. Flagged.")
                temp = max(self.cleansing_rules["engine_temp_min_c"], min(temp, self.cleansing_rules["engine_temp_max_c"])) # Clamp
            cleansed_data["engine_temp_celsius"] = temp
        except (ValueError, TypeError):
            cleansing_flags.append(CleansingFlag.MISSING_FIELD)
            cleansing_flags.append(CleansingFlag.ENGINE_TEMP_INVALID)
            logger.warning(f"Invalid engine temp data '{parsed_raw_data.get('engine_temp_str')}' for truck {cleansed_data['truck_id']}. Flagged.")

        # --- Handle Alert Code (Simple Passthrough for cleansing, normalization will standardize) ---
        alert_code_raw = parsed_raw_data.get("alert_code_str", None)
        if alert_code_raw and alert_code_raw.strip() != self.cleansing_rules["missing_field_placeholder"]:
            cleansed_data["engine_alert_code"] = alert_code_raw.strip()
        else:
            cleansed_data["engine_alert_code"] = None

        # Finalize flags
        cleansed_data["cleansing_flags"] = sorted(list(set(cleansing_flags))) # Remove duplicates and sort

        logger.debug(f"Cleansed data for {cleansed_data['truck_id']}: {cleansed_data}")
        return cleansed_data
