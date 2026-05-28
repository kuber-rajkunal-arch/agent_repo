-- Tests for crm_raw_data_gold.dim_account

-- test: not_null_dim_account_accountid
-- The primary key `accountid` must not contain any NULL values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_dim_account_accountid' AS test_name
FROM
  `gcp-cloud-source-repo.crm_raw_data_gold.dim_account`
WHERE
  accountid IS NULL;

-- test: unique_dim_account_accountid
-- The primary key `accountid` must be unique across all records.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_dim_account_accountid' AS test_name
FROM (
  SELECT
    accountid
  FROM
    `gcp-cloud-source-repo.crm_raw_data_gold.dim_account`
  WHERE
    accountid IS NOT NULL
  GROUP BY
    accountid
  HAVING
    COUNT(*) > 1
);