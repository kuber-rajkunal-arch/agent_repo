/*
  Unit tests for the Curated.customer table.
  These tests validate the data integrity of the customer single source of truth.
*/

-- test: unique_customer_id
-- Ensures that every customer has a unique identifier.
SELECT
  IF(COUNT(customer_id) = COUNT(DISTINCT customer_id), 'PASS', 'FAIL') AS result,
  'unique_customer_id' AS test_name
FROM
  `Curated.customer`;

-- test: not_null_customer_id
-- The primary key for the customer table must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_customer_id' AS test_name
FROM
  `Curated.customer`
WHERE
  customer_id IS NULL;

-- test: not_null_created_on
-- The created_on timestamp is used for watermarking and should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_created_on' AS test_name
FROM
  `Curated.customer`
WHERE
  created_on IS NULL;

-- test: not_null_modified_on
-- The modified_on timestamp is critical for tracking updates and should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_modified_on' AS test_name
FROM
  `Curated.customer`
WHERE
  modified_on IS NULL;

-- test: not_null_is_active
-- The activity status flag must always be present.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_is_active' AS test_name
FROM
  `Curated.customer`
WHERE
  is_active IS NULL;

-- test: not_null_customer_type
-- The customer type is a fundamental classification and must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_customer_type' AS test_name
FROM
  `Curated.customer`
WHERE
  customer_type IS NULL;

-- test: valid_email_format
-- Checks for a basic email format ('@' symbol) for non-null email addresses.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'valid_email_format' AS test_name
FROM
  `Curated.customer`
WHERE
  email IS NOT NULL
  AND NOT REGEXP_CONTAINS(email, r'@');