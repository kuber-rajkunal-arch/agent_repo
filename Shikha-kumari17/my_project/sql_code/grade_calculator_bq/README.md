# BigQuery Grade Calculator

This project implements a system in Google Standard SQL (BigQuery) to calculate academic grades based on numerical scores, as specified in Technical Requirement Document `TR-GRD-001`.

## Project Overview

The system consists of two main BigQuery objects:
1.  A User-Defined Function (UDF) that encapsulates the core grading logic.
2.  A Stored Procedure that orchestrates the process, calls the UDF, and logs the outcome for traceability.

## BigQuery Objects

### 1. UDF: `udf_calculate_academic_grade`

This is a persistent SQL UDF that takes a score and returns the corresponding academic grade.

-   **File:** `src/functions/udf_calculate_academic_grade.sql`
-   **Signature:** `udf_calculate_academic_grade(score_input STRING) RETURNS STRING`
-   **Description:**
    -   Assigns a grade ('A', 'B', 'C', or 'D') based on predefined thresholds.
    -   Handles input validation by accepting a `STRING` and using `SAFE_CAST`.
    -   Returns `NULL` if the input cannot be interpreted as a number, indicating a validation error.

### 2. Stored Procedure: `sp_process_score_and_log`

This procedure serves as the main entry point for processing a score and ensuring the result is logged.

-   **File:** `src/procedures/sp_process_score_and_log.sql`
-   **Signature:** `sp_process_score_and_log(IN score_input STRING, IN log_table_id STRING)`
-   **Description:**
    -   Receives a score as a `STRING`.
    -   Calls `udf_calculate_academic_grade` to determine the grade.
    -   Logs the input, output, and status ('SUCCESS' or 'VALIDATION_ERROR') into a specified log table.

#### Log Table Schema

The target log table, specified by the `log_table_id` parameter, must have the following schema:

| Column Name         | Data Type | Description                                           |
| ------------------- | --------- | ----------------------------------------------------- |
| `ingestion_timestamp` | `TIMESTAMP` | The timestamp when the log entry was created.         |
| `input_score`       | `STRING`    | The original input score string provided.             |
| `calculated_grade`  | `STRING`    | The academic grade determined by the UDF. `NULL` on error. |
| `status`            | `STRING`    | 'SUCCESS' or 'VALIDATION_ERROR'.                      |
| `error_message`     | `STRING`    | A descriptive message if a validation error occurred. |

## Deployment

1.  **Set Project and Dataset:** Before deployment, replace the placeholder values `your_project` and `your_dataset` in all `.sql` files with your actual Google Cloud project ID and BigQuery dataset ID.
2.  **Create Log Table:** Create the log table in your dataset using the schema defined above.
3.  **Deploy UDF:** Execute the contents of `src/functions/udf_calculate_academic_grade.sql` in the BigQuery UI or via the `bq` command-line tool.
4.  **Deploy Stored Procedure:** Execute the contents of `src/procedures/sp_process_score_and_log.sql`.

## Execution Example

After deployment, you can process a score by calling the stored procedure.

```sql
CALL `your_project.your_dataset.sp_process_score_and_log`(
  '88.5', -- Input Score
  '`your_project.your_dataset.your_log_table`' -- Target Log Table
);
```

## Testing

The test suite is designed to be run directly in the BigQuery console as a single script.

1.  **Set Test Dataset:** In `tests/test_routines.sql`, replace the placeholder `your_temp_dataset` with a dataset where temporary test tables can be created and dropped. This dataset should exist in the same project used for deployment.
2.  **Run Tests:** Execute the entire content of `tests/test_routines.sql` in the BigQuery UI.
3.  **Review Results:** The script will run a series of `ASSERT` statements. If all tests pass, the script will complete successfully. If any test fails, it will raise an error with a descriptive message.
