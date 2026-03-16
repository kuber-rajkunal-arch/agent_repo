import logging
import os
from datetime import datetime

def setup_logging(log_file_path: str = None, level: int = logging.INFO) -> logging.Logger:
    """
    Sets up and returns a logger instance.

    Args:
        log_file_path (str, optional): Path to the log file. If None, logs only to console.
                                       Defaults to None.
        level (int, optional): Logging level (e.g., logging.INFO, logging.DEBUG).
                               Defaults to logging.INFO.

    Returns:
        logging.Logger: Configured logger instance.
    """
    logger = logging.getLogger("iot_data_processor")
    logger.setLevel(level)

    # Prevent adding multiple handlers if called multiple times
    if not logger.handlers:
        # Console handler
        console_handler = logging.StreamHandler()
        console_handler.setLevel(level)
        formatter = logging.Formatter(
            "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        )
        console_handler.setFormatter(formatter)
        logger.addHandler(console_handler)

        # File handler (optional)
        if log_file_path:
            # Ensure log directory exists
            log_dir = os.path.dirname(log_file_path)
            if log_dir and not os.path.exists(log_dir):
                os.makedirs(log_dir)

            file_handler = logging.FileHandler(log_file_path)
            file_handler.setLevel(level)
            file_handler.setFormatter(formatter)
            logger.addHandler(file_handler)

    return logger

# Initialize a default logger for the application
# This can be overridden or configured differently in main.py if needed
LOG_FILE_NAME = f"iot_processor_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
LOG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "logs")
DEFAULT_LOG_FILE_PATH = os.path.join(LOG_DIR, LOG_FILE_NAME)

# Ensure the log directory exists
if not os.path.exists(LOG_DIR):
    os.makedirs(LOG_DIR)

app_logger = setup_logging(DEFAULT_LOG_FILE_PATH)
