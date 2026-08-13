/*
  Unit tests for the Curated.customer table, targeting the customer_transformation.sql script.
  This script performs a basic MERGE without inline quality checks. These tests
  serve as post-load validation of the data's fundamental integrity.
*/

-- test: not_null_customer_id
-- The primary key for the customer table must not be null.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_customer_id' AS test_name,
  'All customer_id values must be non-null.' AS description
FROM `Curated.customer`
WHERE customer_id IS NULL;

-- test: unique_customer_id
-- The primary key for the customer table must be unique to ensure entity integrity.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'unique_customer_id' AS test_name,
  'Each customer_id must be unique.' AS description
FROM (
  SELECT
    customer_id
  FROM `Curated.customer`
  WHERE customer_id IS NOT NULL
  GROUP BY customer_id
  HAVING COUNT(*) > 1
);