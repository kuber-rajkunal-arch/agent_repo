-- File: tests/customer_ssot/test_dim_customer.sql
-- Description: Unit tests for the curated dim_customer table.

-- test: not_null_customerid
-- Ensures the primary key column `customerid` in dim_customer is never NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_customerid' AS test_name
FROM
  `${project_id}.${curated_dataset}.dim_customer`
WHERE
  customerid IS NULL;

-- test: unique_customerid
-- Ensures that every `customerid` in dim_customer is unique.
SELECT
  IF(COUNT(customerid) = COUNT(DISTINCT customerid), 'PASS', 'FAIL') AS result,
  'unique_customerid' AS test_name
FROM
  `${project_id}.${curated_dataset}.dim_customer`;

-- test: not_null_accountid
-- The foreign key to dim_account should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_accountid' AS test_name
FROM
  `${project_id}.${curated_dataset}.dim_customer`
WHERE
  accountid IS NULL;

-- test: referential_integrity_accountid
-- Verifies that every `accountid` in dim_customer exists in the dim_account table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_accountid' AS test_name
FROM (
  SELECT
    cust.accountid
  FROM
    `${project_id}.${curated_dataset}.dim_customer` AS cust
  LEFT JOIN
    `${project_id}.${curated_dataset}.dim_account` AS acct
    ON cust.accountid = acct.accountid
  WHERE
    acct.accountid IS NULL
    AND cust.accountid IS NOT NULL
);