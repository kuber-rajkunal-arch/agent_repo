-- =================================================================================================
-- Unit Tests for crm_code_files/customer_ssot.sql - customer table
--
-- Description: These tests validate the data integrity of the `customer` table after the
--              incremental load.
-- =================================================================================================

-- test: not_null_customer_id
-- A customer must always have a primary key.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_customer_id' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.customer`
WHERE customer_id IS NULL;

-- test: unique_customer_id
-- The customer_id must be unique to serve as a primary key.
SELECT
  IF(COUNT(customer_id) = COUNT(DISTINCT customer_id), 'PASS', 'FAIL') AS result,
  'unique_customer_id' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.customer`;

-- test: not_null_customer_type
-- Customer type is a critical classification field and should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_customer_type' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.customer`
WHERE customer_type IS NULL;

-- test: not_null_is_active
-- The active status of a customer must always be known.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_is_active' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.customer`
WHERE is_active IS NULL;

-- test: consistency_name_vs_company_name
-- A 'Company' type customer must have a company_name.
-- An 'Individual' type customer must have a name.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'consistency_name_vs_company_name' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.customer`
WHERE
  (customer_type = 'Company' AND company_name IS NULL)
  OR (customer_type = 'Individual' AND name IS NULL);