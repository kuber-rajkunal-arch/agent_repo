# Grade System SQL Component

This project contains a production-ready SQL component for determining academic letter grades from numerical scores, based on the requirements specified in `TR-GRD-001`.

## Component Details

-   **Function:** `fn_get_academic_grade(score NUMERIC) RETURNS STRING`
-   **Location:** `src/functions/fn_get_academic_grade.sql`
-   **Description:** This BigQuery User-Defined Function (UDF) takes a numerical score and returns the corresponding letter grade according to the following logic:
    -   `score >= 90` -> 'Grade A'
    -   `75 <= score < 90` -> 'Grade B'
    -   `60 <= score < 75` -> 'Grade C'
    -   `score < 60` -> 'Grade D'

## Deployment

1.  Replace the placeholder `your_project.your_dataset` in the SQL files with your actual BigQuery project and dataset ID.
2.  Deploy the function by running the script in `src/functions/fn_get_academic_grade.sql` in your BigQuery environment.

## Testing

The test suite is located at `tests/test_fn_get_academic_grade.sql`.

To run the tests:
1.  Ensure the `fn_get_academic_grade` function has been deployed to your BigQuery project.
2.  Execute the test script in the BigQuery console.
3.  The script will run a series of assertions. If all tests pass, the script will complete without errors. If a test fails, it will raise an error with details about the failure.
