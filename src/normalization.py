"""
Normalization module for the IoT Sensor Data Gateway.

This module transforms cleaned sensor data from various manufacturers
into the company’s predefined standard data schema, as per FR-GW-003.
"""

import logging
import re
from typing import Dict, Any, Optional
from datetime import datetime

from project_name.src.config import AppConfig
from project_name.src.data_models import StandardSensorData

logger = logging.getLogger(__name__)

class Normalizer:
    """
    Transforms cleaned sensor data into the company's standard data schema.

    Identifies the sensor source and applies specific mapping rules.
    """

    def __init__(self):
        """
        Initializes the Normalizer with manufacturer mappings from AppConfig.
        """
        self.manufacturer_mappings = AppConfig.MANUFACTURER_MAPPINGS
        logger.info("Normalizer initialized with manufacturer mappings.")

    def _identify_manufacturer(self, cleaned_data_text: str) -> str:
        """
        Identifies the manufacturer of the sensor data based on the text.

        Args:
            cleaned_data_text: The cleaned raw sensor data string.

        Returns:
            The identified manufacturer as a string (e.g., "BOSCH", "GARMIN"),
            or "UNKNOWN" if no specific manufacturer can be identified.
        """
        # A simple approach: check for manufacturer keywords at the start of the string
        # In a real system, this might involve a more robust header or metadata parsing.
        for manufacturer in self.manufacturer_mappings.keys():
            if cleaned_data_text.upper().startswith(f"{manufacturer}|"):
                return manufacturer
        logger.warning(f"Could not identify manufacturer for data: {cleaned_data_text[:50]}...")
        return "GENERIC" # Fallback to a generic parser if available

    def normalize_data(self, cleaned_data_text: str) -> Optional[StandardSensorData]:
        """
        Transforms cleaned sensor data into a StandardSensorData object.

        Args:
            cleaned_data_text: The cleaned raw sensor data string.

        Returns:
            A StandardSensorData object if normalization is successful,
            otherwise None.
        """
        if not cleaned_data_text:
            logger.warning("Received empty cleaned_data_text for normalization.")
            return None

        manufacturer = self._identify_manufacturer(cleaned_data_text)
        mappings = self.manufacturer_mappings.get(manufacturer, self.manufacturer_mappings.get("GENERIC"))

        if not mappings:
            logger.error(f"No mapping rules found for manufacturer: {manufacturer}. Skipping normalization.")
            return None

        extracted_data: Dict[str, Any] = {"manufacturer": manufacturer}
        raw_tags: Dict[str, Any] = {} # To capture data not directly mapped

        # Iterate through the mapping rules and extract data using regex
        for standard_field, pattern_str in mappings.items():
            if standard_field == "_parser":
                continue # Handle custom parsers separately
            
            # Use regex to find and extract the value
            match = re.search(pattern_str, cleaned_data_text)
            if match and len(match.groups()) > 0:
                value = match.group(1).strip()
                extracted_data[standard_field] = value
                logger.debug(f"Extracted {standard_field}: {value} for {manufacturer}")
            else:
                logger.debug(f"No match for {standard_field} using pattern '{pattern_str}' for manufacturer {manufacturer}")
                # If a field is explicitly defined in mappings but not found,
                # it means it's not present in this specific raw data, which is fine.
                # However, if we want to capture all "unmapped" raw fields,
                # a more sophisticated tokenization of the raw string would be needed.

        # Apply custom parsers if defined
        custom_parsers = mappings.get("_parser", {})
        for field, parser_func in custom_parsers.items():
            if field in extracted_data:
                try:
                    extracted_data[field] = parser_func(extracted_data[field])
                except Exception as e:
                    logger.error(f"Error applying custom parser for field '{field}': {e}")
                    extracted_data[field] = None # Clear potentially invalid data

        # Type conversion and validation for StandardSensorData
        try:
            sensor_id = str(extracted_data.get("sensor_id"))
            timestamp = extracted_data.get("timestamp")
            if not isinstance(timestamp, datetime):
                # Attempt default parsing if custom parser failed or was absent
                try:
                    # Common Unix timestamp
                    if isinstance(timestamp, str) and timestamp.isdigit():
                        timestamp = datetime.fromtimestamp(int(timestamp))
                    elif isinstance(timestamp, (int, float)):
                        timestamp = datetime.fromtimestamp(timestamp)
                    else:
                        raise ValueError("Timestamp format not recognized.")
                except (ValueError, TypeError):
                    logger.error(f"Failed to parse timestamp '{timestamp}'. Using current time.")
                    timestamp = datetime.now()

            # Convert other fields to their target types, handling missing values
            latitude = self._safe_float_conversion(extracted_data.get("latitude"))
            longitude = self._safe_float_conversion(extracted_data.get("longitude"))
            altitude = self._safe_float_conversion(extracted_data.get("altitude"))
            engine_temp_celsius = self._safe_float_conversion(extracted_data.get("engine_temp_celsius"))
            oil_pressure_psi = self._safe_float_conversion(extracted_data.get("oil_pressure_psi"))
            fuel_level_percent = self._safe_float_conversion(extracted_data.get("fuel_level_percent"))
            engine_rpm = self._safe_int_conversion(extracted_data.get("engine_rpm"))
            location_accuracy = extracted_data.get("location_accuracy")
            engine_status = extracted_data.get("engine_status")

            normalized_data = StandardSensorData(
                sensor_id=sensor_id,
                timestamp=timestamp,
                manufacturer=manufacturer,
                latitude=latitude,
                longitude=longitude,
                altitude=altitude,
                location_accuracy=location_accuracy,
                engine_temp_celsius=engine_temp_celsius,
                oil_pressure_psi=oil_pressure_psi,
                fuel_level_percent=fuel_level_percent,
                engine_rpm=engine_rpm,
                engine_status=engine_status,
                raw_data_tags=raw_tags if raw_tags else None # Only include if not empty
            )
            logger.info(f"Successfully normalized data for sensor_id: {sensor_id}")
            return normalized_data

        except KeyError as e:
            logger.error(f"Missing crucial field during normalization for {manufacturer}: {e}. Data: {extracted_data}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error during normalization for {manufacturer}: {e}. Data: {extracted_data}")
            return None

    def _safe_float_conversion(self, value: Any) -> Optional[float]:
        """Safely converts a value to float, returning None on failure."""
        if value is None:
            return None
        try:
            return float(value)
        except (ValueError, TypeError):
            logger.debug(f"Could not convert '{value}' to float.")
            return None

    def _safe_int_conversion(self, value: Any) -> Optional[int]:
        """Safely converts a value to int, returning None on failure."""
        if value is None:
            return None
        try:
            return int(value)
        except (ValueError, TypeError):
            logger.debug(f"Could not convert '{value}' to int.")
            return None
