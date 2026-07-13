--
-- Unit tests for the curated lead table.
-- These tests validate the data integrity of the `<project_id>.<curated_dataset>.lead` table
-- after the MERGE operation from `crm_code/customer_ssot.sql` is executed.
--

-- test: not_null_lead_id
-- The primary key `lead_id` must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_lead_id' AS test_name
FROM
  `<project_id>.<curated_dataset>.lead`
WHERE
  lead_id IS NULL;

-- test: unique_lead_id
-- The primary key `lead_id` must be unique across all records.
SELECT
  IF(COUNT(lead_id) = COUNT(DISTINCT lead_id), 'PASS', 'FAIL') AS result,
  'unique_lead_id' AS test_name
FROM
  `<project_id>.<curated_dataset>.lead`;

-- test: not_null_created_on
-- The `created_on` timestamp is the watermark for incremental loads and must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_created_on' AS test_name
FROM
  `<project_id>.<curated_dataset>.lead`
WHERE
  created_on IS NULL;

-- test: referential_integrity_customer_id
-- If `customer_id` is populated, it must exist in the `customer` table.
-- This confirms the `EXISTS` check in the source query is effective.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customer_id' AS test_name
FROM
  `<project_id>.<curated_dataset>.lead` AS l
WHERE
  l.customer_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1
    FROM `<project_id>.<curated_dataset>.customer` AS c
    WHERE c.customer_id = l.customer_id
  );

-- test: valid_status_domain
-- The `status` field should only contain expected values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'valid_status_domain' AS test_name
FROM
  `<project_id>.<curated_dataset>.lead`
WHERE
  status NOT IN ('New', 'Contacted', 'Qualified', 'Unqualified', 'Nurturing'); -- Inferred domain

-- test: chronological_qualified_on
-- If a lead is qualified, the `qualified_on` date must be on or after the `created_on` date.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'chronological_qualified_on' AS test_name
FROM
  `<project_id>.<curated_dataset>.lead`
WHERE
  qualified_on IS NOT NULL AND qualified_on < created_on;