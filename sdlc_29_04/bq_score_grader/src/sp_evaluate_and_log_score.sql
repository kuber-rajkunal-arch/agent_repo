-- Technical Requirement ID: TR-GRD-001
-- Description: Stored procedure to evaluate a single score, with logging and error handling.

CREATE OR REPLACE PROCEDURE `your_project_id.your_dataset_id.sp_evaluate_and_log_score`(
  IN p_score_input STRING,
  OUT p_academic_grade STRING
)
OPTIONS(
  description="Receives a score as a string, validates it, assigns a grade, and logs the result. Raises an error for invalid input."
)
BEGIN
  DECLARE score_numeric NUMERIC;

  -- Attempt to cast the input string to a numeric type.
  SET score_numeric = SAFE_CAST(p_score_input AS NUMERIC);

  -- Step: Validate that the provided score is a valid number.
  IF score_numeric IS NULL THEN
    -- Log details of any invalid input scores encountered.
    INSERT INTO `your_project_id.your_dataset_id.grade_error_log` (error_timestamp, invalid_input, error_message)
    VALUES(CURRENT_TIMESTAMP(), p_score_input, 'Invalid input: Not a valid number.');

    -- If the score is not a valid number, the system shall indicate an error.
    RAISE USING MESSAGE = FORMAT('Invalid input: The provided score "%s" is not a valid number.', p_score_input);

  ELSE
    -- Step: Evaluate Score using the transformation logic encapsulated in the UDF.
    SET p_academic_grade = `your_project_id.your_dataset_id.grade_from_score`(score_numeric);

    -- Log the input numerical score and the assigned grade upon successful processing.
    INSERT INTO `your_project_id.your_dataset_id.grade_processing_log` (processed_timestamp, input_score, assigned_grade)
    VALUES(CURRENT_TIMESTAMP(), score_numeric, p_academic_grade);

    -- The determined academic grade is set in the OUT parameter p_academic_grade.
  END IF;

END;
