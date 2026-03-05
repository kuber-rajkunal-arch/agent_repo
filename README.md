# IoT Sensor Data Gateway

This project implements a Python-based IoT Sensor Data Gateway designed to ingest, clean, normalize, and route data from various IoT sensors on delivery trucks. It serves as a central processing unit for raw sensor data before it's dispatched to different downstream agents.

## Project Structure

```
project_name/
├── src/
│   ├── __init__.py             # Initializes the src package
│   ├── agents.py               # Defines abstract agent interfaces and mock implementations (Maintenance, Customer Tracking)
│   ├── cleaning.py             # Implements data cleaning logic for raw sensor data (FR-GW-002)
│   ├── config.py               # Centralized application configuration (logging, rules, mappings)
│   ├── data_models.py          # Defines standard data structures like StandardSensorData
│   ├── gateway.py              # The main orchestration logic for the entire data pipeline
│   ├── ingestion.py            # Handles raw sensor data reception and temporary storage (FR-GW-001)
│   └── normalization.py        # Transforms cleaned data into a standard schema (FR-GW-003)
│   └── routing.py              # Routes normalized data to appropriate agents (FR-GW-004, FR-GW-005)
├── tests/
│   ├── __init__.py
│   ├── test_agents.py
│   ├── test_cleaning.py
│   ├── test_gateway.py
│   ├── test_ingestion.py
│   ├── test_normalization.py
│   └── test_routing.py
├── data/                       # Placeholder for any sample data or configuration files
├── requirements.txt            # Python package dependencies
├── pyproject.toml              # Project metadata and build configuration
├── README.md                   # This README file
├── LICENSE                     # Project license (MIT)
└── .gitignore                  # Files/directories to ignore in Git
```

## Functional Requirements Implemented

The gateway addresses the following functional requirements:

*   **FR-GW-001: Ingest Raw Sensor Data:** Receives and temporarily stores raw sensor data text.
*   **FR-GW-002: Clean Raw Sensor Data:** Identifies and cleans "noisy" data (e.g., GPS signal losses, erratic readings).
*   **FR-GW-003: Normalize Data to Standard Schema:** Transforms cleaned data from various manufacturers into a predefined standard schema.
*   **FR-GW-004: Route Engine Alerts to Maintenance Agent:** Detects "Engine Alerts" in normalized data and routes them to a Maintenance Agent.
*   **FR-GW-005: Route Location Updates to Customer Tracking Agent:** Identifies "Location Updates" in normalized data and routes them to a Customer Tracking Agent.

## Getting Started

### Prerequisites

*   Python 3.8+

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/iot-sensor-data-gateway.git
    cd iot-sensor-data-gateway/project_name
    ```
2.  **Create a virtual environment (recommended):**
    ```bash
    python -m venv .venv
    source .venv/bin/activate  # On Windows, use `.venv\Scripts\activate`
    ```
3.  **Install dependencies:**
    This project uses only standard Python libraries, so there are no external dependencies listed in `requirements.txt` currently.
    ```bash
    # pip install -r requirements.txt # If external dependencies are added later
    ```

### Running the Gateway

You can run a simulation of the gateway processing sample data directly:

```bash
python src/gateway.py
```

This will execute the `run_simulation` method in `gateway.py`, demonstrating the flow with predefined raw data samples, including cases for cleaning and routing.

### Running Tests

To ensure everything is working correctly, run the provided unit tests:

```bash
pip install pytest
pytest tests/
```

## Configuration

The `src/config.py` module holds all configurable parameters for the gateway, including:

*   Logging levels and format
*   Regex patterns and default values for data cleaning
*   Mapping rules for different sensor manufacturers (e.g., Bosch, Garmin) to the standard data schema
*   Endpoints for the Maintenance and Customer Tracking Agents (currently mock endpoints)
*   Rules for detecting engine alerts

You can modify these parameters to customize the gateway's behavior.

## Extending the Gateway

*   **New Sensor Manufacturers:** Add new entries to `AppConfig.MANUFACTURER_MAPPINGS` in `src/config.py` and potentially update `Normalizer._identify_manufacturer` if the identification logic changes.
*   **New Noise Patterns/Cleaning Rules:** Update `AppConfig.NOISE_PATTERNS` and `AppConfig.CLEANING_DEFAULTS` in `src/config.py`, and implement corresponding logic in `DataCleaner.clean_raw_data`.
*   **New Agents/Routing:**
    1.  Define a new `AbstractXAgent` in `src/agents.py`.
    2.  Create a concrete `MockXAgent` (or real implementation).
    3.  Create a `XRouter` class in `src/routing.py` to identify relevant data and interact with the new agent.
    4.  Integrate the new router into `IoTDataGateway` in `src/gateway.py`.
*   **Real Agent Integrations:** Replace `MockMaintenanceAgent` and `MockCustomerTrackingAgent` with actual implementations that communicate with external services (e.g., via HTTP, Kafka, AMQP) in `src/agents.py`.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

_This project is a demonstration of enterprise-grade Python system design based on specified functional and technical requirements._
