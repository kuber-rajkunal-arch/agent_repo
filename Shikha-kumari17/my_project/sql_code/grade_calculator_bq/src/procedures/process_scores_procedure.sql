/*
  TR-GRD-001: Score Processing and Logging Procedure

  Objective:
  Implements the full job flow for processing scores from a source table,
  applying grade calculation logic, and logging the results to a target table.
  This procedure handles input validation and error logging as per requirements.

  Job Flow:
  1. Reads data from a specified source table.
  2. Validates and casts the input score column.
  3. Calls the `calculate_letter_grade` UDF for valid scores.
  4. Logs input, output, and processing status for each record.
  5. Writes the results to a specified target table, replacing it if it exists.

  Error Handling:
  - Uses SAFE_CAST to handle non-numerical score inputs gracefully.
  - Logs an error message in the 'processing_status' column for invalid inputs.
*/
CREATE OR REPLACE PROCEDURE `grade_calculator_prod.process_scores`(
  source_table_id STRING,
  source_score_column STRING,
  target_table_id STRING
)
BEGIN
  EXECUTE IMMEDIATE FORMAT("""
    CREATE OR REPLACE TABLE `%s`
    PARTITION BY
      -- Partitioning is recommended for large-scale production tables
      -- to improve query performance and manage costs.
      DATE_TRUNC(ingestion_timestamp, DAY)
    CLUSTER BY letter_grade, processing_status
    AS
    WITH
      SourceData AS (
        SELECT
          *
        FROM
          `%s`
      ),
      ValidatedScores AS (
        SELECT
          *,
          SAFE_CAST(%s AS NUMERIC) AS numerical_score
        FROM
          SourceData
      ),
      GradedScores AS (
        SELECT
          *,
          `grade_calculator_prod.calculate_letter_grade`(numerical_score) AS letter_grade
        FROM
          ValidatedScores
      )
    SELECT
      -- Log the input numerical score received
      %s AS input_score,
      -- Log the determined letter grade
      letter_grade,
      -- Log any instances where an invalid numerical score was provided
      CASE
        WHEN numerical_score IS NULL AND %s IS NOT NULL THEN FORMAT("Invalid input: Score '%s' is not a valid number.", %s)
        WHEN numerical_score IS NULL AND %s IS NULL THEN 'Invalid input: Score is NULL.'
        ELSE 'Processed successfully'
      END AS processing_status,
      CURRENT_TIMESTAMP() AS ingestion_timestamp
    FROM
      GradedScores;
  """,
  target_table_id,
  source_table_id,
  source_score_column,
  source_score_column,
  source_score_column,
  source_score_column
  );
END;
