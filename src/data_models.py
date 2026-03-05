"""
Data models for the IoT Sensor Data Gateway.

This module defines the standard data schema used throughout the gateway
for normalized sensor data and other related data structures.
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Optional, Dict, Any


@dataclass
class StandardSensorData:
    """
    Represents sensor data normalized to a standard company schema.
    This dataclass holds all relevant sensor readings after cleaning
    and normalization.
    """
    sensor_id: str
    timestamp: datetime
    manufacturer: str

    # Location Data
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    altitude: Optional[float] = None
    location_accuracy: Optional[str] = None # e.g., 'HIGH', 'MEDIUM', 'LOW'

    # Engine Data
    engine_temp_celsius: Optional[float] = None
    oil_pressure_psi: Optional[float] = None
    fuel_level_percent: Optional[float] = None
    engine_rpm: Optional[int] = None
    engine_status: Optional[str] = None # e.g., 'OK', 'WARNING', 'ALERT'

    # Other data points can be added as needed
    # A generic field for manufacturer-specific data not yet standardized
    raw_data_tags: Optional[Dict[str, Any]] = None

    def to_dict(self) -> Dict[str, Any]:
        """Converts the StandardSensorData object to a dictionary."""
        data_dict = {
            "sensor_id": self.sensor_id,
            "timestamp": self.timestamp.isoformat(),
            "manufacturer": self.manufacturer,
        }
        if self.latitude is not None:
            data_dict["latitude"] = self.latitude
        if self.longitude is not None:
            data_dict["longitude"] = self.longitude
        if self.altitude is not None:
            data_dict["altitude"] = self.altitude
        if self.location_accuracy is not None:
            data_dict["location_accuracy"] = self.location_accuracy
        if self.engine_temp_celsius is not None:
            data_dict["engine_temp_celsius"] = self.engine_temp_celsius
        if self.oil_pressure_psi is not None:
            data_dict["oil_pressure_psi"] = self.oil_pressure_psi
        if self.fuel_level_percent is not None:
            data_dict["fuel_level_percent"] = self.fuel_level_percent
        if self.engine_rpm is not None:
            data_dict["engine_rpm"] = self.engine_rpm
        if self.engine_status is not None:
            data_dict["engine_status"] = self.engine_status
        if self.raw_data_tags:
            data_dict["raw_data_tags"] = self.raw_data_tags
        return data_dict