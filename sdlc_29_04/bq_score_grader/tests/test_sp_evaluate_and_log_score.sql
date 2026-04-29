-- Test script for sp_evaluate_and_log_score
-- This script creates temporary log tables, calls the procedure for success and error cases,
-- and asserts the expected outcomes. The script will complete successfully if all tests pass.

BEGIN

  -- Create temporary tables for logging within the scope of this test script.
  CREATE TEMP TABLE temp_grade_processing_log (
      processed_timestamp TIMESTAMP,
      input_score NUMERIC,
      assigned_grade STRING
  );

  CREATE TEMP TABLE temp_grade_error_log (
      error_timestamp TIMESTAMP,
      invalid_input STRING,
      error_message STRING
  );

  -- Test Case 1: Successful processing of a valid score.
  BEGIN
    DECLARE grade_output STRING;
    -- Call the procedure with a valid score.
    CALL `your_project_id.your_dataset_id.sp_evaluate_and_log_score`('88.5', grade_output);

    -- Assert the OUT parameter has the correct grade.
    ASSERT grade_output = 'Grade B' AS 'Test Case 1 Failed: Incorrect grade for score 88.5';

    -- Assert that the success log was written to correctly.
    ASSERT (
      SELECT COUNT(1)
      FROM temp_grade_processing_log
      WHERE input_score = 88.5 AND assigned_grade = 'Grade B'
    ) = 1 AS 'Test Case 1 Failed: Success log entry not found or incorrect.';

    -- Assert that the error log remains empty.
    ASSERT (SELECT COUNT(1) FROM temp_grade_error_log) = 0 AS 'Test Case 1 Failed: Error log should be empty.';
  END;


  -- Test Case 2: Handling of an invalid (non-numeric) score.
  BEGIN
    DECLARE grade_output STRING;
    -- This call is expected to raise an exception.
    CALL `your_project_id.your_dataset_id.sp_evaluate_and_log_score`('ninety', grade_output);

    -- This line should not be reached. If it is, the test fails because no error was raised.
    ASSERT FALSE AS 'Test Case 2 Failed: Procedure did not raise an error for invalid input "ninety".';

  EXCEPTION WHEN ERROR THEN
    -- The procedure correctly raised an error. Now, verify the error was logged.
    ASSERT (
      SELECT COUNT(1)
      FROM temp_grade_error_log
      WHERE invalid_input = 'ninety' AND error_message = 'Invalid input: Not a valid number.'
    ) = 1 AS 'Test Case 2 Failed: Error log entry not found or incorrect.';
  END;

END;