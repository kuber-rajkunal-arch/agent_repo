-- Test script for udf_grade_from_score
-- This query tests all specified business logic and edge cases.
-- The test passes if this query returns zero rows.

WITH test_cases AS (
  -- Test cases for each grade category and its boundaries
  SELECT 105 AS score, 'Grade A' AS expected_grade, 'Above 90' AS description
  UNION ALL
  SELECT 90 AS score, 'Grade A' AS expected_grade, 'Lower bound for Grade A' AS description
  UNION ALL
  SELECT 89.99 AS score, 'Grade B' AS expected_grade, 'Upper bound for Grade B' AS description
  UNION ALL
  SELECT 75 AS score, 'Grade B' AS expected_grade, 'Lower bound for Grade B' AS description
  UNION ALL
  SELECT 74.99 AS score, 'Grade C' AS expected_grade, 'Upper bound for Grade C' AS description
  UNION ALL
  SELECT 60 AS score, 'Grade C' AS expected_grade, 'Lower bound for Grade C' AS description
  UNION ALL
  SELECT 59.99 AS score, 'Grade D' AS expected_grade, 'Upper bound for Grade D' AS description
  UNION ALL
  SELECT 0 AS score, 'Grade D' AS expected_grade, 'Zero score' AS description
  UNION ALL
  SELECT -50 AS score, 'Grade D' AS expected_grade, 'Negative score' AS description
  UNION ALL
  -- Edge case: NULL input
  SELECT NULL AS score, NULL AS expected_grade, 'NULL score' AS description
),

test_results AS (
  SELECT
    score,
    description,
    expected_grade,
    `your_project_id.your_dataset_id.grade_from_score`(score) AS actual_grade
  FROM test_cases
)

-- Select all records where the actual result does not match the expected result.
-- A successful test run will produce 0 rows.
SELECT *
FROM test_results
WHERE
  -- Use a NULL-safe comparison
  NOT(actual_grade IS NOT DISTINCT FROM expected_grade);