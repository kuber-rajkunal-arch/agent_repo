-- File: tests/customer_ssot/test_dim_account.sql
-- Description: Unit tests for the curated dim_account table.

-- test: not_null_accountid
-- Ensures the primary key column `accountid` in dim_account is never NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_accountid' AS test_name
FROM
  `${project_id}.${curated_dataset}.dim_account`
WHERE
  accountid IS NULL;

-- test: unique_accountid
-- Ensures that every `accountid` in dim_account is unique, which is critical for a dimension table's primary key.
-- This also validates the effectiveness of the MERGE statement's ON clause and deduplication logic.
SELECT
  IF(COUNT(accountid) = COUNT(DISTINCT accountid), 'PASS', 'FAIL') AS result,
  'unique_accountid' AS test_name
FROM
  `${project_id}.${curated_dataset}.dim_account`;

-- test: not_null_name
-- The account name is a fundamental business attribute and should always be present.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_name' AS test_name
FROM
  `${project_id}.${curated_dataset}.dim_account`
WHERE
  name IS NULL;