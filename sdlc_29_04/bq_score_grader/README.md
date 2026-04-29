# BigQuery Score Grader Module

This project contains a BigQuery SQL module to evaluate a numerical score and assign a corresponding academic grade.

It is implemented as a set of a User-Defined Function (UDF) for the core logic and a Stored Procedure (SP) for orchestration, including logging and error handling.

## TRD ID
- TR-GRD-001

## Components

1.  **`src/udf_grade_from_score.sql`**: A pure SQL UDF that takes a `NUMERIC` score and returns a `STRING` grade.
2.  **`src/sp_evaluate_and_log_score.sql`**: A stored procedure that takes a `STRING` score, validates it, calls the UDF, logs the outcome, and handles errors.

## Prerequisites

Before deploying the stored procedure, ensure the following tables exist in the target BigQuery dataset. The procedure will log to these tables.

```sql
CREATE TABLE IF NOT EXISTS your_dataset_id.grade_processing_log (
    processed_timestamp TIMESTAMP OPTIONS(description="Timestamp of the processing event."),
    input_score NUMERIC OPTIONS(description="The valid numerical score that was processed."),
    assigned_grade STRING OPTIONS(description="The academic grade assigned to the score.")
);

CREATE TABLE IF NOT EXISTS your_dataset_id.grade_error_log (
    error_timestamp TIMESTAMP OPTIONS(description="Timestamp of the error event."),
    invalid_input STRING OPTIONS(description="The input string that caused the validation error."),
    error_message STRING OPTIONS(description="A description of the error.")
);
```

## Deployment

1.  Replace `your_project_id` and `your_dataset_id` in all `.sql` files with your actual BigQuery project and dataset IDs.
2.  Run the SQL commands in the `src/` directory files in your BigQuery console or using a deployment tool to create the UDF and Stored Procedure. It is recommended to deploy the UDF first.

## Testing

The `tests/` directory contains SQL scripts to validate the functionality.

1.  Update the project and dataset placeholders in the test files.
2.  Run the contents of each test file in the BigQuery SQL Editor.
3.  `test_udf_grade_from_score.sql`: This test passes if the query returns 0 rows.
4.  `test_sp_evaluate_and_log_score.sql`: This is a script that runs a series of assertions. The script will succeed without error if all tests pass.
