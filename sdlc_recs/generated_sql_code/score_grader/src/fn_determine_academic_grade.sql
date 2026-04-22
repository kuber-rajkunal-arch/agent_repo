/*
-------------------------------------------------------------------------------
| Name:         fn_determine_academic_grade
|
| Description:  Implements a function to determine an academic grade (A, B, C,
|               or D) from a numerical score based on predefined conditional
|               thresholds.
|
|               Corresponds to Technical Requirement TR-GRD-001.
|
| Parameters:
|   - score (NUMERIC): The numerical score to evaluate.
|
| Returns:
|   - STRING: The calculated academic grade ('A', 'B', 'C', or 'D').
|
| Raises:
|   - An error if the input score is NULL.
-------------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION `your_dataset.fn_determine_academic_grade`(score NUMERIC)
RETURNS STRING
AS (
  CASE
    WHEN score IS NULL THEN ERROR('Input score cannot be NULL. TR-GRD-001 validation failed.')
    WHEN score >= 90 THEN 'A'
    WHEN score >= 75 THEN 'B'
    WHEN score >= 60 THEN 'C'
    ELSE 'D'
  END
);
