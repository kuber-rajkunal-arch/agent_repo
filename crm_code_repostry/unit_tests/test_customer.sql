/*
  Unit tests for the 'curated.customer' table.
  These tests validate the data integrity of the final customer table
  after the transformation script has been executed.
*/

-- test: not_null_customer_id
-- The primary key 'customer_id' should never be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_customer_id' AS test_name
FROM `curated.customer`
WHERE customer_id IS NULL;

-- test: unique_customer_id
-- The primary key 'customer_id' must be unique across all records.
SELECT
  IF(COUNT(customer_id) = COUNT(DISTINCT customer_id), 'PASS', 'FAIL') AS result,
  'unique_customer_id' AS test_name
FROM `curated.customer`;

-- test: not_null_name
-- The customer's name is a critical field and should not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_name' AS test_name
FROM `curated.customer`
WHERE name IS NULL;

-- test: not_null_customer_type
-- The customer type should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_customer_type' AS test_name
FROM `curated.customer`
WHERE customer_type IS NULL;

-- test: not_null_created_on
-- The creation timestamp is essential for tracking and should not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_created_on' AS test_name
FROM `curated.customer`
WHERE created_on IS NULL;

-- test: not_null_is_active
-- The 'is_active' flag must always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_is_active' AS test_name
FROM `curated.customer`
WHERE is_active IS NULL;

-- test: domain_is_active
-- The 'is_active' flag must be a boolean value (TRUE or FALSE).
SELECT
  IF(COUNTIF(is_active NOT IN (TRUE, FALSE)) = 0, 'PASS', 'FAIL') AS result,
  'domain_is_active' AS test_name
FROM `curated.customer`
WHERE is_active IS NOT NULL;