# Score Grader

This project contains a Google Standard SQL (BigQuery) User-Defined Function (UDF) for converting numerical scores into academic letter grades.

## Description

The UDF `fn_determine_academic_grade` takes a numeric score and returns a string grade ('A', 'B', 'C', or 'D') based on a set of predefined thresholds.

- **TRD:** `TR-GRD-001`
- **FRD:** `FR-GRD-001`

## Structure

- `src/`: Contains the SQL source code for the UDF.
- `tests/`: Contains the SQL script for testing the UDF.
- `data/`: Placeholder for data files.

## Usage

1.  Deploy the function in `src/fn_determine_academic_grade.sql` to your BigQuery dataset. Remember to replace `your_dataset` with the actual name of your target dataset.
2.  Call the function in your queries:
    ```sql
    SELECT your_dataset.fn_determine_academic_grade(85) as grade;
    ```

## Testing

Run the script in `tests/test_fn_determine_academic_grade.sql` using the BigQuery query editor. The script is self-contained and will report an error if any test case fails.
