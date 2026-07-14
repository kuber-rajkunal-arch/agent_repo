-- ===================================================================================
--
-- Unit Tests for Curated.customer
--
-- ===================================================================================

-- test: not_null_customer_id
-- The primary key `customer_id` must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_customer_id' AS test_name
FROM
  `Curated.customer`
WHERE
  customer_id IS NULL;

-- test: unique_customer_id
-- The primary key `customer_id` must be unique.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_customer_id' AS test_name
FROM (
  SELECT
    customer_id
  FROM
    `Curated.customer`
  WHERE
    customer_id IS NOT NULL
  GROUP BY
    customer_id
  HAVING
    COUNT(*) > 1
);

-- test: not_null_created_on
-- The `created_on` timestamp is a critical field and should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_created_on' AS test_name
FROM
  `Curated.customer`
WHERE
  created_on IS NULL;

-- test: not_null_modified_on
-- The `modified_on` timestamp is a critical field and should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_modified_on' AS test_name
FROM
  `Curated.customer`
WHERE
  modified_on IS NULL;

-- test: consistency_modified_on_vs_created_on
-- The `modified_on` timestamp should not be earlier than the `created_on` timestamp.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'consistency_modified_on_vs_created_on' AS test_name
FROM
  `Curated.customer`
WHERE
  modified_on < created_on;

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