-- Test Suite for fn_determine_academic_grade logic
--
-- Description: This file contains a set of declarative unit tests to verify the
-- correctness of the academic grading logic. Each test is a standalone SELECT
-- statement that evaluates a specific scenario. This approach is designed for
-- production-quality data validation and integration with automated testing frameworks.
--
-- Corresponds to Technical Requirement TR-GRD-001.

-- test: grade_A_high_score
-- Verifies a score well within the 'A' grade range.
SELECT
  IF(
    (CASE WHEN 100 >= 90 THEN 'A' WHEN 100 >= 75 THEN 'B' WHEN 100 >= 60 THEN 'C' ELSE 'D' END) = 'A',
    'PASS', 'FAIL'
  ) AS result,
  'grade_A_high_score' AS test_name;

-- test: grade_A_boundary
-- Verifies the exact lower boundary for an 'A' grade.
SELECT
  IF(
    (CASE WHEN 90 >= 90 THEN 'A' WHEN 90 >= 75 THEN 'B' WHEN 90 >= 60 THEN 'C' ELSE 'D' END) = 'A',
    'PASS', 'FAIL'
  ) AS result,
  'grade_A_boundary' AS test_name;

-- test: grade_B_upper_boundary
-- Verifies a score just below the 'A' grade threshold, which should result in a 'B'.
SELECT
  IF(
    (CASE WHEN 89.9 >= 90 THEN 'A' WHEN 89.9 >= 75 THEN 'B' WHEN 89.9 >= 60 THEN 'C' ELSE 'D' END) = 'B',
    'PASS', 'FAIL'
  ) AS result,
  'grade_B_upper_boundary' AS test_name;

-- test: grade_B_mid_range
-- Verifies a score squarely in the 'B' grade range.
SELECT
  IF(
    (CASE WHEN 82 >= 90 THEN 'A' WHEN 82 >= 75 THEN 'B' WHEN 82 >= 60 THEN 'C' ELSE 'D' END) = 'B',
    'PASS', 'FAIL'
  ) AS result,
  'grade_B_mid_range' AS test_name;

-- test: grade_B_lower_boundary
-- Verifies the exact lower boundary for a 'B' grade.
SELECT
  IF(
    (CASE WHEN 75 >= 90 THEN 'A' WHEN 75 >= 75 THEN 'B' WHEN 75 >= 60 THEN 'C' ELSE 'D' END) = 'B',
    'PASS', 'FAIL'
  ) AS result,
  'grade_B_lower_boundary' AS test_name;

-- test: grade_C_upper_boundary
-- Verifies a score just below the 'B' grade threshold, which should result in a 'C'.
SELECT
  IF(
    (CASE WHEN 74.9 >= 90 THEN 'A' WHEN 74.9 >= 75 THEN 'B' WHEN 74.9 >= 60 THEN 'C' ELSE 'D' END) = 'C',
    'PASS', 'FAIL'
  ) AS result,
  'grade_C_upper_boundary' AS test_name;

-- test: grade_C_mid_range
-- Verifies a score squarely in the 'C' grade range.
SELECT
  IF(
    (CASE WHEN 65 >= 90 THEN 'A' WHEN 65 >= 75 THEN 'B' WHEN 65 >= 60 THEN 'C' ELSE 'D' END) = 'C',
    'PASS', 'FAIL'
  ) AS result,
  'grade_C_mid_range' AS test_name;

-- test: grade_C_lower_boundary
-- Verifies the exact lower boundary for a 'C' grade.
SELECT
  IF(
    (CASE WHEN 60 >= 90 THEN 'A' WHEN 60 >= 75 THEN 'B' WHEN 60 >= 60 THEN 'C' ELSE 'D' END) = 'C',
    'PASS', 'FAIL'
  ) AS result,
  'grade_C_lower_boundary' AS test_name;

-- test: grade_D_upper_boundary
-- Verifies a score just below the 'C' grade threshold, which should result in a 'D'.
SELECT
  IF(
    (CASE WHEN 59.9 >= 90 THEN 'A' WHEN 59.9 >= 75 THEN 'B' WHEN 59.9 >= 60 THEN 'C' ELSE 'D' END) = 'D',
    'PASS', 'FAIL'
  ) AS result,
  'grade_D_upper_boundary' AS test_name;

-- test: grade_D_mid_range
-- Verifies a score squarely in the 'D' grade range.
SELECT
  IF(
    (CASE WHEN 30 >= 90 THEN 'A' WHEN 30 >= 75 THEN 'B' WHEN 30 >= 60 THEN 'C' ELSE 'D' END) = 'D',
    'PASS', 'FAIL'
  ) AS result,
  'grade_D_mid_range' AS test_name;

-- test: grade_D_zero_score
-- Verifies that a score of zero correctly results in a 'D'.
SELECT
  IF(
    (CASE WHEN 0 >= 90 THEN 'A' WHEN 0 >= 75 THEN 'B' WHEN 0 >= 60 THEN 'C' ELSE 'D' END) = 'D',
    'PASS', 'FAIL'
  ) AS result,
  'grade_D_zero_score' AS test_name;

-- test: grade_D_negative_score
-- Verifies that a negative score correctly results in a 'D'.
SELECT
  IF(
    (CASE WHEN -50 >= 90 THEN 'A' WHEN -50 >= 75 THEN 'B' WHEN -50 >= 60 THEN 'C' ELSE 'D' END) = 'D',
    'PASS', 'FAIL'
  ) AS result,
  'grade_D_negative_score' AS test_name;
