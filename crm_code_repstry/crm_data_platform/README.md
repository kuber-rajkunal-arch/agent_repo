# CRM Data Platform - Data Transformation & Curation

This project contains the data ingestion pipelines for populating the Curated layer of the Customer Single Source of Truth (SSOT) Data Platform in Google BigQuery.

## Overview

The pipelines implement an incremental, SCD Type 1 data ingestion process from the `Raw` dataset to the `Curated` dataset for the following entities:
- `customer`
- `lead`
- `opportunity`
- `quote`
- `quote_detail`

## Prerequisites

- Python 3.8+
- Google Cloud SDK authenticated with access to the target BigQuery project.

## Installation

1.  Clone the repository.
2.  Install the required Python packages:
    ```bash
    pip install -r requirements.txt
    ```

## Configuration

Set the `GCP_PROJECT_ID` environment variable to your Google Cloud project ID.

```bash
export GCP_PROJECT_ID="your-gcp-project-id"
```

## Usage

To run the entire ingestion pipeline for all tables:

```bash
python -m src.main
```

## Testing

To run the automated tests:

```bash
pip install ".[dev]"
pytest
```
