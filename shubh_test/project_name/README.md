# Real-time IoT Data Processing for Logistics

This project implements a real-time IoT data processing pipeline for logistics, focusing on receiving, cleaning, transforming, and routing sensor data from delivery trucks. The system is designed to handle updates related to location, fuel, and engine health, and to trigger alerts for critical events.

The implementation strictly adheres to the provided Technical Requirement Document (TRD) and uses only standard Python libraries, ensuring a production-quality, scalable, and readable codebase.

## Project Structure

```
project_name/
├── src/
│   ├── __init__.py
│   ├── config.py             # Centralized configuration settings
│   ├── logger.py             # Custom logging utility
│   ├── models.py             # Data models (dataclasses) for the pipeline
│   ├── data_ingestion.py     # Implements TR-IOT-001: Raw data reception
│   ├── data_processing.py    # Implements TR-IOT-002: Data cleaning and transformation
│   ├── data_routing.py       # Implements TR-IOT-003 & TR-IOT-004: Alert and update routing
│   └── main.py               # Orchestrates the entire pipeline flow
├── tests/
│   ├── test_data_ingestion.py
│   ├── test_data_processing.py
│   └── test_data_routing.py
├── data/                     # Placeholder for sample data or output files
├── logs/                     # Directory for log files (created at runtime)
├── requirements.txt          # Project dependencies (none beyond standard library)
├── pyproject.toml            # Project metadata and build configuration
├── README.md                 # This README file
├── LICENSE                   # Project license
└── .gitignore                # Git ignore rules
```

## Technical Requirements Implemented

The system addresses the following technical requirements:

*   **TR-IOT-001: Sensor Data Ingestion**
    *   **Objective:** Receive raw text data from IoT sensors (location, fuel, engine health).
    *   **Implementation:** The `data_ingestion.py` module provides a `receive_raw_sensor_data` function that simulates receiving raw text and acknowledging it by encapsulating it in a `RawSensorData` object with a reception timestamp.

*   **TR-IOT-002: Data Cleaning and Transformation**
    *   **Objective:** Clean "noisy" raw sensor text data and transform it into the company\'s standard schema.
    *   **Implementation:** The `data_processing.py` module contains functions for:
        *   `identify_source_and_parse`: Determines sensor type and parses raw text based on `config.py` definitions.
        *   `clean_sensor_data`: Applies configured cleaning rules (e.g., range checks, type conversions) to filter out invalid or noisy data.
        *   `transform_to_standard_schema`: Maps cleaned data to the `StandardSensorData` dataclass.
        *   `process_raw_sensor_data`: Orchestrates these steps.

*   **TR-IOT-003: Engine Alert Routing**
    *   **Objective:** Detect "Engine Alerts" from normalized sensor data and transmit them to the Maintenance Agent.
    *   **Implementation:** The `data_routing.py` module includes:
        *   `detect_engine_alert`: Applies criteria from `config.py` (e.g., high engine temperature, low fuel) to `StandardSensorData`.
        *   `format_engine_alert`: Formats the detected alert into a JSON string suitable for the Maintenance Agent.
        *   `transmit_engine_alert`: Simulates transmission to the Maintenance Agent\'s system.

*   **TR-IOT-004: Location Update Routing**
    *   **Objective:** Detect "Location Updates" from normalized sensor data and transmit them to the Customer Tracking Agent.
    *   **Implementation:** Also in `data_routing.py`:
        *   `detect_location_update`: Identifies valid location data in `StandardSensorData` as an update.
        *   `format_location_update`: Formats the location data into a JSON string for the Customer Tracking Agent.
        *   `transmit_location_update`: Simulates transmission to the Customer Tracking Agent\'s system.
        *   `route_normalized_data`: Orchestrates both alert and location routing.

## Key Design Principles

*   **Modularity:** The system is broken down into logical modules (`data_ingestion`, `data_processing`, `data_routing`, `models`, `config`, `logger`) for clear separation of concerns.
*   **Scalability:** While implemented with standard Python, the modular design allows for easy integration with message queues (e.g., Kafka) or distributed processing frameworks (e.g., Apache Flink, Spark Streaming) for true real-time, high-volume scenarios. The current implementation processes data synchronously, suitable for demonstrating the core logic.
*   **Readability & Maintainability:** Adherence to PEP8, meaningful naming, docstrings, and comments ensure the code is easy to understand and maintain.
*   **Configuration-driven:** Critical parameters like sensor formats, cleaning rules, and alert thresholds are externalized in `config.py`, allowing for easy adjustments without code changes.
*   **Data Models:** `dataclasses` are used to define clear and consistent data schemas (`RawSensorData`, `StandardSensorData`, `EngineAlert`, `LocationUpdate`) throughout the pipeline.
*   **Error Handling & Logging:** Comprehensive logging is integrated using Python\'s standard `logging` module, providing visibility into the pipeline\'s operation, including warnings for noisy data and errors for processing failures.

## How to Run

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/realtime-iot-data-processor.git
    cd realtime-iot-data-processor
    ```

2.  **Install dependencies:**
    This project uses only standard Python libraries, so typically no `pip install` is strictly required beyond ensuring you have a compatible Python version (3.8+).
    However, if you want to explicitly manage dependencies or use a virtual environment:
    ```bash
    python -m venv venv
    source venv/bin/activate  # On Windows: venv\Scripts\activate
    pip install -r requirements.txt
    ```

3.  **Run the main pipeline demonstration:**
    ```bash
    python src/main.py
    ```
    This will execute the `main.py` script, which simulates a series of raw sensor data inputs and demonstrates their journey through the ingestion, processing, and routing stages. Output will be printed to the console and also saved to a log file in the `logs/` directory.

4.  **Run tests:**
    ```bash
    python -m unittest discover tests
    ```
    This will execute all unit tests to verify the functionality of each module.

## Assumptions and Simplifications

Due to the generic nature of "raw text data" and "not specified" configurations in the TRD, the following assumptions were made:

*   **Raw Data Format:** Two example raw text formats (`TRUCK_A` as CSV-like, `TRUCK_B` as key-value pairs) are defined in `config.py` to demonstrate source identification and parsing.
*   **Standard Schema:** A `StandardSensorData` dataclass is defined with common fields relevant to logistics IoT (device ID, timestamp, location, fuel, engine health).
*   **Cleaning Rules:** Simple range-based validation and default value assignments are implemented for cleaning.
*   **Alert Criteria:** Threshold-based rules are used for detecting engine alerts (e.g., `engine_temperature > X`, `fuel_level < Y`).
*   **Agent System Requirements:** Output formats for Maintenance and Customer Tracking Agents are assumed to be simple JSON structures.
*   **Transmission:** "Transmission" to agents is simulated by logging the formatted data and indicating success/failure. In a real system, this would involve actual API calls, message queue publishing, etc.
*   **Internal Storage:** "Internal system storage" is represented by in-memory data structures passed between functions.
*   **Real-time:** The "real-time" aspect is addressed by the synchronous, low-latency processing of individual data points. For high-throughput, a message queue (e.g., Kafka) would typically feed this pipeline.

## Future Enhancements

*   **Message Queue Integration:** Replace simulated data reception with actual consumers (e.g., Kafka, MQTT) and integrate producers for agent communication.
*   **Database Integration:** Persist raw, normalized, and alert data to a database (e.g., PostgreSQL, NoSQL DB) for historical analysis and state management (e.g., last known location for advanced routing).
*   **Dynamic Configuration:** Load `SENSOR_FORMATS`, `CLEANING_RULES`, and `ALERT_CRITERIA` from a dynamic source (e.g., configuration service, database) rather than static `config.py`.
*   **Advanced Cleaning/Anomaly Detection:** Implement more sophisticated cleaning algorithms (e.g., outlier detection, machine learning models) and anomaly detection for alerts.
*   **Scalable Deployment:** Containerize the application (Docker) and deploy on a cloud platform (Kubernetes, AWS ECS/EKS, Azure AKS, GCP GKE) for horizontal scalability.
*   **Monitoring & Alerting:** Integrate with monitoring tools (Prometheus, Grafana) and actual alerting systems (PagerDuty, Slack).
*   **API Endpoints:** Expose RESTful APIs for agents to pull data or for external systems to push raw data.
*   **Error Handling:** Implement more robust error handling, including retry mechanisms, dead-letter queues, and circuit breakers for external communications.

---

This project provides a solid foundation for a real-time IoT data processing system, demonstrating core functionalities as per the TRD.
