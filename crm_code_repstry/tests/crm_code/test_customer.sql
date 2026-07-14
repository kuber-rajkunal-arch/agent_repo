-- =============================================================================
-- Unit Tests for curated.customer
--
-- These tests validate the data integrity of the `customer` table after the
-- MERGE operation.
-- =============================================================================

-- test: not_null_customer_id
-- The customer_id is the primary key and should never be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_customer_id' AS test_name
FROM `your_project_id.your_curated_dataset.customer`
WHERE customer_id IS NULL;

-- test: unique_customer_id
-- The customer_id must be unique to serve as a primary key.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_customer_id' AS test_name
FROM (
  SELECT
    customer_id
  FROM `your_project_id.your_curated_dataset.customer`
  WHERE customer_id IS NOT NULL
  GROUP BY
    customer_id
  HAVING
    COUNT(*) > 1
);

-- test: not_null_name
-- Every customer record should have a name.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_name' AS test_name
FROM `your_project_id.your_curated_dataset.customer`
WHERE name IS NULL;

-- test: not_null_created_on
-- The created_on date is a critical audit field and must be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_created_on' AS test_name
FROM `your_project_id.your_curated_dataset.customer`
WHERE created_on IS NULL;

-- test: not_null_is_active
-- The is_active flag is critical for business logic and must be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_is_active' AS test_name
FROM `your_project_id.your_curated_dataset.customer`
WHERE is_active IS NULL;

-- test: valid_email_format
-- Emails should contain an '@' symbol. This is a basic format check.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'valid_email_format' AS test_name
FROM `your_project_id.your_curated_dataset.customer`
WHERE email IS NOT NULL AND NOT REGEXP_CONTAINS(email, r'@');