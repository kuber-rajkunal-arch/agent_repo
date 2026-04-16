/*
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

-- Test suite for the `calculate_academic_grade` function.
-- Before running, ensure the function has been deployed to the specified dataset.
-- Replace `your_project.your_dataset` with the project and dataset where the
-- function is located.

BEGIN

  -- Test case data
  DECLARE test_cases ARRAY<STRUCT<
    test_name STRING,
    input_score ANY TYPE,
    expected_grade STRING
  >> DEFAULT [
    -- Grade 'A' tests
    ('Score at lower bound for A', 90, 'A'),
    ('Score within A range', 95.5, 'A'),
    ('Score well above A range', 110, 'A'),

    -- Grade 'B' tests
    ('Score at lower bound for B', 75, 'B'),
    ('Score just below A', 89.9, 'B'),
    ('Score within B range', 82, 'B'),

    -- Grade 'C' tests
    ('Score at lower bound for C', 60, 'C'),
    ('Score just below B', 74.9, 'C'),
    ('Score within C range', 68.7, 'C'),

    -- Grade 'D' tests
    ('Score just below C', 59.9, 'D'),
    ('Score within D range', 30, 'D'),
    ('Zero score', 0, 'D'),
    ('Negative score', -15, 'D'),

    -- Input validation tests
    ('Invalid string input', 'ninety', 'Invalid input: score must be a numerical value.'),
    ('NULL input', NULL, 'Invalid input: score must be a numerical value.'),
    ('Empty string input', '', 'Invalid input: score must be a numerical value.')
  ];

  -- Loop through test cases and assert results
  FOR test IN (SELECT * FROM UNNEST(test_cases))
  DO
    ASSERT
      `your_project.your_dataset.calculate_academic_grade`(test.input_score) = test.expected_grade
      AS FORMAT("Test '%s' failed: Expected '%s' for input %T, but got '%s'",
                test.test_name,
                test.expected_grade,
                test.input_score,
                `your_project.your_dataset.calculate_academic_grade`(test.input_score)
      );
  END FOR;

  -- If all assertions pass, this message will be displayed.
  SELECT 'All tests for calculate_academic_grade passed successfully.' AS status;

EXCEPTION WHEN ERROR THEN
  -- This block will be executed if any ASSERT statement fails.
  SELECT
    @@error.message,
    @@error.stack_trace,
    @@error.statement_text,
    @@error.formatted_stack_trace;
END;