-- Unit tests for the curated 'customer' table.
-- These tests verify primary key integrity after the sp_load_customer procedure runs.

-- test: not_null_customer_id
-- The primary key `customer_id` must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_customer_id' AS test_name,
  'All customer_id records must be not-null.' AS description
FROM `your-gcp-project-id.Curated.customer`
WHERE customer_id IS NULL;

-- test: unique_customer_id
-- The primary key `customer_id` must be unique across all records.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_customer_id' AS test_name,
  'All customer_id records must be unique.' AS description
FROM (
  SELECT
    customer_id
  FROM `your-gcp-project-id.Curated.customer`
  WHERE customer_id IS NOT NULL
  GROUP BY customer_id
  HAVING COUNT(*) > 1
);