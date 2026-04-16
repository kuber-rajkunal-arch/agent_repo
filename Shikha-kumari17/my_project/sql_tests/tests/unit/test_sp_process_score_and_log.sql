-- Test Suite for Stored Procedure: `sp_process_score_and_log`
-- This test declaratively verifies the business logic within the stored procedure
-- without executing it directly, thus avoiding procedural calls and side effects.
-- It simulates the internal logic to confirm that status and error messages are derived correctly.

-- test: sp_logging_logic_all_cases
-- This single, comprehensive test validates the core decision-making logic of the stored procedure
-- for a variety of success and validation error scenarios.
WITH
  -- 1. Define test inputs and their expected outcomes after processing by the SP logic.
  test_cases AS (
    SELECT '95' AS score_input, 'A' AS expected_grade, 'SUCCESS' AS expected_status, CAST(NULL AS STRING) AS expected_error_message UNION ALL
    SELECT '89.999', 'B', 'SUCCESS', NULL UNION ALL
    SELECT '75', 'B', 'SUCCESS', NULL UNION ALL
    SELECT '60', 'C', 'SUCCESS', NULL UNION ALL
    SELECT '59.9', 'D', 'SUCCESS', NULL UNION ALL
    SELECT '-10', 'D', 'SUCCESS', NULL UNION ALL
    SELECT 'not-a-number', NULL, 'VALIDATION_ERROR', 'Input score is not a valid numerical value.' UNION ALL
    SELECT '', NULL, 'VALIDATION_ERROR', 'Input score is not a valid numerical value.' UNION ALL
    SELECT NULL, NULL, 'VALIDATION_ERROR', 'Input score is not a valid numerical value.'
  ),

  -- 2. Simulate the core logic of the stored procedure:
  --    - Call the UDF to get the grade.
  --    - Determine status and error message based on the UDF's result.
  simulated_sp_logic AS (
    SELECT
      score_input,
      `your_project.your_dataset.udf_calculate_academic_grade`(score_input) AS calculated_grade,
      IF(`your_project.your_dataset.udf_calculate_academic_grade`(score_input) IS NULL, 'VALIDATION_ERROR', 'SUCCESS') AS calculated_status,
      IF(`your_project.your_dataset.udf_calculate_academic_grade`(score_input) IS NULL, 'Input score is not a valid numerical value.', NULL) AS calculated_error_message
    FROM
      test_cases
  ),

  -- 3. Compare the simulated results against the expected outcomes.
  --    A row will exist here only if the simulated logic produces the expected result.
  --    `IS NOT DISTINCT FROM` is used for correct NULL-safe comparison.
  validation AS (
    SELECT
      test_cases.score_input
    FROM
      test_cases
    INNER JOIN
      simulated_sp_logic ON test_cases.score_input IS NOT DISTINCT FROM simulated_sp_logic.score_input
    WHERE
      test_cases.expected_grade IS NOT DISTINCT FROM simulated_sp_logic.calculated_grade
      AND test_cases.expected_status IS NOT DISTINCT FROM simulated_sp_logic.calculated_status
      AND test_cases.expected_error_message IS NOT DISTINCT FROM simulated_sp_logic.calculated_error_message
  )

-- Final check: The test passes if the number of successfully validated rows
-- equals the total number of test cases. Any mismatch indicates a logic failure.
SELECT
  IF(
    (SELECT COUNT(*) FROM validation) = (SELECT COUNT(*) FROM test_cases),
    'PASS',
    'FAIL'
  ) AS result,
  'sp_logging_logic_all_cases' AS test_name;