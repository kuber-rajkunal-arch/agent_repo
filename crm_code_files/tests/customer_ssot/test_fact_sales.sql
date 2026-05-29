-- File: tests/customer_ssot/test_fact_sales.sql
-- Description: Unit tests for the curated fact_sales table.

-- test: not_null_salesorderid
-- Ensures the primary key column `salesorderid` is never NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_salesorderid' AS test_name
FROM
  `${project_id}.${curated_dataset}.fact_sales`
WHERE
  salesorderid IS NULL;

-- test: unique_salesorderid
-- Ensures that every `salesorderid` is unique.
SELECT
  IF(COUNT(salesorderid) = COUNT(DISTINCT salesorderid), 'PASS', 'FAIL') AS result,
  'unique_salesorderid' AS test_name
FROM
  `${project_id}.${curated_dataset}.fact_sales`;

-- test: not_null_totalamount
-- Verifies that the SAFE_CAST on `totalamount` did not result in unexpected NULLs.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_totalamount' AS test_name
FROM
  `${project_id}.${curated_dataset}.fact_sales`
WHERE
  totalamount IS NULL;

-- test: referential_integrity_customerid
-- Verifies that every `customerid` in fact_sales exists in the dim_customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customerid' AS test_name
FROM (
  SELECT
    fs.customerid
  FROM
    `${project_id}.${curated_dataset}.fact_sales` AS fs
  LEFT JOIN
    `${project_id}.${curated_dataset}.dim_customer` AS cust
    ON fs.customerid = cust.customerid
  WHERE
    cust.customerid IS NULL
    AND fs.customerid IS NOT NULL
);