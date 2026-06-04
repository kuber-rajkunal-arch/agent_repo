/*
--------------------------------------------------------------------------------
--
-- Test File: customer_tests.sql
--
-- Purpose: Unit tests for the `customer` table.
--
-- Author: Senior Software/Quality Engineer
--
--------------------------------------------------------------------------------
*/

-- =============================================================================
-- Tests for the `customer` table
-- =============================================================================

-- test: customer_not_null_customer_id
-- The primary key `customer_id` must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'customer_not_null_customer_id' AS test_name
FROM `your_project_id.your_curated_dataset.customer`
WHERE customer_id IS NULL;

-- test: customer_unique_customer_id
-- The primary key `customer_id` must be unique.
SELECT
  IF(
    (SELECT COUNT(customer_id) FROM `your_project_id.your_curated_dataset.customer`) =
    (SELECT COUNT(DISTINCT customer_id) FROM `your_project_id.your_curated_dataset.customer`),
    'PASS', 'FAIL'
  ) AS result,
  'customer_unique_customer_id' AS test_name;

-- test: customer_not_null_created_on
-- The `created_on` timestamp should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'customer_not_null_created_on' AS test_name
FROM `your_project_id.your_curated_dataset.customer`
WHERE created_on IS NULL;

-- test: customer_not_null_modified_on
-- The `modified_on` timestamp should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'customer_not_null_modified_on' AS test_name
FROM `your_project_id.your_curated_dataset.customer`
WHERE modified_on IS NULL;

-- test: customer_not_null_is_active
-- The `is_active` flag should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'customer_not_null_is_active' AS test_name
FROM `your_project_id.your_curated_dataset.customer`
WHERE is_active IS NULL;

-- test: customer_valid_timestamps
-- The `modified_on` timestamp must be greater than or equal to the `created_on` timestamp.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'customer_valid_timestamps' AS test_name
FROM `your_project_id.your_curated_dataset.customer`
WHERE modified_on < created_on;

-- test: customer_accepted_values_customer_type
-- The `customer_type` field should only contain expected values.
-- Note: This list is an example. Update with all valid customer types.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'customer_accepted_values_customer_type' AS test_name
FROM `your_project_id.your_curated_dataset.customer`
WHERE
  customer_type NOT IN ('Enterprise', 'SMB', 'Individual', 'Partner')
  AND customer_type IS NOT NULL;