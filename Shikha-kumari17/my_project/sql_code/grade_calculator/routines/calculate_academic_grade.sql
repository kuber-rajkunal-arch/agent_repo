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

-- TR-GRD-001: This function calculates an academic grade from a numerical score.
-- It should be deployed to a shared BigQuery dataset (e.g., `grade_management`).
-- Replace `your_project.your_dataset` with the target project and dataset.

CREATE OR REPLACE FUNCTION `your_project.your_dataset.calculate_academic_grade`(score ANY TYPE)
RETURNS STRING
AS ((
  WITH validation AS (
    SELECT SAFE_CAST(score AS NUMERIC) AS numeric_score
  )
  SELECT
    CASE
      -- Input Validation: Handle non-numerical input as per TRD.
      WHEN v.numeric_score IS NULL
        THEN 'Invalid input: score must be a numerical value.'
      -- Grade Calculation: Apply grading thresholds.
      WHEN v.numeric_score >= 90 THEN 'A'
      WHEN v.numeric_score >= 75 THEN 'B'
      WHEN v.numeric_score >= 60 THEN 'C'
      ELSE 'D'
    END
  FROM validation AS v
));