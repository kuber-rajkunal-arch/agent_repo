-- Technical Requirement ID: TR-GRD-001
-- Deploys the user-defined function to calculate an academic grade from a numerical score.
--
-- To deploy, replace `your_project` and `your_dataset` with your BigQuery project and dataset.
CREATE OR REPLACE FUNCTION `your_project.your_dataset.udf_calculate_academic_grade`(
  score_input STRING
)
RETURNS STRING
AS (
  (
    -- Stage 2: Evaluate Score
    -- Stage 3: Determine Grade
    -- The logic uses SAFE_CAST to handle the input validation requirement.
    -- If score_input is not a valid number, SAFE_CAST returns NULL,
    -- which causes the scalar subquery to return NULL, indicating an error.
    SELECT
      CASE
        -- Step 1: Grade 'A' Assignment
        WHEN score >= 90 THEN 'A'
        -- Step 2: Grade 'B' Assignment
        WHEN score >= 75 THEN 'B'
        -- Step 3: Grade 'C' Assignment
        WHEN score >= 60 THEN 'C'
        -- Step 4: Grade 'D' Assignment
        ELSE 'D'
      END
    FROM (SELECT SAFE_CAST(score_input AS NUMERIC) AS score)
    WHERE score IS NOT NULL
  )
);
