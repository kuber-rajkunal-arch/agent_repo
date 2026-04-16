-- Copyright 2023 Google LLC
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

/*
*   TRD-ID: TR-GRD-001
*   Objective: Implements a system component to calculate and assign a letter grade
*              to a student based on their numerical assessment score.
*/
CREATE OR REPLACE FUNCTION grade_assignment.calculate_student_grade(marks NUMERIC)
RETURNS STRING
AS (
  -- TR-GRD-001: 9. Input Validation: Validate that the received marks are a
  -- valid non-negative numerical value. Log an error if invalid.
  -- The ERROR() function will halt execution and log the error message in the
  -- job history, fulfilling the logging requirement.
  IF(marks IS NULL OR marks < 0, ERROR('Input marks must be a non-negative numerical value.'),
    -- TR-GRD-001: 8. Data Transformations / Business Logic
    CASE
      -- Step 1: Grade A Determination
      WHEN marks >= 90 THEN 'Grade A'
      -- Step 2: Grade B Determination
      WHEN marks >= 75 THEN 'Grade B'
      -- Step 3: Grade C Determination
      WHEN marks >= 50 THEN 'Grade C'
      -- Step 4: Fail Determination
      ELSE 'Fail'
    END
  )
);
/*
* NOTE on Logging:
* Per TRD-GRD-001, requirement 9:
* - "Log an error if invalid input is detected": Handled via the ERROR() function.
* - "Log any unexpected errors": Handled by the BigQuery execution engine.
* - "Log the final assigned grade": This is an operational concern of the calling
*   process (e.g., an ETL script or a MERGE statement). User-Defined Functions
*   should be pure (i.e., without side effects like writing to a log table) to
*   ensure reusability and predictable behavior. The calling process is
*   responsible for logging the output of this function.
*/