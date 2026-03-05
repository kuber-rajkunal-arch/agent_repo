"""
Data Cleaning module for the IoT Sensor Data Gateway.

This module processes ingested raw sensor data to identify and clean "noisy"
data, as per FR-GW-002.
"""

import logging
import re
from typing import Optional, Dict, Any

from project_name.src.config import AppConfig

logger = logging.getLogger(__name__)

class DataCleaner:
    """
    Cleans raw sensor data by identifying and correcting noisy segments.

    Applies predefined patterns and cleaning algorithms to ensure data quality.
    """

    def __init__(self):
        """
        Initializes the DataCleaner with cleaning rules from AppConfig.
        """
        self.noise_patterns = AppConfig.NOISE_PATTERNS
        self.cleaning_defaults = AppConfig.CLEANING_DEFAULTS
        self.engine_temp_min = AppConfig.ENGINE_TEMP_MIN_C
        self.engine_temp_max = AppConfig.ENGINE_TEMP_MAX_C
        logger.info("DataCleaner initialized with configured rules.")

    def clean_raw_data(self, raw_data_text: str) -> str:
        """
        Processes ingested raw sensor data to identify and clean noisy data.

        Args:
            raw_data_text: The raw sensor data string received from the ingestion stage.

        Returns:
            A cleaned version of the raw data text.
            If noise is detected and corrected, the corrected values are
            injected into the string. If no noise, the original string is returned.
        """
        if not raw_data_text:
            logger.warning("Received empty raw_data_text for cleaning.")
            return ""

        cleaned_data = raw_data_text
        original_data = raw_data_text # For logging comparisons

        # --- GPS Noise Cleaning ---
        # Example: replacing "GPS:LOST" with default coordinates
        for pattern in self.noise_patterns.get("gps_noise", []):
            if pattern.search(cleaned_data):
                logger.debug(f"GPS noise detected: '{pattern.pattern}' in {cleaned_data[:100]}...")
                # Assuming GPS data is structured like "LAT:XX.XX|LON:YY.YY"
                # This is a simplification; a more robust parser would be needed
                # if data structures are complex or variable.
                default_lat = self.cleaning_defaults["default_latitude"]
                default_lon = self.cleaning_defaults["default_longitude"]

                # Replace any GPS indications with default valid ones
                cleaned_data = re.sub(r"LAT:(-?\d+\.\d+)|LAT:(?:LOST|INVALID|NO_SIGNAL)", f"LAT:{default_lat:.4f}", cleaned_data, flags=re.IGNORECASE)
                cleaned_data = re.sub(r"LON:(-?\d+\.\d+)|LON:(?:LOST|INVALID|NO_SIGNAL)", f"LON:{default_lon:.4f}", cleaned_data, flags=re.IGNORECASE)
                # If there's a generic GPS tag like "GPS:LOST" without specific LAT/LON
                cleaned_data = re.sub(r"GPS:(?:LOST|INVALID|NO_SIGNAL)", f"LAT:{default_lat:.4f}|LON:{default_lon:.4f}", cleaned_data, flags=re.IGNORECASE)

                logger.info(f"Corrected GPS noise for sensor data. Defaulted to ({default_lat}, {default_lon}).")
                break # Assume one type of GPS noise per message for simplicity

        # --- Erratic Engine Temperature Cleaning ---
        # Example: replacing out-of-range temperature with a default
        for pattern in self.noise_patterns.get("erratic_temp", []):
            match = pattern.search(cleaned_data)
            if match:
                try:
                    temp_str = match.group(1)
                    temp_value = float(temp_str)
                    if not (self.engine_temp_min <= temp_value <= self.engine_temp_max):
                        logger.warning(
                            f"Erratic engine temperature detected: {temp_value}°C "
                            f"(expected range {self.engine_temp_min}-{self.engine_temp_max}°C) "
                            f"in {cleaned_data[:100]}..."
                        )
                        default_temp = self.cleaning_defaults["default_engine_temp"]
                        cleaned_data = cleaned_data.replace(f"ENGINE_TEMP:{temp_str}", f"ENGINE_TEMP:{default_temp:.1f}")
                        logger.info(f"Corrected erratic engine temperature to {default_temp}°C.")
                    break # Assume one engine temp reading per message
                except (ValueError, IndexError):
                    logger.error(f"Failed to parse engine temperature from '{match.group(0)}'.")

        if cleaned_data != original_data:
            logger.debug(f"Data cleaned. Original: {original_data[:50]}..., Cleaned: {cleaned_data[:50]}...")
        else:
            logger.debug(f"No cleaning required for data: {cleaned_data[:50]}...")

        return cleaned_data
