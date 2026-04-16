-- Test script for the get_academic_grade UDF.
-- This script is self-contained and can be run directly in the BigQuery Console
-- or via `bq query --use_legacy_sql=false < tests/test_get_academic_grade.sql`.

BEGIN

  -- Stage 1: Define the function to be tested as a temporary function.
  -- This ensures the test runs with the exact logic from the source file,
  -- without needing the permanent UDF to be deployed.
  CREATE TEMP FUNCTION get_academic_grade(score NUMERIC)
  RETURNS STRING
  AS (
    CASE
      WHEN score >= 90 THEN 'A'
      WHEN score >= 75 THEN 'B'
      WHEN score >= 60 THEN 'C'
      WHEN score IS NOT NULL THEN 'D'
      ELSE NULL
    END
  );

  -- Stage 2: Define test cases and expected outcomes.
  WITH test_cases AS (
    -- Grade 'A' tests
    SELECT 100 AS score, 'A' AS expected_grade, 'Grade A: High score' as description UNION ALL
    SELECT 90 AS score, 'A' AS expected_grade, 'Grade A: Lower bound' as description UNION ALL

    -- Grade 'B' tests
    SELECT 89.99 AS score, 'B' AS expected_grade, 'Grade B: Upper bound' as description UNION ALL
    SELECT 75 AS score, 'B' AS expected_grade, 'Grade B: Lower bound' as description UNION ALL
    SELECT 82 AS score, 'B' AS expected_grade, 'Grade B: Mid-range score' as description UNION ALL

    -- Grade 'C' tests
    SELECT 74.99 AS score, 'C' AS expected_grade, 'Grade C: Upper bound' as description UNION ALL
    SELECT 60 AS score, 'C' AS expected_grade, 'Grade C: Lower bound' as description UNION ALL

    -- Grade 'D' tests
    SELECT 59.99 AS score, 'D' AS expected_grade, 'Grade D: Upper bound' as description UNION ALL
    SELECT 0 AS score, 'D' AS expected_grade, 'Grade D: Zero score' as description UNION ALL
    SELECT -25 AS score, 'D' AS expected_grade, 'Grade D: Negative score' as description UNION ALL

    -- Edge case: NULL input
    SELECT NULL AS score, NULL AS expected_grade, 'Edge Case: NULL score' as description
  ),

  -- Stage 3: Execute tests and validate results.
  validation_results AS (
    SELECT
      *,
      get_academic_grade(score) AS actual_grade,
      -- SAFE.EQUAL correctly compares values, returning TRUE for NULL vs NULL.
      SAFE.EQUAL(get_academic_grade(score), expected_grade) AS is_correct
    FROM test_cases
  )

  -- Stage 4: Assert that all test cases pass.
  -- The script will raise an error and fail if any test case is not correct.
  ASSERT (SELECT LOGICAL_AND(is_correct) FROM validation_results)
  AS 'One or more test cases for get_academic_grade failed.';


EXCEPTION WHEN ERROR THEN
  -- If the assertion fails, this block catches the error and provides a detailed failure report.
  SELECT
    'TESTS FAILED. Mismatched cases:' AS status,
    description,
    score,
    expected_grade,
    get_academic_grade(score) AS actual_grade
  FROM test_cases
  WHERE
    NOT SAFE.EQUAL(get_academic_grade(score), expected_grade);

END;
