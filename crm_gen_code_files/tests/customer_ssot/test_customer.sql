/*
  Unit tests for the incremental load of the Curated.customer table.
  These tests validate the data integrity and uniqueness of the customer
  dimension table after the watermark-based MERGE operation.
*/

-- test: not_null_customer_id
-- The primary key for the customer table must not be null.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_customer_id' AS test_name
FROM `<project_id>.<curated_dataset>.customer`
WHERE customer_id IS NULL;

-- test: unique_customer_id
-- The primary key for the customer table must be unique.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'unique_customer_id' AS test_name
FROM (
  SELECT
    customer_id
  FROM `<project_id>.<curated_dataset>.customer`
  WHERE customer_id IS NOT NULL
  GROUP BY customer_id
  HAVING COUNT(*) > 1
);

-- test: not_null_modified_on
-- The 'modified_on' timestamp is the watermark for incremental loads and is
-- critical for data freshness. It must not be null.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_modified_on' AS test_name
FROM `<project_id>.<curated_dataset>.customer`
WHERE modified_on IS NULL;