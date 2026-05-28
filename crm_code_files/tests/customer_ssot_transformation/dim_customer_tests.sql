-- Tests for crm_raw_data_gold.dim_customer

-- test: not_null_dim_customer_customerid
-- The primary key `customerid` must not contain any NULL values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_dim_customer_customerid' AS test_name
FROM
  `gcp-cloud-source-repo.crm_raw_data_gold.dim_customer`
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
    `gcp-cloud-source-repo.crm_raw_data_gold.dim_customer`
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
  `gcp-cloud-source-repo.crm_raw_data_gold.dim_customer` AS t
LEFT JOIN
  `gcp-cloud-source-repo.crm_raw_data_gold.dim_account` AS ref
  ON t.accountid = ref.accountid
WHERE
  t.accountid IS NOT NULL AND ref.accountid IS NULL;