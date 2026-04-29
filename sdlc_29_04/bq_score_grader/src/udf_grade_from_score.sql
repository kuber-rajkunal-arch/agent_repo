-- Technical Requirement ID: TR-GRD-001
-- Description: Core grade assignment logic based on a numerical score.

CREATE OR REPLACE FUNCTION `your_project_id.your_dataset_id.grade_from_score`(
  score NUMERIC
)
RETURNS STRING
OPTIONS(
  description="Assigns an academic grade based on a numerical score using conditional logic."
)
AS (
  -- Transformation Logic:
  -- IF score >= 90 THEN assign 'Grade A'.
  -- ELSE IF score >= 75 THEN assign 'Grade B'.
  -- ELSE IF score >= 60 THEN assign 'Grade C'.
  -- ELSE (if score < 60) THEN assign 'Grade D'.
  CASE
    WHEN score IS NULL THEN NULL
    WHEN score >= 90 THEN 'Grade A'
    WHEN score >= 75 THEN 'Grade B'
    WHEN score >= 60 THEN 'Grade C'
    ELSE 'Grade D'
  END
);
