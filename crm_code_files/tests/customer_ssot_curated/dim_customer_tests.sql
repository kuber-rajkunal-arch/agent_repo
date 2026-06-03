/*
  Unit tests for the curated.dim_customer table.
  These tests verify the data integrity and quality of the transformed customer data,
  including primary key constraints and referential integrity with the account dimension.
*/

-- test: not_null_dim_customer_customerid
-- The primary key `customerid` must not contain any NULL values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_dim_customer_customerid' AS test_name
FROM
  `your-gcp-project-id.curated_dataset.dim_customer`
WHERE
  customerid IS NULL;

-- test: unique_dim_customer_customerid
-- The primary key `customerid` must be unique across all records.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_dim_customer_customerid' AS test_name
FROM (
  SELECT
    customerid
  FROM
    `your-gcp-project-id.curated_dataset.dim_customer`
  WHERE
    customerid IS NOT NULL
  GROUP BY
    customerid
  HAVING
    COUNT(*) > 1
);

-- test: referential_integrity_dim_customer_accountid
-- Each `accountid` in `dim_customer` must exist as a valid `accountid` in `dim_account`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_dim_customer_accountid' AS test_name
FROM
  `your-gcp-project-id.curated_dataset.dim_customer` AS t
LEFT JOIN
  `your-gcp-project-id.curated_dataset.dim_account` AS ref
  ON t.accountid = ref.accountid
WHERE
  t.accountid IS NOT NULL AND ref.accountid IS NULL;

-- test: trimmed_check_dim_customer_fields
-- All string fields should have no leading/trailing whitespace, verifying the TRIM() transformation.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'trimmed_check_dim_customer_fields' AS test_name
FROM
  `your-gcp-project-id.curated_dataset.dim_customer`
WHERE
  name <> TRIM(name)
  OR telephone1 <> TRIM(telephone1)
  OR industry <> TRIM(industry)
  OR region <> TRIM(region)
  OR accountid <> TRIM(accountid);