"""
Initializes the 'src' package for the IoT Sensor Data Gateway project.
"""
import logging
from project_name.src.config import AppConfig

# Configure logging at package initialization
logging.basicConfig(level=AppConfig.LOG_LEVEL, format=AppConfig.LOG_FORMAT)
logging.getLogger(__name__).addHandler(logging.NullHandler()) # Prevent double logging if root logger is configured elsewhere
