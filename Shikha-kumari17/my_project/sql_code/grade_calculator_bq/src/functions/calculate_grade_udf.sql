/*
  TR-GRD-001: Grade Calculation User-Defined Function

  Objective:
  Encapsulates the core business logic for determining a letter grade from a
  numerical score. This function is designed for reusability and deterministic
  output.

  Business Logic:
  - Score >= 90: 'A'
  - Score >= 75: 'B'
  - Score >= 60: 'C'
  - Score < 60:  'D'

  Usage:
  SELECT grade_calculator_prod.calculate_letter_grade(95); -- Returns 'A'
*/
CREATE OR REPLACE FUNCTION `grade_calculator_prod.calculate_letter_grade`(
  score NUMERIC
)
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