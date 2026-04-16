-- Copyright 2023 Your Company
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

CREATE OR REPLACE FUNCTION `your_project.your_dataset.calculate_letter_grade`(
  score NUMERIC
)
RETURNS STRING
AS (
  -- TR-GRD-001: Implements the academic grade calculation based on a numerical score.
  -- This function evaluates the score against predefined grading thresholds
  -- and returns the corresponding letter grade.
  CASE
    -- Step: Grade Assignment for 'A'
    -- Transformation Logic: IF score >= 90 THEN 'A'
    WHEN score >= 90 THEN 'A'

    -- Step: Grade Assignment for 'B'
    -- Transformation Logic: ELSE IF score >= 75 AND score < 90 THEN 'B'
    WHEN score >= 75 AND score < 90 THEN 'B'

    -- Step: Grade Assignment for 'C'
    -- Transformation Logic: ELSE IF score >= 60 AND score < 75 THEN 'C'
    WHEN score >= 60 AND score < 75 THEN 'C'

    -- Step: Grade Assignment for 'D'
    -- Transformation Logic: ELSE IF score < 60 THEN 'D'
    WHEN score < 60 THEN 'D'

    -- Per TRD, behavior for inputs not covered by the above logic is undefined.
    -- The CASE statement will return NULL for such cases (e.g., a NULL input score).
    ELSE NULL
  END
);