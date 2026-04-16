-- Test suite for all SQL routines related to TR-GRD-001.
-- To run, execute this entire script in the BigQuery console.
--
-- PRE-REQUISITES:
-- 1. The UDF and Stored Procedure must be deployed to the dataset specified below.
-- 2. Replace `your_project` and `your_dataset` with your BQ project and dataset.
-- 3. Replace `your_temp_dataset` with a dataset designated for temporary test objects.

BEGIN

  -- =================================================================================
  -- Test Suite: udf_calculate_academic_grade
  -- =================================================================================

  -- Test Case 1: Grade 'A' - Lower boundary
  ASSERT `your_project.your_dataset.udf_calculate_academic_grade`('90') = 'A' AS 'UDF Test Failed: Grade A lower boundary';

  -- Test Case 2: Grade 'A' - High value with decimals
  ASSERT `your_project.your_dataset.udf_calculate_academic_grade`('105.5') = 'A' AS 'UDF Test Failed: Grade A high value';

  -- Test Case 3: Grade 'B' - Upper boundary
  ASSERT `your_project.your_dataset.udf_calculate_academic_grade`('89.999') = 'B' AS 'UDF Test Failed: Grade B upper boundary';

  -- Test Case 4: Grade 'B' - Lower boundary
  ASSERT `your_project.your_dataset.udf_calculate_academic_grade`('75') = 'B' AS 'UDF Test Failed: Grade B lower boundary';

  -- Test Case 5: Grade 'C' - Upper boundary
  ASSERT `your_project.your_dataset.udf_calculate_academic_grade`('74.9') = 'C' AS 'UDF Test Failed: Grade C upper boundary';

  -- Test Case 6: Grade 'C' - Lower boundary
  ASSERT `your_project.your_dataset.udf_calculate_academic_grade`('60') = 'C' AS 'UDF Test Failed: Grade C lower boundary';

  -- Test Case 7: Grade 'D' - Upper boundary
  ASSERT `your_project.your_dataset.udf_calculate_academic_grade`('59.99') = 'D' AS 'UDF Test Failed: Grade D upper boundary';

  -- Test Case 8: Grade 'D' - Zero value
  ASSERT `your_project.your_dataset.udf_calculate_academic_grade`('0') = 'D' AS 'UDF Test Failed: Grade D zero value';

  -- Test Case 9: Grade 'D' - Negative value
  ASSERT `your_project.your_dataset.udf_calculate_academic_grade`('-10') = 'D' AS 'UDF Test Failed: Grade D negative value';

  -- Test Case 10: Input Validation - Non-numeric string
  ASSERT `your_project.your_dataset.udf_calculate_academic_grade`('abc') IS NULL AS 'UDF Test Failed: Non-numeric input';

  -- Test Case 11: Input Validation - Empty string
  ASSERT `your_project.your_dataset.udf_calculate_academic_grade`('') IS NULL AS 'UDF Test Failed: Empty string input';

  -- Test Case 12: Input Validation - NULL input
  ASSERT `your_project.your_dataset.udf_calculate_academic_grade`(NULL) IS NULL AS 'UDF Test Failed: NULL input';


  -- =================================================================================
  -- Test Suite: sp_process_score_and_log
  -- =================================================================================
  DECLARE temp_log_table_id STRING;
  DECLARE log_results ARRAY<STRUCT<input_score STRING, calculated_grade STRING, status STRING, error_message STRING>>;

  -- Create a temporary table for logging during the test. Name is randomized.
  SET temp_log_table_id = FORMAT(
    '`%s.%s.temp_log_%s`',
    @@project_id,
    'your_temp_dataset', -- NOTE: Replace with a dataset for temporary objects
    REPLACE(CAST(GENERATE_UUID() AS STRING), '-', '_')
  );

  EXECUTE IMMEDIATE FORMAT("""
    CREATE TABLE %s (
      ingestion_timestamp TIMESTAMP,
      input_score STRING,
      calculated_grade STRING,
      status STRING,
      error_message STRING
    )
  """, temp_log_table_id);

  -- Call procedure for various cases
  CALL `your_project.your_dataset.sp_process_score_and_log`('95', temp_log_table_id);
  CALL `your_project.your_dataset.sp_process_score_and_log`('42.5', temp_log_table_id);
  CALL `your_project.your_dataset.sp_process_score_and_log`('not-a-number', temp_log_table_id);

  -- Capture the results from the log table into a variable for assertion
  EXECUTE IMMEDIATE FORMAT("SELECT ARRAY_AGG(STRUCT(input_score, calculated_grade, status, error_message) ORDER BY input_score) FROM %s", temp_log_table_id)
  INTO log_results;

  -- Assertions on the log table content
  ASSERT (SELECT COUNT(1) FROM UNNEST(log_results)) = 3 AS 'SP Test Failed: Expected 3 log entries';
  ASSERT (SELECT COUNT(1) FROM UNNEST(log_results) WHERE status = 'SUCCESS') = 2 AS 'SP Test Failed: Expected 2 SUCCESS entries';
  ASSERT (SELECT COUNT(1) FROM UNNEST(log_results) WHERE status = 'VALIDATION_ERROR') = 1 AS 'SP Test Failed: Expected 1 VALIDATION_ERROR entry';
  ASSERT (SELECT calculated_grade FROM UNNEST(log_results) WHERE input_score = '95') = 'A' AS 'SP Test Failed: Grade A for score 95';
  ASSERT (SELECT calculated_grade FROM UNNEST(log_results) WHERE input_score = '42.5') = 'D' AS 'SP Test Failed: Grade D for score 42.5';
  ASSERT (SELECT calculated_grade FROM UNNEST(log_results) WHERE input_score = 'not-a-number') IS NULL AS 'SP Test Failed: NULL grade for invalid score';
  ASSERT (SELECT error_message FROM UNNEST(log_results) WHERE status = 'VALIDATION_ERROR') = 'Input score is not a valid numerical value.' AS 'SP Test Failed: Incorrect error message';

  -- Clean up the temporary log table
  EXECUTE IMMEDIATE FORMAT("DROP TABLE %s", temp_log_table_id);

EXCEPTION WHEN ERROR THEN
  -- This block will be entered if any ASSERT fails.
  -- It also handles cleanup if the script fails mid-execution.
  IF temp_log_table_id IS NOT NULL THEN
    EXECUTE IMMEDIATE IF EXISTS FORMAT("DROP TABLE %s", temp_log_table_id);
  END IF;

  -- Re-raise the original error to make the test failure visible
  SELECT
    @@error.message,
    @@error.stack_trace,
    @@error.statement_text,
    @@error.formatted_stack_trace;
END;
