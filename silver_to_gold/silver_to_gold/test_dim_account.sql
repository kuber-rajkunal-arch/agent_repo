-- =============================================================================
-- Unit Tests for `curated_dataset.dim_account`
-- =============================================================================

-- test: not_null_accountid
-- Ensures that the primary key `accountid` is never null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_accountid' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_account`
WHERE
  accountid IS NULL;

-- test: unique_accountid
-- Ensures that the primary key `accountid` is unique across the table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_accountid' AS test_name
FROM (
  SELECT
    accountid,
    COUNT(*) AS id_count
  FROM
    `gcp-cloud-source-repo.curated_dataset.dim_account`
  WHERE
    accountid IS NOT NULL
  GROUP BY
    accountid
  HAVING
    id_count > 1
);

-- test: not_null_name
-- The account name is a critical business field and should not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_name' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_account`
WHERE
  name IS NULL;