/*
  Unit tests for the Curated.customer table.
  These tests validate the data integrity, uniqueness, and completeness
  of the customer dimension table after transformation.
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
FROM `your_gcp_project_id.Curated.customer`
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
  FROM `your_gcp_project_id.Curated.customer`
  WHERE customer_id IS NOT NULL
  GROUP BY customer_id
  HAVING COUNT(*) > 1
);

-- test: not_null_created_on
-- The creation timestamp is critical for tracking and should not be null.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_created_on' AS test_name
FROM `your_gcp_project_id.Curated.customer`
WHERE created_on IS NULL;

-- test: not_null_is_active
-- The activity status flag should always be populated (true or false).
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_is_active' AS test_name
FROM `your_gcp_project_id.Curated.customer`
WHERE is_active IS NULL;