-- Technical Requirement ID: TR-GRD-001
-- Deploys the stored procedure to process a score and log the result.
-- This procedure depends on `udf_calculate_academic_grade`.
--
-- To deploy, replace `your_project` and `your_dataset` with your BigQuery project and dataset.
CREATE OR REPLACE PROCEDURE `your_project.your_dataset.sp_process_score_and_log`(
  IN score_input STRING,
  IN log_table_id STRING
)
BEGIN
  -- This procedure orchestrates the grade calculation and logging as per TR-GRD-001.

  DECLARE calculated_grade STRING;
  DECLARE log_status STRING;
  DECLARE error_message STRING;

  -- Stage 1: Receive Input Score (handled by procedure IN parameter)
  -- Stage 2 & 3: Evaluate Score and Determine Grade by calling the UDF.
  SET calculated_grade = `your_project.your_dataset.udf_calculate_academic_grade`(score_input);

  -- Input Validation: Determine status and error message for logging.
  IF calculated_grade IS NULL THEN
    -- Action: If the input is not a valid number, the system shall reject the input and indicate an error.
    SET log_status = 'VALIDATION_ERROR';
    SET error_message = 'Input score is not a valid numerical value.';
  ELSE
    -- Action: Record successful grade calculations.
    SET log_status = 'SUCCESS';
    SET error_message = NULL;
  END IF;

  -- Stage 4: Output Grade (by logging)
  -- Logging: Log the input score and the determined grade for traceability.
  EXECUTE IMMEDIATE FORMAT("""
    INSERT INTO `%s` (ingestion_timestamp, input_score, calculated_grade, status, error_message)
    VALUES(CURRENT_TIMESTAMP(), ?, ?, ?, ?);
  """, log_table_id)
  USING score_input, calculated_grade, log_status, error_message;

END;
