/*
  Test Suite for process_scores Procedure

  Purpose:
  Verifies the end-to-end functionality of the score processing pipeline.
  It checks input validation, grade calculation, and logging/error reporting.

  Execution:
  This script must be run in a BigQuery project where the following have been deployed:
  1. `grade_calculator_prod.calculate_letter_grade` UDF
  2. `grade_calculator_prod.process_scores` Stored Procedure

  The script creates temporary tables for source and target, so no cleanup is needed.
  It will raise an error if any final assertion fails.
*/
BEGIN
  -- 1. Setup: Create a temporary source table with test data
  CREATE OR REPLACE TEMP TABLE TestSourceData (
    student_id STRING,
    score_text STRING
  );

  INSERT INTO TestSourceData (student_id, score_text)
  VALUES
    ('student-01', '95.5'),    -- Expected: A
    ('student-02', '90'),      -- Expected: A
    ('student-03', '75'),      -- Expected: B
    ('student-04', '60.0'),    -- Expected: C
    ('student-05', '59.9'),    -- Expected: D
    ('student-06', 'invalid'), -- Expected: Error
    ('student-07', NULL),      -- Expected: Error (NULL score)
    ('student-08', '88');      -- Expected: B

  -- 2. Execution: Call the procedure to process the test data
  -- The target table will be created by the procedure.
  -- We use a temporary table name for the target.
  CALL `grade_calculator_prod.process_scores`(
    'TestSourceData',
    'score_text',
    'temp_db.TestTargetData' -- BigQuery requires temporary tables to be qualified with a schema
  );

  -- 3. Verification: Assert the contents of the resulting target table
  -- We perform checks in a single ASSERT statement for atomicity.
  ASSERT (
    WITH ResultValidation AS (
      SELECT
        (SELECT COUNT(1) FROM temp_db.TestTargetData) AS total_rows,
        COUNTIF(letter_grade = 'A') AS grade_a_count,
        COUNTIF(letter_grade = 'B') AS grade_b_count,
        COUNTIF(letter_grade = 'C') AS grade_c_count,
        COUNTIF(letter_grade = 'D') AS grade_d_count,
        COUNTIF(processing_status LIKE 'Invalid input%') AS error_count,
        COUNTIF(input_score = 'invalid' AND processing_status LIKE "Invalid input: Score 'invalid' is not a valid number.") > 0 AS invalid_text_message_correct,
        COUNTIF(input_score IS NULL AND processing_status = 'Invalid input: Score is NULL.') > 0 AS null_input_message_correct
      FROM
        temp_db.TestTargetData
    )
    SELECT
      total_rows = 8
      AND grade_a_count = 2
      AND grade_b_count = 2
      AND grade_c_count = 1
      AND grade_d_count = 1
      AND error_count = 2
      AND invalid_text_message_correct
      AND null_input_message_correct
    FROM ResultValidation
  ) AS 'Test Failed: The output of process_scores did not match expected results.';

END;
