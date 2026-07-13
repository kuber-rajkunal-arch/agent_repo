--
-- Unit tests for the curated customer table.
-- These tests validate the data integrity of the `<project_id>.<curated_dataset>.customer` table
-- after the MERGE operation from `crm_code/customer_ssot.sql` is executed.
--

-- test: not_null_customer_id
-- The primary key `customer_id` must not be null. This is a fundamental data quality check.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_customer_id' AS test_name
FROM
  `<project_id>.<curated_dataset>.customer`
WHERE
  customer_id IS NULL;

-- test: unique_customer_id
-- The primary key `customer_id` must be unique across all records to ensure entity integrity.
SELECT
  IF(COUNT(customer_id) = COUNT(DISTINCT customer_id), 'PASS', 'FAIL') AS result,
  'unique_customer_id' AS test_name
FROM
  `<project_id>.<curated_dataset>.customer`;

-- test: not_null_created_on
-- The `created_on` timestamp is a critical audit field and must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_created_on' AS test_name
FROM
  `<project_id>.<curated_dataset>.customer`
WHERE
  created_on IS NULL;

-- test: not_null_modified_on
-- The `modified_on` timestamp is the watermark for incremental loads and must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_modified_on' AS test_name
FROM
  `<project_id>.<curated_dataset>.customer`
WHERE
  modified_on IS NULL;

-- test: chronological_timestamps
-- The `modified_on` timestamp must be greater than or equal to the `created_on` timestamp.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'chronological_timestamps' AS test_name
FROM
  `<project_id>.<curated_dataset>.customer`
WHERE
  modified_on < created_on;

-- test: valid_email_format
-- The `email` field should contain a valid format (basic check for '@' symbol).
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'valid_email_format' AS test_name
FROM
  `<project_id>.<curated_dataset>.customer`
WHERE
  email IS NOT NULL AND NOT REGEXP_CONTAINS(email, r'@');