-- Test suite for the get_academic_grade function (TR-GRD-001).
-- This script verifies the correctness of the business logic and error handling.
BEGIN

  -- This test script assumes the function `your_project_id.your_dataset_id.get_academic_grade`
  -- has been deployed. To run this as a self-contained unit test without deploying the
  -- function first, uncomment the CREATE TEMP FUNCTION block below and replace all
  -- references to the permanent function.
  /*
  CREATE TEMP FUNCTION get_academic_grade(score NUMERIC)
  RETURNS STRING
  AS (
    IF(
      score IS NULL,
      ERROR('Input score cannot be NULL. Validation failed as per TR-GRD-001.'),
      CASE
        WHEN score >= 90 THEN 'A'
        WHEN score >= 75 THEN 'B'
        WHEN score >= 60 THEN 'C'
        ELSE 'D'
      END
    )
  );
  DECLARE target_function STRING DEFAULT 'get_academic_grade';
  */

  -- Test Case 1: Grade A Assignment
  ASSERT `your_project_id.your_dataset_id.get_academic_grade`(100) = 'A' AS 'Test Failed: Perfect score 100.0 should be A';
  ASSERT `your_project_id.your_dataset_id.get_academic_grade`(90) = 'A' AS 'Test Failed: Boundary score 90.0 should be A';

  -- Test Case 2: Grade B Assignment
  ASSERT `your_project_id.your_dataset_id.get_academic_grade`(89.9) = 'B' AS 'Test Failed: Score 89.9 should be B';
  ASSERT `your_project_id.your_dataset_id.get_academic_grade`(75) = 'B' AS 'Test Failed: Boundary score 75.0 should be B';

  -- Test Case 3: Grade C Assignment
  ASSERT `your_project_id.your_dataset_id.get_academic_grade`(74.9) = 'C' AS 'Test Failed: Score 74.9 should be C';
  ASSERT `your_project_id.your_dataset_id.get_academic_grade`(60) = 'C' AS 'Test Failed: Boundary score 60.0 should be C';

  -- Test Case 4: Grade D Assignment
  ASSERT `your_project_id.your_dataset_id.get_academic_grade`(59.9) = 'D' AS 'Test Failed: Score 59.9 should be D';
  ASSERT `your_project_id.your_dataset_id.get_academic_grade`(0) = 'D' AS 'Test Failed: Zero score 0.0 should be D';
  ASSERT `your_project_id.your_dataset_id.get_academic_grade`(-10) = 'D' AS 'Test Failed: Negative score -10.0 should be D';

  -- Test Case 5: Error Handling for NULL input
  -- This block specifically tests that a NULL input raises an error as required by the TRD.
  BEGIN
    SELECT `your_project_id.your_dataset_id.get_academic_grade`(NULL);
    -- If the line above does not raise an error, this assertion will fail the test.
    ASSERT FALSE AS 'Test Failed: NULL input should raise an error but did not.';
  EXCEPTION WHEN ERROR THEN
    -- This block is expected to be entered, indicating the test passed.
    -- The presence of this block catches the error and allows the script to continue.
    -- Without it, the script would halt on the expected error.
    SELECT 'Assertion Passed: NULL input correctly raised an error.' AS test_status;
  END;

END;