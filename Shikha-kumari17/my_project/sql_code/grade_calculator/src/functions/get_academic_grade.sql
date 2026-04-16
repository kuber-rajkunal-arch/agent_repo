-- Technical Requirement ID: TR-GRD-001
-- Objective: Implement a function to determine an academic grade (A, B, C, or D) from a
-- numerical score based on predefined thresholds.
CREATE OR REPLACE FUNCTION `your_project_id.your_dataset_id.get_academic_grade`(score NUMERIC)
RETURNS STRING
AS (
  -- Stage 1: Receive Input Score & Perform Validation
  IF(
    score IS NULL,
    -- Error Handling: Raise an error if the input score is null.
    ERROR('Input score cannot be NULL. Validation failed as per TR-GRD-001.'),
    -- Stage 2: Evaluate Score
    CASE
      -- Step 1: Grade A Assignment
      -- Transformation Logic: IF score >= 90 THEN grade := 'A';
      WHEN score >= 90 THEN 'A'
      -- Step 2: Grade B Assignment
      -- Transformation Logic: ELSIF score >= 75 THEN grade := 'B';
      WHEN score >= 75 THEN 'B'
      -- Step 3: Grade C Assignment
      -- Transformation Logic: ELSIF score >= 60 THEN grade := 'C';
      WHEN score >= 60 THEN 'C'
      -- Step 4: Grade D Assignment
      -- Transformation Logic: ELSE grade := 'D';
      ELSE 'D'
    END
  )
  -- Stage 3: Output Grade (implicit return)
);