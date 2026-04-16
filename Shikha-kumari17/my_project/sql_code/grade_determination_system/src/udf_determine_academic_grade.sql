/*
TR-GRD-001: Creates a persistent user-defined function (UDF) to determine an academic
letter grade from a numerical score.

Description:
  This function implements the business logic defined in the TRD for grading.
  It takes a numerical score and returns a corresponding letter grade (A, B, C, or D).
  The function is designed to be idempotent and reusable across the data warehouse.

Function Signature:
  `bq_project.bq_dataset.udf_determine_academic_grade`(score NUMERIC) RETURNS STRING

Deployment:
  Replace `bq_project` and `bq_dataset` with the target Google Cloud project ID and
  BigQuery dataset ID where the function should be stored.
  Execute this script using the BigQuery console, bq command-line tool, or an API client.
*/
CREATE OR REPLACE FUNCTION `bq_project.bq_dataset.udf_determine_academic_grade`(score NUMERIC)
RETURNS STRING
AS (
  CASE
    WHEN score IS NULL THEN NULL
    WHEN score >= 90 THEN 'A'
    WHEN score >= 75 THEN 'B'
    WHEN score >= 60 THEN 'C'
    ELSE 'D'
  END
);
