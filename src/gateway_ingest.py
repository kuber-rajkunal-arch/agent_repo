"""
Module for ingesting raw sensor data.
Implements FR-GW-001 and TR-GW-001.
"""

import collections
import logging
from typing import List, Optional

# Configure logging for the module
logger = logging.getLogger(__name__)

class SensorDataIngestor:
    """
    Responsible for receiving raw sensor text data and temporarily buffering it.
    This simulates the initial data reception from IoT sensors.
    """

    def __init__(self, buffer_max_size: int = 1000):
        """
        Initializes the SensorDataIngestor.

        Args:
            buffer_max_size (int): The maximum number of raw sensor data strings
                                   to hold in the internal buffer. Older items
                                   are discarded if buffer exceeds this size.
        """
        self.buffer: collections.deque[str] = collections.deque(maxlen=buffer_max_size)
        logger.info(f"SensorDataIngestor initialized with buffer max size: {buffer_max_size}")

    def ingest_raw_data(self, raw_data_text: str) -> None:
        """
        Ingests a single raw sensor data string and adds it to the internal buffer.

        Args:
            raw_data_text (str): The raw text string received from an IoT sensor.
        """
        if not isinstance(raw_data_text, str) or not raw_data_text.strip():
            logger.warning(f"Attempted to ingest invalid or empty raw data: '{raw_data_text}'")
            return

        self.buffer.append(raw_data_text)
        logger.debug(f"Ingested raw data (first 50 chars): '{raw_data_text[:50]}'")
        if len(self.buffer) == self.buffer.maxlen:
            logger.warning(f"Ingestor buffer is full ({self.buffer.maxlen} items). "
                           "Oldest items are being automatically discarded.")

    def get_buffered_data(self, count: Optional[int] = None) -> List[str]:
        """
        Retrieves a specified number of items from the buffer, or all if count is None.
        Retrieved items are removed from the buffer.

        Args:
            count (Optional[int]): The maximum number of items to retrieve.
                                   If None, all current items are retrieved.

        Returns:
            List[str]: A list of raw sensor data strings that were in the buffer.
        """
        if not self.buffer:
            logger.debug("Attempted to retrieve data from an empty buffer.")
            return []

        retrieved_items = []
        num_to_retrieve = count if count is not None else len(self.buffer)
        
        for _ in range(min(num_to_retrieve, len(self.buffer))):
            retrieved_items.append(self.buffer.popleft())

        logger.info(f"Retrieved {len(retrieved_items)} items from the buffer. "
                    f"Buffer now has {len(self.buffer)} items.")
        return retrieved_items

    def __len__(self) -> int:
        """Returns the current number of items in the buffer."""
        return len(self.buffer)

    def __bool__(self) -> bool:
        """Returns True if the buffer is not empty, False otherwise."""
        return bool(self.buffer)

