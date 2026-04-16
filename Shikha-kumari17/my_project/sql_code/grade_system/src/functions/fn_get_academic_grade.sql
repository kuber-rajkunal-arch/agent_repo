CREATE OR REPLACE FUNCTION `your_project.your_dataset.fn_get_academic_grade`(
  score NUMERIC
)
RETURNS STRING
AS (
  /*
  * TR-GRD-001: Determines the academic letter grade based on a numerical score.
  *
  * This function implements the grading criteria defined in the technical requirement
  * document. It accepts a numerical score and returns the corresponding letter
  * grade as a string.
  *
  * @param score The numerical score to be evaluated.
  * @return The corresponding academic letter grade ('Grade A', 'Grade B', 'Grade C', 'Grade D')
  *         or NULL if the input score is NULL.
  */
  CASE
    WHEN score >= 90 THEN 'Grade A'
    WHEN score >= 75 THEN 'Grade B'
    WHEN score >= 60 THEN 'Grade C'
    WHEN score < 60 THEN 'Grade D'
    ELSE NULL -- Handles cases where score is NULL
  END
);
