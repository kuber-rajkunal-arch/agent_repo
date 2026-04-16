-- Unit tests for the calculate_letter_grade function.
-- These tests cover boundary conditions, typical values for each grade, and NULL input handling.

-- Test Category: CONDITIONAL / BUSINESS LOGIC TESTS
-- Test Case: Score at the exact lower boundary for Grade A (90).
SELECT
  'test_grade_A_lower_boundary' AS test_name,
  IF(`your_project.your_dataset.calculate_letter_grade`(90) = 'A', 'PASS', 'FAIL') AS result;

-- Test Category: CONDITIONAL / BUSINESS LOGIC TESTS
-- Test Case: Score well within the range for Grade A (100).
SELECT
  'test_grade_A_mid_range' AS test_name,
  IF(`your_project.your_dataset.calculate_letter_grade`(100) = 'A', 'PASS', 'FAIL') AS result;

-- Test Category: CONDITIONAL / BUSINESS LOGIC TESTS
-- Test Case: Score at the exact lower boundary for Grade B (75).
SELECT
  'test_grade_B_lower_boundary' AS test_name,
  IF(`your_project.your_dataset.calculate_letter_grade`(75) = 'B', 'PASS', 'FAIL') AS result;

-- Test Category: CONDITIONAL / BUSINESS LOGIC TESTS
-- Test Case: Score just below the upper boundary for Grade B (89.9).
SELECT
  'test_grade_B_upper_boundary' AS test_name,
  IF(`your_project.your_dataset.calculate_letter_grade`(89.9) = 'B', 'PASS', 'FAIL') AS result;

-- Test Category: CONDITIONAL / BUSINESS LOGIC TESTS
-- Test Case: Score well within the range for Grade B (82).
SELECT
  'test_grade_B_mid_range' AS test_name,
  IF(`your_project.your_dataset.calculate_letter_grade`(82) = 'B', 'PASS', 'FAIL') AS result;

-- Test Category: CONDITIONAL / BUSINESS LOGIC TESTS
-- Test Case: Score at the exact lower boundary for Grade C (60).
SELECT
  'test_grade_C_lower_boundary' AS test_name,
  IF(`your_project.your_dataset.calculate_letter_grade`(60) = 'C', 'PASS', 'FAIL') AS result;

-- Test Category: CONDITIONAL / BUSINESS LOGIC TESTS
-- Test Case: Score just below the upper boundary for Grade C (74.9).
SELECT
  'test_grade_C_upper_boundary' AS test_name,
  IF(`your_project.your_dataset.calculate_letter_grade`(74.9) = 'C', 'PASS', 'FAIL') AS result;

-- Test Category: CONDITIONAL / BUSINESS LOGIC TESTS
-- Test Case: Score well within the range for Grade C (68).
SELECT
  'test_grade_C_mid_range' AS test_name,
  IF(`your_project.your_dataset.calculate_letter_grade`(68) = 'C', 'PASS', 'FAIL') AS result;

-- Test Category: CONDITIONAL / BUSINESS LOGIC TESTS
-- Test Case: Score just below the lower boundary for Grade C, which should be Grade D (59.9).
SELECT
  'test_grade_D_upper_boundary' AS test_name,
  IF(`your_project.your_dataset.calculate_letter_grade`(59.9) = 'D', 'PASS', 'FAIL') AS result;

-- Test Category: CONDITIONAL / BUSINESS LOGIC TESTS
-- Test Case: A score of 0, which should result in Grade D.
SELECT
  'test_grade_D_zero_score' AS test_name,
  IF(`your_project.your_dataset.calculate_letter_grade`(0) = 'D', 'PASS', 'FAIL') AS result;

-- Test Category: CONDITIONAL / BUSINESS LOGIC TESTS
-- Test Case: A negative score, which should result in Grade D.
SELECT
  'test_grade_D_negative_score' AS test_name,
  IF(`your_project.your_dataset.calculate_letter_grade`(-10) = 'D', 'PASS', 'FAIL') AS result;

-- Test Category: NULL / EMPTY VALUE CHECKS
-- Test Case: A NULL input score should result in a NULL output.
SELECT
  'test_null_input' AS test_name,
  IF(`your_project.your_dataset.calculate_letter_grade`(NULL) IS NULL, 'PASS', 'FAIL') AS result;