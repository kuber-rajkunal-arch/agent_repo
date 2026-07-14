-- =============================================================================
-- Unit Tests for curated.lead
--
-- These tests validate the data integrity of the `lead` table after the
-- MERGE operation.
-- =============================================================================

-- test: not_null_lead_id
-- The lead_id is the primary key and should never be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_lead_id' AS test_name
FROM `your_project_id.your_curated_dataset.lead`
WHERE lead_id IS NULL;

-- test: unique_lead_id
-- The lead_id must be unique to serve as a primary key.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_lead_id' AS test_name
FROM (
  SELECT
    lead_id
  FROM `your_project_id.your_curated_dataset.lead`
  WHERE lead_id IS NOT NULL
  GROUP BY
    lead_id
  HAVING
    COUNT(*) > 1
);

-- test: not_null_status
-- The status field is critical for tracking lead progression and must be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_status' AS test_name
FROM `your_project_id.your_curated_dataset.lead`
WHERE status IS NULL;

-- test: not_null_created_on
-- The created_on date is a critical audit field and must be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_created_on' AS test_name
FROM `your_project_id.your_curated_dataset.lead`
WHERE created_on IS NULL;

-- test: referential_integrity_customer_id
-- If a lead is associated with a customer, that customer_id must exist in the customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customer_id' AS test_name
FROM `your_project_id.your_curated_dataset.lead` AS l
LEFT JOIN `your_project_id.your_curated_dataset.customer` AS c
  ON l.customer_id = c.customer_id
WHERE
  l.customer_id IS NOT NULL
  AND c.customer_id IS NULL;

-- test: qualified_date_logic
-- The qualified_on date cannot be before the created_on date.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'qualified_date_logic' AS test_name
FROM `your_project_id.your_curated_dataset.lead`
WHERE qualified_on IS NOT NULL AND qualified_on < created_on;