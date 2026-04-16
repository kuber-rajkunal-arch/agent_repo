/*
  Test Suite for calculate_letter_grade UDF

  Purpose:
  Verifies the correctness of the grade calculation logic by testing
  boundary conditions, standard cases, and edge cases.

  Execution:
  This script must be run in a BigQuery project where the
  `grade_calculator_prod.calculate_letter_grade` UDF has been deployed.
  It will raise an error if any assertion fails.
*/
BEGIN

  -- Test Case: Top of A range
  ASSERT `grade_calculator_prod.calculate_letter_grade`(105) = 'A'
    AS 'Test Failed: Score 105 should be A';

  -- Test Case: Boundary between A and B (exact A)
  ASSERT `grade_calculator_prod.calculate_letter_grade`(90) = 'A'
    AS 'Test Failed: Score 90 should be A';

  -- Test Case: Boundary between A and B (just below A)
  ASSERT `grade_calculator_prod.calculate_letter_grade`(89.99) = 'B'
    AS 'Test Failed: Score 89.99 should be B';

  -- Test Case: Middle of B range
  ASSERT `grade_calculator_prod.calculate_letter_grade`(82) = 'B'
    AS 'Test Failed: Score 82 should be B';

  -- Test Case: Boundary between B and C (exact B)
  ASSERT `grade_calculator_prod.calculate_letter_grade`(75) = 'B'
    AS 'Test Failed: Score 75 should be B';

  -- Test Case: Boundary between B and C (just below B)
  ASSERT `grade_calculator_prod.calculate_letter_grade`(74.99) = 'C'
    AS 'Test Failed: Score 74.99 should be C';

  -- Test Case: Boundary between C and D (exact C)
  ASSERT `grade_calculator_prod.calculate_letter_grade`(60) = 'C'
    AS 'Test Failed: Score 60 should be C';

  -- Test Case: Boundary between C and D (just below C)
  ASSERT `grade_calculator_prod.calculate_letter_grade`(59.99) = 'D'
    AS 'Test Failed: Score 59.99 should be D';

  -- Test Case: Low D range
  ASSERT `grade_calculator_prod.calculate_letter_grade`(25) = 'D'
    AS 'Test Failed: Score 25 should be D';

  -- Test Case: Zero score
  ASSERT `grade_calculator_prod.calculate_letter_grade`(0) = 'D'
    AS 'Test Failed: Score 0 should be D';

  -- Test Case: Negative score (edge case)
  ASSERT `grade_calculator_prod.calculate_letter_grade`(-10) = 'D'
    AS 'Test Failed: Score -10 should be D';

  -- Test Case: NULL input
  ASSERT `grade_calculator_prod.calculate_letter_grade`(NULL) IS NULL
    AS 'Test Failed: NULL score should result in NULL grade';

END;
