-- ============================================================================
-- Unit Tests for `dim_account`
-- ============================================================================

-- test: not_null_accountid
-- The primary key `accountid` must be populated for every record.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_accountid' AS test_name,
  'The primary key `accountid` must be populated for every record.' AS description
FROM `your_project_id.curated_dataset.dim_account`
WHERE accountid IS NULL;

-- test: unique_accountid
-- The primary key `accountid` must be unique across the table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_accountid' AS test_name,
  'The primary key `accountid` must be unique across the table.' AS description
FROM (
  SELECT
    accountid
  FROM `your_project_id.curated_dataset.dim_account`
  WHERE accountid IS NOT NULL
  GROUP BY 1
  HAVING COUNT(*) > 1
);

-- test: not_null_name
-- The account `name` is a critical business identifier and should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_name' AS test_name,
  'The account `name` should always be populated.' AS description
FROM `your_project_id.curated_dataset.dim_account`
WHERE name IS NULL;