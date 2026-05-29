-- File: tests/customer_ssot/test_dim_sales_rep.sql
-- Description: Unit tests for the curated dim_sales_rep table.

-- test: not_null_salesrepid
-- Ensures the primary key column `salesrepid` is never NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_salesrepid' AS test_name
FROM
  `${project_id}.${curated_dataset}.dim_sales_rep`
WHERE
  salesrepid IS NULL;

-- test: unique_salesrepid
-- Ensures that every `salesrepid` is unique.
SELECT
  IF(COUNT(salesrepid) = COUNT(DISTINCT salesrepid), 'PASS', 'FAIL') AS result,
  'unique_salesrepid' AS test_name
FROM
  `${project_id}.${curated_dataset}.dim_sales_rep`;

-- test: not_null_name
-- The sales rep name is a fundamental business attribute and should always be present.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_name' AS test_name
FROM
  `${project_id}.${curated_dataset}.dim_sales_rep`
WHERE
  name IS NULL;