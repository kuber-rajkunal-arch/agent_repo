"""
Defines data models (schemas) for the IoT data processing system.
These models ensure data consistency across different stages of the pipeline.
"""

from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional, Dict, Any

@dataclass
class RawSensorData:
    """
    Represents raw text data received directly from an IoT sensor.
    TR-IOT-001: Output Name: Acknowledged Raw Data
    """
    data: str
    received_timestamp: datetime = field(default_factory=datetime.utcnow)
    source_identifier: Optional[str] = None # e.g., IP address, gateway ID

@dataclass
class StandardSensorData:
    """
    Represents sensor data transformed into the company\'s standard schema.
    TR-IOT-002: Output Name: Normalized Sensor Data
    """
    device_id: str
    timestamp: datetime
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    fuel_level: Optional[int] = None  # Percentage (0-100)
    engine_temperature: Optional[int] = None # e.g., Celsius or Fahrenheit
    engine_rpm: Optional[int] = None
    status: str = "OK" # e.g., OK, WARNING, CRITICAL
    raw_data_ref: Optional[str] = None # Reference to the original raw data or its ID
    additional_info: Dict[str, Any] = field(default_factory=dict) # For any extra fields

    def to_dict(self) -> Dict[str, Any]:
        """Converts the dataclass instance to a dictionary."""
        data_dict = {
            "device_id": self.device_id,
            "timestamp": self.timestamp.isoformat() if self.timestamp else None,
            "latitude": self.latitude,
            "longitude": self.longitude,
            "fuel_level": self.fuel_level,
            "engine_temperature": self.engine_temperature,
            "engine_rpm": self.engine_rpm,
            "status": self.status,
            "raw_data_ref": self.raw_data_ref,
            "additional_info": self.additional_info
        }
        # Remove None values for cleaner output if desired, or keep them.
        return {k: v for k, v in data_dict.items() if v is not None}

@dataclass
class EngineAlert:
    """
    Represents an alert generated due to an engine-related issue.
    TR-IOT-003: Output Name: Formatted Engine Alert (before formatting)
    """
    device_id: str
    timestamp: datetime
    alert_type: str # e.g., "engine_temperature_high", "fuel_level_low"
    alert_value: Any # The value that triggered the alert
    threshold: Any # The threshold that was crossed
    current_location: Optional[Dict[str, float]] = None # Lat/Lon
    severity: str = "CRITICAL" # e.g., WARNING, CRITICAL
    normalized_data_ref: Optional[StandardSensorData] = None # Reference to the normalized data

    def to_dict(self) -> Dict[str, Any]:
        """Converts the dataclass instance to a dictionary."""
        return {
            "device_id": self.device_id,
            "timestamp": self.timestamp.isoformat(),
            "alert_type": self.alert_type,
            "alert_value": self.alert_value,
            "threshold": self.threshold,
            "current_location": self.current_location,
            "severity": self.severity
        }

@dataclass
class LocationUpdate:
    """
    Represents a significant location update for a vehicle.
    TR-IOT-004: Output Name: Formatted Location Update (before formatting)
    """
    device_id: str
    timestamp: datetime
    latitude: float
    longitude: float
    normalized_data_ref: Optional[StandardSensorData] = None # Reference to the normalized data

    def to_dict(self) -> Dict[str, Any]:
        """Converts the dataclass instance to a dictionary."""
        return {
            "device_id": self.device_id,
            "timestamp": self.timestamp.isoformat(),
            "latitude": self.latitude,
            "longitude": self.longitude
        }
