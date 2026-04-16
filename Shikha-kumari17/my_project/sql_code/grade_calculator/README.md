# Grade Calculator - BigQuery SQL Implementation

This project provides a production-ready Google Standard SQL (BigQuery) implementation for calculating an academic grade from a numerical score, based on the specifications in `TRD_PL_SQL_Grade_Calculator`.

## Project Structure

```
grade_calculator/
├── src/
│   └── functions/
│       └── get_academic_grade.sql  -- DDL for the BigQuery UDF
└── tests/
    └── test_get_academic_grade.sql -- Test script for the UDF
```

- **`src/functions/get_academic_grade.sql`**: Contains the `CREATE OR REPLACE FUNCTION` statement for the user-defined function (UDF). This is the core logic of the application.
- **`tests/test_get_academic_grade.sql`**: A BigQuery script that contains a suite of automated tests to verify the function's behavior, including boundary conditions and error handling.

## Deployment

### Prerequisites

- A Google Cloud Platform project with BigQuery enabled.
- A BigQuery dataset to host the function (e.g., `your_dataset_id`).
- `gcloud` CLI or BigQuery UI access with permissions to create functions.

### Steps

1.  **Update Placeholders**: In `src/functions/get_academic_grade.sql`, replace `your_project_id` and `your_dataset_id` with your actual GCP project ID and BigQuery dataset ID.

2.  **Execute DDL**: Run the SQL script from `src/functions/get_academic_grade.sql` in the BigQuery UI or via the `gcloud` CLI.

    ```bash
    gcloud bq query --use_legacy_sql=false < src/functions/get_academic_grade.sql
    ```

## Running Tests

The test script verifies that the deployed function behaves as expected.

1.  **Update Placeholders**: In `tests/test_get_academic_grade.sql`, replace `your_project_id` and `your_dataset_id` with the same values used during deployment.

2.  **Execute Test Script**: Run the SQL script from `tests/test_get_academic_grade.sql` in the BigQuery UI or via the `gcloud` CLI.

    ```bash
    gcloud bq query --use_legacy_sql=false < tests/test_get_academic_grade.sql
    ```

A successful run will complete without errors and output a final message: `Assertion Passed: NULL input correctly raised an error.`. If any assertion fails, the script will halt and report a descriptive error message.

## Example Usage

Once deployed, the function can be used in any query within the same project.

```sql
WITH scores AS (
  SELECT 95 AS student_id, 92.5 AS numerical_score
  UNION ALL
  SELECT 101, 74.8
  UNION ALL
  SELECT 102, 59.9
  UNION ALL
  SELECT 103, NULL
)
SELECT
  student_id,
  numerical_score,
  -- The following demonstrates logging input and output as per TRD.
  -- The SAFE prefix prevents the query from failing on an error, returning NULL instead.
  SAFE.your_project_id.your_dataset_id.get_academic_grade(numerical_score) AS academic_grade
FROM
  scores;
```