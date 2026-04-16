/*
TR-GRD-001: Test script for `udf_determine_academic_grade`.

Description:
  This script validates the correctness of the academic grading function by
  running a set of deterministic tests. It covers boundary conditions,
  values within each grade bracket, and edge cases like NULL or negative inputs.

Execution:
  1. Ensure the function `bq_project.bq_dataset.udf_determine_academic_grade` has been
     deployed to your BigQuery environment.
  2. Replace `bq_project` and `bq_dataset` in this script with the correct
     project and dataset IDs.
  3. Run this script in the BigQuery console. A success message will be displayed
     if all tests pass. The script will raise an error if any test fails.
*/
BEGIN

  -- A temporary table to hold all test cases and their expected outcomes.
  DECLARE test_cases ARRAY<STRUCT<test_name STRING, score NUMERIC, expected_grade STRING>> DEFAULT [
    -- Grade 'A' tests
    ('Upper bound', 105, 'A'),
    ('Exact boundary A', 90, 'A'),
    -- Grade 'B' tests
    ('Upper boundary B', 89.99, 'B'),
    ('Mid-range B', 82, 'B'),
    ('Exact boundary B', 75, 'B'),
    -- Grade 'C' tests
    ('Upper boundary C', 74.99, 'C'),
    ('Mid-range C', 68, 'C'),
    ('Exact boundary C', 60, 'C'),
    -- Grade 'D' tests
    ('Upper boundary D', 59.99, 'D'),
    ('Zero score', 0, 'D'),
    ('Negative score', -50, 'D'),
    -- NULL input test
    ('NULL score', NULL, NULL)
  ];

  -- This temporary table will store the results of any failed tests.
  CREATE TEMP TABLE test_failures AS
  WITH
    -- Unnest the test cases array into rows for processing.
    tests AS (
      SELECT * FROM UNNEST(test_cases)
    ),
    -- Execute the function against each test case.
    results AS (
      SELECT
        test_name,
        score,
        expected_grade,
        `bq_project.bq_dataset.udf_determine_academic_grade`(score) AS actual_grade
      FROM tests
    )
  -- Select only the rows where the actual result does not match the expected result.
  -- SAFE.EQUAL is used for correct handling of NULL comparisons.
  SELECT *
  FROM results
  WHERE NOT SAFE.EQUAL(actual_grade, expected_grade);

  -- Assert that the count of failures is zero.
  -- If this assertion fails, the script will stop and raise an error with the
  -- provided message, indicating which tests failed.
  ASSERT (SELECT COUNT(1) FROM test_failures) = 0 AS
    FORMAT(
      "Test failures detected for udf_determine_academic_grade. Mismatched results:\n%T",
      (SELECT ARRAY_AGG(t) FROM test_failures t)
    );

  -- If the script reaches this point, all tests have passed.
  SELECT 'All tests for `bq_project.bq_dataset.udf_determine_academic_grade` passed successfully.' AS status;

END;
