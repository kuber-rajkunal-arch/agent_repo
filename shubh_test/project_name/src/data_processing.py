"""
Module for cleaning and transforming raw IoT sensor data into a standard schema.
Corresponds to TR-IOT-002: Develop a processing component to clean "noisy" raw sensor
text data and transform it into the company\'s standard schema.
"""

import re
from datetime import datetime
from typing import Dict, Any, Optional, Tuple

from src.models import RawSensorData, StandardSensorData
from src.config import SENSOR_FORMATS, CLEANING_RULES
from src.logger import app_logger

def _parse_csv_data(raw_data_str: str, config: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """Parses CSV-like raw data based on configuration."""
    parts = raw_data_str.split(config["delimiter"])
    if len(parts) != len(config["fields"]):
        app_logger.warning(f"CSV parsing error: Mismatch in field count for '{raw_data_str}'. Expected {len(config['fields'])}, got {len(parts)}.")
        return None

    parsed_data = dict(zip(config["fields"], parts))
    return parsed_data

def _parse_key_value_data(raw_data_str: str, config: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """Parses key-value pair raw data based on configuration."""
    parts = raw_data_str.split(config["delimiter"])
    parsed_data: Dict[str, Any] = {}

    # Handle fixed fields first (e.g., device_id, timestamp)
    if len(parts) > len(config["fixed_fields"]):
        for i, field_name in enumerate(config["fixed_fields"]):
            parsed_data[field_name] = parts[i]
        remaining_parts = parts[len(config["fixed_fields"]):]
    else:
        app_logger.warning(f"Key-value parsing error: Not enough fixed fields for '{raw_data_str}'. Expected at least {len(config['fixed_fields'])}.")
        return None

    # Handle key-value pairs
    for part in remaining_parts:
        if config["kv_separator"] in part:
            key, value_str = part.split(config["kv_separator"], 1)
            key = key.strip()
            value_str = value_str.strip()

            if key in config["prefix_map"]:
                # Special handling for combined values like LOC:lat,lon
                target_fields = config["prefix_map"][key]
                sub_values = value_str.split(',')
                if len(sub_values) == len(target_fields):
                    for i, field_name in enumerate(target_fields):
                        parsed_data[field_name] = sub_values[i]
                else:
                    app_logger.warning(f"Key-value parsing error: Mismatch in sub-field count for '{key}:{value_str}'. Expected {len(target_fields)}, got {len(sub_values)}.")
            else:
                # Direct key-value mapping
                parsed_data[key] = value_str
        else:
            app_logger.warning(f"Key-value parsing error: Invalid key-value pair '{part}' in '{raw_data_str}'.")

    return parsed_data

def identify_source_and_parse(raw_data: RawSensorData) -> Optional[Dict[str, Any]]:
    """
    TR-IOT-002, Stage 2: Identifies the source sensor and parses its raw data structure.

    This function attempts to determine the format of the raw data based on a
    predefined set of sensor formats (e.g., by looking at a device ID prefix).
    It then parses the raw text into a dictionary.

    Args:
        raw_data (RawSensorData): The raw sensor data object.

    Returns:
        Optional[Dict[str, Any]]: A dictionary containing parsed data fields,
                                  or None if the format cannot be identified or parsed.
    """
    raw_text = raw_data.data
    device_id_prefix = raw_text.split(',')[0] if ',' in raw_text else raw_text.split(';')[0]

    for sensor_type, config in SENSOR_FORMATS.items():
        if device_id_prefix.startswith(sensor_type):
            app_logger.debug(f"Identified sensor type '{sensor_type}' for device '{device_id_prefix}'.")
            parsed_data = None
            if config["type"] == "csv":
                parsed_data = _parse_csv_data(raw_text, config)
            elif config["type"] == "key_value":
                parsed_data = _parse_key_value_data(raw_text, config)

            if parsed_data:
                # Add the identified sensor type and format config for later use
                parsed_data["_sensor_type"] = sensor_type
                parsed_data["_format_config"] = config
                return parsed_data
            else:
                app_logger.error(f"Failed to parse raw data '{raw_text[:100]}...' using format '{sensor_type}'.")
                return None

    app_logger.error(f"TR-IOT-002: Could not identify sensor source/format for raw data: '{raw_text[:100]}...'")
    return None

def clean_sensor_data(parsed_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    TR-IOT-002, Stage 3: Applies cleaning algorithms to filter out "noisy" data.

    This function iterates through the parsed data and applies predefined cleaning rules
    (e.g., range checks, format validation) to ensure data quality. Invalid data points
    might be corrected, flagged, or removed.

    Args:
        parsed_data (Dict[str, Any]): A dictionary of parsed sensor data.

    Returns:
        Dict[str, Any]: A dictionary with cleaned sensor data.
    """
    cleaned_data = parsed_data.copy()
    device_id = cleaned_data.get("device_id", "UNKNOWN_DEVICE")

    for field, rules in CLEANING_RULES.items():
        if field in cleaned_data:
            value = cleaned_data[field]
            original_value = value
            is_valid = True

            # Type conversion based on format config
            field_type = parsed_data.get("_format_config", {}).get("field_types", {}).get(field)
            if field_type == "float":
                try:
                    value = float(value)
                except (ValueError, TypeError):
                    is_valid = False
                    app_logger.warning(f"Device {device_id}: Invalid float for '{field}': '{original_value}'.")
            elif field_type == "int":
                try:
                    value = int(value)
                except (ValueError, TypeError):
                    is_valid = False
                    app_logger.warning(f"Device {device_id}: Invalid int for '{field}': '{original_value}'.")
            elif field_type == "datetime":
                try:
                    value = datetime.strptime(str(value), rules["format"])
                except (ValueError, TypeError):
                    is_valid = False
                    app_logger.warning(f"Device {device_id}: Invalid datetime format for '{field}': '{original_value}'. Expected '{rules['format']}'.")

            if not is_valid:
                if rules.get("default_on_invalid") is not None:
                    cleaned_data[field] = rules["default_on_invalid"]
                    app_logger.info(f"Device {device_id}: Corrected invalid '{field}' from '{original_value}' to default '{rules['default_on_invalid']}'.")
                else:
                    cleaned_data[field] = None # Or remove the field
                    app_logger.info(f"Device {device_id}: Removed invalid '{field}' with value '{original_value}'.")
                continue # Skip further checks for this field if already invalid

            # Range checks for numeric types
            if isinstance(value, (int, float)):
                if "min" in rules and value < rules["min"]:
                    is_valid = False
                    app_logger.warning(f"Device {device_id}: '{field}' value {value} below min {rules['min']}.")
                if "max" in rules and value > rules["max"]:
                    is_valid = False
                    app_logger.warning(f"Device {device_id}: '{field}' value {value} above max {rules['max']}.")

            if not is_valid:
                if rules.get("default_on_invalid") is not None:
                    cleaned_data[field] = rules["default_on_invalid"]
                    app_logger.info(f"Device {device_id}: Corrected out-of-range '{field}' from '{original_value}' to default '{rules['default_on_invalid']}'.")
                else:
                    cleaned_data[field] = None
                    app_logger.info(f"Device {device_id}: Removed out-of-range '{field}' with value '{original_value}'.")
            else:
                cleaned_data[field] = value # Update with converted/validated value

    app_logger.debug(f"TR-IOT-002: Cleaned data for device {device_id}.")
    return cleaned_data

def transform_to_standard_schema(cleaned_data: Dict[str, Any], raw_data_ref: str) -> Optional[StandardSensorData]:
    """
    TR-IOT-002, Stage 4: Converts cleaned data to the company\'s standard schema.

    This function maps the cleaned, parsed data fields to the `StandardSensorData`
    dataclass structure. It handles potential missing fields by setting them to None.

    Args:
        cleaned_data (Dict[str, Any]): A dictionary of cleaned sensor data.
        raw_data_ref (str): A reference to the original raw data (e.g., its content or ID).

    Returns:
        Optional[StandardSensorData]: An instance of `StandardSensorData`, or None if
                                      essential fields are missing.
    """
    device_id = cleaned_data.get("device_id")
    timestamp = cleaned_data.get("timestamp")

    if not device_id or not timestamp:
        app_logger.error(f"TR-IOT-002: Cannot transform to standard schema. Missing essential fields (device_id or timestamp) in cleaned data: {cleaned_data}.")
        return None

    try:
        standard_data = StandardSensorData(
            device_id=str(device_id),
            timestamp=timestamp,
            latitude=cleaned_data.get("latitude"),
            longitude=cleaned_data.get("longitude"),
            fuel_level=cleaned_data.get("fuel_level"),
            engine_temperature=cleaned_data.get("engine_temperature"),
            engine_rpm=cleaned_data.get("engine_rpm"),
            raw_data_ref=raw_data_ref,
            # Any other fields can go into additional_info if not part of the core schema
            additional_info={k: v for k, v in cleaned_data.items()
                             if k not in ["device_id", "timestamp", "latitude", "longitude",
                                          "fuel_level", "engine_temperature", "engine_rpm",
                                          "_sensor_type", "_format_config"]}
        )
        app_logger.info(f"TR-IOT-002: Transformed data for device '{device_id}' to standard schema.")
        return standard_data
    except Exception as e:
        app_logger.error(f"TR-IOT-002: Error transforming cleaned data to StandardSensorData for device '{device_id}': {e}. Data: {cleaned_data}")
        return None

def process_raw_sensor_data(raw_data: RawSensorData) -> Optional[StandardSensorData]:
    """
    TR-IOT-002: Orchestrates the full processing pipeline for raw sensor data.

    This function combines source identification, data cleaning, and schema transformation
    into a single, cohesive processing step.

    Args:
        raw_data (RawSensorData): The raw sensor data object received from ingestion.

    Returns:
        Optional[StandardSensorData]: The cleaned and transformed data in the standard schema,
                                      or None if processing fails at any stage.
    """
    app_logger.info(f"TR-IOT-002: Starting processing for raw data from '{raw_data.source_identifier}' (device: {raw_data.data.split(',')[0] if ',' in raw_data.data else raw_data.data.split(';')[0]}).")

    # Stage 2: Source Identification
    parsed_data = identify_source_and_parse(raw_data)
    if parsed_data is None:
        app_logger.error(f"TR-IOT-002: Failed source identification for raw data: '{raw_data.data[:100]}...'")
        return None

    # Stage 3: Data Cleaning
    cleaned_data = clean_sensor_data(parsed_data)
    if not cleaned_data: # If cleaning resulted in an empty dict or critical data loss
        app_logger.error(f"TR-IOT-002: Data cleaning resulted in unusable data for device '{parsed_data.get('device_id', 'UNKNOWN')}'.")
        return None

    # Stage 4: Data Transformation
    standard_data = transform_to_standard_schema(cleaned_data, raw_data.data)
    if standard_data is None:
        app_logger.error(f"TR-IOT-002: Failed to transform cleaned data to standard schema for device '{cleaned_data.get('device_id', 'UNKNOWN')}'.")
        return None

    app_logger.info(f"TR-IOT-002: Successfully processed raw data for device '{standard_data.device_id}'.")
    return standard_data

# Example usage (for demonstration, not part of the core pipeline logic)
if __name__ == "__main__":
    from src.data_ingestion import receive_raw_sensor_data

    app_logger.info("--- Demonstrating Data Processing (TR-IOT-002) ---")

    # Valid data for TRUCK_A
    raw_data_a_valid = receive_raw_sensor_data("TRUCK_A,2023-10-27T10:00:00Z,34.0522,-118.2437,85,200,1500", "Gateway-001")
    processed_data_a_valid = process_raw_sensor_data(raw_data_a_valid)
    if processed_data_a_valid:
        app_logger.info(f"Processed Data A (Valid): {processed_data_a_valid.to_dict()}")
    else:
        app_logger.error("Processing failed for valid data A.")

    print("-" * 50)

    # Data with invalid fuel level for TRUCK_A
    raw_data_a_invalid_fuel = receive_raw_sensor_data("TRUCK_A,2023-10-27T10:01:00Z,34.0523,-118.2438,105,205,1550", "Gateway-001")
    processed_data_a_invalid_fuel = process_raw_sensor_data(raw_data_a_invalid_fuel)
    if processed_data_a_invalid_fuel:
        app_logger.info(f"Processed Data A (Invalid Fuel): {processed_data_a_invalid_fuel.to_dict()}")
    else:
        app_logger.error("Processing failed for invalid fuel data A.")

    print("-" * 50)

    # Valid data for TRUCK_B
    raw_data_b_valid = receive_raw_sensor_data("TRUCK_B,2023-10-27T10:00:05Z,LOC:34.0525,-118.2440;FUEL:84;ENG:201,1510", "Gateway-002")
    processed_data_b_valid = process_raw_sensor_data(raw_data_b_valid)
    if processed_data_b_valid:
        app_logger.info(f"Processed Data B (Valid): {processed_data_b_valid.to_dict()}")
    else:
        app_logger.error("Processing failed for valid data B.")

    print("-" * 50)

    # Data with missing parts for TRUCK_B
    raw_data_b_incomplete = receive_raw_sensor_data("TRUCK_B,2023-10-27T10:00:10Z,LOC:34.0526;FUEL:90", "Gateway-002")
    processed_data_b_incomplete = process_raw_sensor_data(raw_data_b_incomplete)
    if processed_data_b_incomplete:
        app_logger.info(f"Processed Data B (Incomplete): {processed_data_b_incomplete.to_dict()}")
    else:
        app_logger.error("Processing failed for incomplete data B.")

    print("-" * 50)

    # Unknown sensor type
    raw_data_unknown = receive_raw_sensor_data("UNKNOWN_TRUCK,2023-10-27T10:00:15Z,10,20,30", "Gateway-003")
    processed_data_unknown = process_raw_sensor_data(raw_data_unknown)
    if processed_data_unknown:
        app_logger.info(f"Processed Data (Unknown): {processed_data_unknown.to_dict()}")
    else:
        app_logger.error("Processing failed for unknown sensor type.")
