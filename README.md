# IoT Sensor Data Gateway

This project implements a Python-based IoT Sensor Data Gateway designed to ingest, cleanse, normalize, and route sensor data from delivery trucks. It strictly adheres to the provided functional and technical requirements, focusing on production-quality code using standard Python libraries only.

## Project Structure

The project follows a standard Python package structure:

```
project_name/
├── src/
│   ├── __init__.py           # Makes 'src' a Python package
│   ├── gateway_schemas.py    # Defines common data structures and constants
│   ├── gateway_ingest.py     # Implements raw data ingestion (FR-GW-001)
│   ├── gateway_cleanse.py    # Implements raw data cleansing (FR-GW-002)
│   ├── gateway_normalize.py  # Implements data normalization (FR-GW-003)
│   ├── gateway_router.py     # Implements data routing to agents (FR-GW-004, FR-GW-005)
│   └── main.py               # Orchestrates the pipeline for demonstration
├── tests/
│   ├── test_gateway_ingest.py
│   ├── test_gateway_cleanse.py
│   ├── test_gateway_normalize.py
│   └── test_gateway_router.py
├── data/                     # Placeholder for data files (e.g., config, sample data)
├── requirements.txt          # Project dependencies
├── pyproject.toml            # Project metadata and build configuration
├── README.md                 # This file
├── LICENSE                   # License file
└── .gitignore                # Git ignore rules
```

## Functional Requirements Implemented

*   **FR-GW-001: Ingest Raw Sensor Data**: The `SensorDataIngestor` class handles receiving (simulated) and buffering raw sensor text.
*   **FR-GW-002: Cleanse Raw Sensor Data**: The `SensorDataCleanser` class parses raw text, identifies "noisy" data (e.g., zeroed GPS, out-of-range values), applies cleaning rules, and flags issues.
*   **FR-GW-003: Normalize Sensor Data to Standard Schema**: The `SensorDataNormalizer` class transforms cleansed data from various manufacturers into a predefined company-standard schema, including alert code standardization and schema validation.
*   **FR-GW-004: Route Engine Alerts to Maintenance Agent**: The `GatewayRouter` class detects engine alerts in normalized data, formats them, and routes them to a simulated Maintenance Agent.
*   **FR-GW-005: Route Location Updates to Customer Tracking Agent**: The `GatewayRouter` class identifies location updates in normalized data, formats them, and routes them to a simulated Customer Tracking Agent.

## Technical Implementation Details

*   **Standard Python Only**: No external libraries like PySpark, Databricks, or cloud-specific SDKs are used for the core logic. All components are built using Python's standard library.
*   **Modularity**: Each functional requirement is encapsulated within its own module (`gateway_ingest.py`, `gateway_cleanse.py`, etc.) and implemented as Python classes.
*   **Data Flow**: Data progresses through the pipeline sequentially:
    1.  `SensorDataIngestor` buffers raw text.
    2.  `SensorDataCleanser` retrieves raw text, parses it, applies cleansing rules, and produces `CleansedSensorData` (a dictionary).
    3.  `SensorDataNormalizer` takes `CleansedSensorData`, identifies the source, applies manufacturer-specific mappings, validates against the `StandardSensorData` schema, and outputs `StandardSensorData`.
    4.  `GatewayRouter` inspects `StandardSensorData` for alerts and location updates, formats relevant payloads, and "transmits" them to simulated agents (logging output).
*   **Configuration**: Rules, schemas, and agent configurations are managed internally within classes using dictionaries. In a real-world scenario, these would typically be loaded from external sources (e.g., YAML files, environment variables, a configuration service).
*   **Error Handling and Logging**: `logging` is used extensively for debugging, info, warning, and error messages. `try-except` blocks are used to catch and report processing errors, preventing pipeline halts where possible.
*   **Data Representation**: Raw sensor data is assumed to be a comma-separated string. It's parsed into `RawSensorData` (TypedDict), then processed into `CleansedSensorData` (TypedDict), and finally into `StandardSensorData` (TypedDict) for internal consistency and type hinting benefits.
*   **Simulations**:
    *   **Ingestion**: `SensorDataIngestor` accepts strings directly, simulating a stream.
    *   **Agent Communication**: `GatewayRouter` simulates transmission to external agents by logging the formatted payloads to the console.

## Setup and Running

### Prerequisites

*   Python 3.8+ (for `TypedDict` directly from `typing`)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/iot-sensor-data-gateway.git
    cd iot-sensor-data-gateway
    ```
2.  **Create a virtual environment (recommended):**
    ```bash
    python -m venv .venv
    source .venv/bin/activate  # On Windows: .venv\Scripts\activate
    ```
3.  **Install dependencies:**
    ```bash
    pip install -e .  # Install the project in editable mode
    pip install -e ".[dev]" # Install dev dependencies like pytest
    ```

### Running the Gateway

To run the demonstration pipeline with example data:

```bash
python project_name/src/main.py
```

This will execute the `main.py` script, which orchestrates the pipeline using predefined sample raw sensor data. You will see log messages indicating the flow of data, cleansing actions, normalization results, and simulated transmissions to agents.

### Running Tests

To run the unit tests:

```bash
pytest
```

This will execute all tests in the `tests/` directory, ensuring that each component of the gateway functions correctly according to its requirements.

## Future Enhancements (beyond scope of current requirements)

*   **Asynchronous Processing**: Implement `asyncio` for non-blocking I/O operations and higher throughput, especially for ingestion and agent communication.
*   **Real-time Ingestion**: Integrate with message queues (e.g., Kafka, RabbitMQ) or network sockets for actual real-time data streams.
*   **Advanced Cleansing Rules**: Utilize machine learning models for anomaly detection, more sophisticated interpolation techniques, and adaptive noise filtering.
*   **Configuration Management**: Load configurations (rules, schemas, mappings, agent endpoints) from external sources like configuration files (YAML, TOML), environment variables, or a dedicated configuration service.
*   **Persistence**: Store intermediate and final processed data in a database (SQL, NoSQL) or a distributed file system.
*   **Monitoring and Alerting**: Integrate with monitoring systems (e.g., Prometheus, Grafana) and a dedicated alerting service.
*   **Scalability**: Deploy components as microservices, potentially in a containerized environment (Docker, Kubernetes), to handle varying loads.
*   **Retry Mechanisms & Dead-Letter Queues**: Implement robust error handling for external communication failures.
*   **API for Agents**: Provide actual API endpoints (e.g., using FastAPI or Flask) for the simulated Maintenance and Customer Tracking Agents.

## License

This project is licensed under the MIT License - see the `LICENSE` file for details.
