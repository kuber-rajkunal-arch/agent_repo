-- Test Suite for UDF: `udf_calculate_academic_grade`
-- This suite tests the function's logic across all specified grade boundaries and for invalid inputs.
-- Each test is a standalone query that can be run independently.

-- test: udf_grade_a_lower_boundary
-- Verifies the inclusive lower boundary for Grade 'A'.
SELECT
  IF(`your_project.your_dataset.udf_calculate_academic_grade`('90') = 'A', 'PASS', 'FAIL') AS result,
  'udf_grade_a_lower_boundary' AS test_name;

-- test: udf_grade_a_high_value
-- Verifies that scores above 90, including decimals, receive Grade 'A'.
SELECT
  IF(`your_project.your_dataset.udf_calculate_academic_grade`('105.5') = 'A', 'PASS', 'FAIL') AS result,
  'udf_grade_a_high_value' AS test_name;

-- test: udf_grade_b_upper_boundary
-- Verifies the exclusive upper boundary for Grade 'B'.
SELECT
  IF(`your_project.your_dataset.udf_calculate_academic_grade`('89.999') = 'B', 'PASS', 'FAIL') AS result,
  'udf_grade_b_upper_boundary' AS test_name;

-- test: udf_grade_b_lower_boundary
-- Verifies the inclusive lower boundary for Grade 'B'.
SELECT
  IF(`your_project.your_dataset.udf_calculate_academic_grade`('75') = 'B', 'PASS', 'FAIL') AS result,
  'udf_grade_b_lower_boundary' AS test_name;

-- test: udf_grade_c_upper_boundary
-- Verifies the exclusive upper boundary for Grade 'C'.
SELECT
  IF(`your_project.your_dataset.udf_calculate_academic_grade`('74.9') = 'C', 'PASS', 'FAIL') AS result,
  'udf_grade_c_upper_boundary' AS test_name;

-- test: udf_grade_c_lower_boundary
-- Verifies the inclusive lower boundary for Grade 'C'.
SELECT
  IF(`your_project.your_dataset.udf_calculate_academic_grade`('60') = 'C', 'PASS', 'FAIL') AS result,
  'udf_grade_c_lower_boundary' AS test_name;

-- test: udf_grade_d_upper_boundary
-- Verifies the exclusive upper boundary for Grade 'D'.
SELECT
  IF(`your_project.your_dataset.udf_calculate_academic_grade`('59.99') = 'D', 'PASS', 'FAIL') AS result,
  'udf_grade_d_upper_boundary' AS test_name;

-- test: udf_grade_d_zero_value
-- Verifies that a score of 0 correctly receives Grade 'D'.
SELECT
  IF(`your_project.your_dataset.udf_calculate_academic_grade`('0') = 'D', 'PASS', 'FAIL') AS result,
  'udf_grade_d_zero_value' AS test_name;

-- test: udf_grade_d_negative_value
-- Verifies that negative scores correctly fall into the 'ELSE' condition, receiving Grade 'D'.
SELECT
  IF(`your_project.your_dataset.udf_calculate_academic_grade`('-10') = 'D', 'PASS', 'FAIL') AS result,
  'udf_grade_d_negative_value' AS test_name;

-- test: udf_invalid_non_numeric
-- Verifies that a non-numeric string input results in a NULL output, indicating a validation error.
SELECT
  IF(`your_project.your_dataset.udf_calculate_academic_grade`('abc') IS NULL, 'PASS', 'FAIL') AS result,
  'udf_invalid_non_numeric' AS test_name;

-- test: udf_invalid_empty_string
-- Verifies that an empty string input results in a NULL output.
SELECT
  IF(`your_project.your_dataset.udf_calculate_academic_grade`('') IS NULL, 'PASS', 'FAIL') AS result,
  'udf_invalid_empty_string' AS test_name;

-- test: udf_invalid_null_input
-- Verifies that a NULL input correctly propagates to a NULL output.
SELECT
  IF(`your_project.your_dataset.udf_calculate_academic_grade`(NULL) IS NULL, 'PASS', 'FAIL') AS result,
  'udf_invalid_null_input' AS test_name;