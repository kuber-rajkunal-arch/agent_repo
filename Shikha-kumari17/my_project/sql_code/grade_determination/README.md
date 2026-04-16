# Grade Determination UDF

This project contains a Google Standard SQL (BigQuery) User-Defined Function (UDF) to calculate an academic grade based on a numerical score.

## Technical Requirement

- **ID**: `TR-GRD-001`
- **Objective**: Implement a component to calculate and display an academic grade based on a numerical score and predefined grading thresholds.

## Logic

The grading logic is as follows:
- `score >= 90` -> **A**
- `score >= 75` -> **B**
- `score >= 60` -> **C**
- `score < 60` -> **D**
- `score IS NULL` -> **NULL**

## Project Structure

```
.
├── src
│   ├── __init__.py
│   └── get_academic_grade.sql  -- UDF Source Code
├── tests
│   └── test_get_academic_grade.sql -- UDF Test Script
├── data/
├── requirements.txt
├── pyproject.toml
├── README.md
├── LICENSE
└── .gitignore
```

## Deployment

The UDF is defined in `src/get_academic_grade.sql`.

1.  **Modify the UDF name**: Before deploying, open the SQL file and replace `your_project_id.your_dataset` with your target BigQuery project ID and dataset name.

2.  **Deploy using `bq` CLI**:
    ```sh
    bq query \
      --project_id=your_project_id \
      --use_legacy_sql=false \
      < src/get_academic_grade.sql
    ```

## Testing

The test script in `tests/test_get_academic_grade.sql` is self-contained and can be run directly in the BigQuery console or via the `bq` CLI. It creates a temporary version of the function to validate its logic against a predefined set of test cases.

To run the tests:

```sh
bq query \
  --project_id=your_project_id \
  --use_legacy_sql=false \
  < tests/test_get_academic_grade.sql
```

A successful run will produce no output and complete without errors. If a test fails, the script will output a detailed report of the mismatched cases.
