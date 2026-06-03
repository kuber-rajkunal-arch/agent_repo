/*
  Unit tests for the curated.dim_account table.
  These tests verify the data integrity and quality of the transformed account data,
  ensuring that primary keys are valid and transformations have been applied correctly.
*/

-- test: not_null_dim_account_accountid
-- The primary key `accountid` must not contain any NULL values, as it's essential for joining and identification.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_dim_account_accountid' AS test_name
FROM
  `your-gcp-project-id.curated_dataset.dim_account`
WHERE
  accountid IS NULL;

-- test: unique_dim_account_accountid
-- The primary key `accountid` must be unique to ensure each record represents a distinct account.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_dim_account_accountid' AS test_name
FROM (
  SELECT
    accountid
  FROM
    `your-gcp-project-id.curated_dataset.dim_account`
  WHERE
    accountid IS NOT NULL
  GROUP BY
    accountid
  HAVING
    COUNT(*) > 1
);

-- test: trimmed_check_dim_account_fields
-- All string fields should have no leading/trailing whitespace, verifying the TRIM() transformation from the source query.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'trimmed_check_dim_account_fields' AS test_name
FROM
  `your-gcp-project-id.curated_dataset.dim_account`
WHERE
  name <> TRIM(name)
  OR address1_city <> TRIM(address1_city)
  OR address1_state <> TRIM(address1_state)
  OR region <> TRIM(region);