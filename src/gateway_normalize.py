"""
Module for normalizing cleansed sensor data to a standard schema.
Implements FR-GW-003 and TR-GW-003.
"""

import logging
import datetime
from typing import Dict, Any, Callable, List, Type, cast

from project_name.src.gateway_schemas import (
    CleansedSensorData,
    StandardSensorData,
    STANDARD_SCHEMA_DEFINITION,
    EngineAlertCode,
    CleansingFlag
)

logger = logging.getLogger(__name__)

class SensorDataNormalizer:
    """
    Transforms cleansed sensor data from various manufacturers to the company’s
    standardized data schema. Includes schema validation.
    """

    def __init__(self,
                 standard_schema: Dict[str, Type] = STANDARD_SCHEMA_DEFINITION,
                 transformation_mappings: Optional[Dict[str, Dict[str, Any]]] = None):
        """
        Initializes the SensorDataNormalizer.

        Args:
            standard_schema (Dict[str, Type]): The target standard data schema definition.
            transformation_mappings (Optional[Dict[str, Dict[str, Any]]]):
                A dictionary where keys are manufacturer names (e.g., "BOSCH", "GARMIN")
                and values are mappings specific to that manufacturer.
                Each mapping dict can contain:
                    - 'field_map': A dict for renaming fields from cleansed to standard schema.
                    - 'alert_map': A dict for standardizing manufacturer-specific alert codes.
        """
        self.standard_schema = standard_schema
        self.transformation_mappings = transformation_mappings if transformation_mappings is not None else self._default_transformation_mappings()
        logger.info("SensorDataNormalizer initialized.")

    def _default_transformation_mappings(self) -> Dict[str, Dict[str, Any]]:
        """
        Defines default transformation mappings for known manufacturers.
        In a real system, these would be loaded from configuration or a database.
        """
        # Assuming a common structure for cleansed data, so field_map might be minimal
        # The main differences might be in how alert codes are represented.
        return {
            "BOSCH": {
                "field_map": {
                    "manufacturer": "manufacturer",
                    "timestamp": "timestamp_utc",
                    "truck_id": "truck_id",
                    "latitude": "latitude",
                    "longitude": "longitude",
                    "fuel_level_percent": "fuel_level_percent",
                    "engine_temp_celsius": "engine_temp_celsius",
                    "engine_alert_code": "engine_alert_code",
                    "cleansing_flags": "cleansing_flags",
                },
                "alert_map": {
                    "NORMAL": None,
                    "WARN_OIL": EngineAlertCode.LOW_OIL_PRESSURE,
                    "HIGH_ENG_TEMP": EngineAlertCode.HIGH_ENGINE_TEMPERATURE,
                    "BATT_CRIT": EngineAlertCode.CRITICAL_BATTERY,
                    "SERVICE_DUE": EngineAlertCode.MAINTENANCE_REQUIRED,
                    "DEFAULT": EngineAlertCode.UNKNOWN_ALERT # Catch-all
                }
            },
            "GARMIN": {
                "field_map": {
                    "manufacturer": "manufacturer",
                    "timestamp": "timestamp_utc",
                    "truck_id": "truck_id",
                    "latitude": "latitude",
                    "longitude": "longitude",
                    "fuel_level_percent": "fuel_level_percent",
                    "engine_temp_celsius": "engine_temp_celsius",
                    "engine_alert_code": "engine_alert_code",
                    "cleansing_flags": "cleansing_flags",
                },
                "alert_map": {
                    "OK": None,
                    "LOW_OIL_PRESSURE": EngineAlertCode.LOW_OIL_PRESSURE,
                    "TEMP_EXCEEDED": EngineAlertCode.HIGH_ENGINE_TEMPERATURE,
                    "BATTERY_LOW": EngineAlertCode.CRITICAL_BATTERY,
                    "INSPECT_ENGINE": EngineAlertCode.MAINTENANCE_REQUIRED,
                    "DEFAULT": EngineAlertCode.UNKNOWN_ALERT
                }
            },
            # Default mapping for unknown manufacturers (best effort)
            "DEFAULT": {
                "field_map": {
                    "manufacturer": "manufacturer",
                    "timestamp": "timestamp_utc",
                    "truck_id": "truck_id",
                    "latitude": "latitude",
                    "longitude": "longitude",
                    "fuel_level_percent": "fuel_level_percent",
                    "engine_temp_celsius": "engine_temp_celsius",
                    "engine_alert_code": "engine_alert_code",
                    "cleansing_flags": "cleansing_flags",
                },
                "alert_map": {
                    "NORMAL": None,
                    "OK": None,
                    "DEFAULT": EngineAlertCode.UNKNOWN_ALERT # All unknown alerts map to this
                }
            }
        }

    def _apply_manufacturer_mapping(self, cleansed_data: CleansedSensorData) -> Dict[str, Any]:
        """
        Applies manufacturer-specific field mapping and alert code standardization.
        """
        manufacturer = cleansed_data.get("manufacturer", "UNKNOWN").upper()
        mapping = self.transformation_mappings.get(manufacturer, self.transformation_mappings["DEFAULT"])

        transformed_data: Dict[str, Any] = {}
        field_map = mapping.get("field_map", {})
        alert_map = mapping.get("alert_map", {})

        # Apply field mapping and type conversions
        for cleansed_key, standard_key in field_map.items():
            value = cleansed_data.get(cleansed_key)
            transformed_data[standard_key] = value
        
        # Special handling for sensor_id (e.g., combine truck_id and timestamp)
        transformed_data["sensor_id"] = f"{cleansed_data['truck_id']}-{cleansed_data['timestamp'].isoformat()}"

        # Standardize engine alert code
        original_alert = cleansed_data.get("engine_alert_code")
        if original_alert:
            standardized_alert = alert_map.get(original_alert.upper(), alert_map.get("DEFAULT"))
            transformed_data["engine_alert_code"] = standardized_alert
            transformed_data["is_engine_alert"] = bool(standardized_alert) # True if an alert code is present
        else:
            transformed_data["engine_alert_code"] = None
            transformed_data["is_engine_alert"] = False

        # Determine if it's a location update (always true if valid GPS and not flagged as temporary loss)
        transformed_data["is_location_update"] = (
            cleansed_data["latitude"] != 0.0 or cleansed_data["longitude"] != 0.0 # Basic check for non-zero coordinates
            ) and (CleansingFlag.GPS_TEMPORARY_LOSS not in cleansed_data["cleansing_flags"]) # Or any other criteria for invalid location

        return transformed_data

    def _validate_schema(self, normalized_data: Dict[str, Any]) -> StandardSensorData:
        """
        Validates the normalized data against the standard schema definition.
        Raises ValueError if validation fails.
        """
        # Check for presence of all required fields
        for field, expected_type in self.standard_schema.items():
            if field not in normalized_data:
                logger.error(f"Schema validation failed: Missing required field '{field}'. Data: {normalized_data}")
                raise ValueError(f"Missing required field: {field}")

            # Check for type compliance (basic check, more robust type checking for Optional types)
            actual_value = normalized_data[field]
            if not isinstance(actual_value, expected_type):
                # Handle Optional types - check if it's None or the inner type
                if hasattr(expected_type, '__origin__') and expected_type.__origin__ is Optional:
                    inner_type = expected_type.__args__[0]
                    if actual_value is not None and not isinstance(actual_value, inner_type):
                        logger.warning(f"Schema type mismatch for field '{field}'. Expected {expected_type}, got {type(actual_value)}. Data: {normalized_data}")
                        # For robustness, we might try to coerce or just warn
                elif not isinstance(actual_value, expected_type):
                    logger.error(f"Schema validation failed: Field '{field}' has wrong type. Expected {expected_type}, got {type(actual_value)}. Data: {normalized_data}")
                    raise TypeError(f"Field '{field}' has wrong type: Expected {expected_type}, got {type(actual_value)}")

        # Ensure no extra fields beyond standard schema (optional, but good for strictness)
        for field in normalized_data:
            if field not in self.standard_schema:
                logger.warning(f"Extra field '{field}' found in normalized data, not part of standard schema. Data: {normalized_data}")
                # Option: remove extra fields if strict compliance is needed
                # del normalized_data[field]

        return cast(StandardSensorData, normalized_data) # Cast to TypedDict for type checking benefits

    def normalize(self, cleansed_data: CleansedSensorData) -> StandardSensorData:
        """
        Normalizes cleansed sensor data to the standard schema.

        Args:
            cleansed_data (CleansedSensorData): The data after cleansing.

        Returns:
            StandardSensorData: The data transformed and validated against the
                                company's standard schema.

        Raises:
            ValueError: If the normalized data fails schema validation.
        """
        logger.debug(f"Normalizing cleansed data for truck {cleansed_data.get('truck_id')}")

        try:
            # Step 1: Apply manufacturer-specific mappings and transformations
            transformed_data = self._apply_manufacturer_mapping(cleansed_data)

            # Step 2: Validate the transformed data against the standard schema
            normalized_data = self._validate_schema(transformed_data)

            logger.debug(f"Successfully normalized data for truck {normalized_data['truck_id']}.")
            return normalized_data

        except (KeyError, ValueError, TypeError) as e:
            logger.error(f"Error during normalization for truck {cleansed_data.get('truck_id', 'UNKNOWN')}: {e}. "
                         f"Original cleansed data: {cleansed_data}")
            # Depending on policy, might re-raise, return None, or return a "failed" record.
            # For strictness, re-raise.
            raise
