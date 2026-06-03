-- UNIT TESTS
-- test: column_a_is_not_null
SELECT
  IF(COUNTIF(column_a IS NULL) = 0, 'PASS', 'FAIL') AS result,
  'column_a_is_not_null' AS test_name
FROM `gcp-cloud-source-repo.phenominal.correction_table`
;

-- test: column_b_has_value
SELECT
  IF(COUNT(*) > 0, 'PASS', 'FAIL') AS result,
  'column_b_has_value' AS test_name
FROM `gcp-cloud-source-repo.phenominal.correction_table`
WHERE column_b = 'dummy_value'
;
