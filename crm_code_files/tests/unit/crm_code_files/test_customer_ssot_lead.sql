-- =================================================================================================
-- Unit Tests for crm_code_files/customer_ssot.sql - lead table
--
-- Description: These tests validate the data integrity of the `lead` table after the
--              incremental load.
-- =================================================================================================

-- test: not_null_lead_id
-- A lead must always have a primary key.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_lead_id' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.lead`
WHERE lead_id IS NULL;

-- test: unique_lead_id
-- The lead_id must be unique to serve as a primary key.
SELECT
  IF(COUNT(lead_id) = COUNT(DISTINCT lead_id), 'PASS', 'FAIL') AS result,
  'unique_lead_id' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.lead`;

-- test: not_null_status
-- Lead status is a critical field for tracking and should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_status' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.lead`
WHERE status IS NULL;

-- test: not_null_created_on
-- The creation timestamp is a critical audit field.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_created_on' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.lead`
WHERE created_on IS NULL;

-- test: fk_lead_customer_id_exists
-- If a lead is associated with a customer, that customer must exist in the customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'fk_lead_customer_id_exists' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.lead` AS l
LEFT JOIN `{{ project_id }}.{{ curated_dataset }}.customer` AS c
  ON l.customer_id = c.customer_id
WHERE l.customer_id IS NOT NULL AND c.customer_id IS NULL;

-- test: chronological_qualified_on
-- A lead cannot be qualified before it was created.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'chronological_qualified_on' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.lead`
WHERE qualified_on IS NOT NULL AND qualified_on < created_on;