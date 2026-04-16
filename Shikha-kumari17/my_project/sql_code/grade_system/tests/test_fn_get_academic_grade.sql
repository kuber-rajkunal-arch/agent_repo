-- Test suite for the fn_get_academic_grade function.
--
-- To run this test, ensure the function `your_project.your_dataset.fn_get_academic_grade`
-- has been deployed in your BigQuery environment. This script will then execute
-- a series of assertions to validate its correctness against predefined test cases.
--
BEGIN
  -- Define a table of test cases including boundary values, typical values, and edge cases.
  DECLARE test_cases ARRAY<STRUCT<test_name STRING, score NUMERIC, expected_grade STRING>> DEFAULT [
    ('Score above Grade A threshold', 95.5, 'Grade A'),
    ('Score at Grade A threshold', 90, 'Grade A'),
    ('Score just below Grade A threshold', 89.9, 'Grade B'),
    ('Score above Grade B threshold', 82, 'Grade B'),
    ('Score at Grade B threshold', 75, 'Grade B'),
    ('Score just below Grade B threshold', 74.9, 'Grade C'),
    ('Score above Grade C threshold', 67, 'Grade C'),
    ('Score at Grade C threshold', 60, 'Grade C'),
    ('Score just below Grade C threshold', 59.9, 'Grade D'),
    ('Score in Grade D range', 45, 'Grade D'),
    ('Zero score', 0, 'Grade D'),
    ('Negative score', -10, 'Grade D'),
    ('Null score input', NULL, NULL)
  ];

  DECLARE i INT64 DEFAULT 0;

  -- Iterate through each test case and assert the function's output.
  WHILE i < ARRAY_LENGTH(test_cases) DO
    DECLARE current_test STRUCT<test_name STRING, score NUMERIC, expected_grade STRING>;
    DECLARE actual_grade STRING;

    SET current_test = test_cases[ORDINAL(i + 1)];
    SET actual_grade = `your_project.your_dataset.fn_get_academic_grade`(current_test.score);

    -- Assert that the actual result is not distinct from the expected result.
    -- This correctly handles NULL-to-NULL comparisons.
    ASSERT actual_grade IS NOT DISTINCT FROM current_test.expected_grade
      AS FORMAT(
        "Test Failed: %s\n  - Score: %t\n  - Expected: %t\n  - Got: %t",
        current_test.test_name,
        current_test.score,
        current_test.expected_grade,
        actual_grade
      );

    SET i = i + 1;
  END WHILE;

  -- If all assertions pass, the script completes successfully.
END;
