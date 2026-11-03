/*
Unit Tests for: customer
Description: Tests the data integrity of the curated customer table.
*/

-- Placeholder for the GCP project and dataset variables.
-- Replace 'your-gcp-project-id' and 'Curated' with your actual project and dataset.
DECLARE gcp_project_id STRING DEFAULT 'your-gcp-project-id';
DECLARE curated_dataset STRING DEFAULT 'Curated';

-- test: not_null_customer_id
-- The primary key 'customer_id' must not contain null values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_customer_id' AS test_name
FROM
  `your-gcp-project-id.Curated.customer`
WHERE
  customer_id IS NULL;

-- test: unique_customer_id
-- The primary key 'customer_id' must be unique across all records.
SELECT
  IF(
    COUNT(customer_id) = COUNT(DISTINCT customer_id),
    'PASS',
    'FAIL'
  ) AS result,
  'unique_customer_id' AS test_name
FROM
  `your-gcp-project-id.Curated.customer`;

-- test: not_null_created_on
-- The 'created_on' timestamp is a critical audit field and should never be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_created_on' AS test_name
FROM
  `your-gcp-project-id.Curated.customer`
WHERE
  created_on IS NULL;

-- test: not_null_modified_on
-- The 'modified_on' timestamp is a critical audit field and should never be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_modified_on' AS test_name
FROM
  `your-gcp-project-id.Curated.customer`
WHERE
  modified_on IS NULL;

-- test: domain_customer_type
-- The 'customer_type' should fall within an expected set of values.
-- This test assumes 'INDIVIDUAL' and 'COMPANY' are the primary types.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'domain_customer_type' AS test_name
FROM
  `your-gcp-project-id.Curated.customer`
WHERE
  customer_type NOT IN ('INDIVIDUAL', 'COMPANY') AND customer_type IS NOT NULL;

-- test: valid_email_format
-- The 'email' field should follow a basic email format.
-- This is a simple check and not a comprehensive regex validation.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'valid_email_format' AS test_name
FROM
  `your-gcp-project-id.Curated.customer`
WHERE
  email IS NOT NULL
  AND NOT REGEXP_CONTAINS(email, r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');