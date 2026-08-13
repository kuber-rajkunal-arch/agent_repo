/*
  Unit tests for the incremental load of the Curated.lead table.
  These tests validate data integrity, uniqueness, and referential
  integrity of the lead table after the watermark-based MERGE operation.
*/

-- test: not_null_lead_id
-- The primary key for the lead table must not be null.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_lead_id' AS test_name,
  'All lead_id values must be non-null.' AS description
FROM `<project_id>.<curated_dataset>.lead`
WHERE lead_id IS NULL;

-- test: unique_lead_id
-- The primary key for the lead table must be unique.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'unique_lead_id' AS test_name,
  'Each lead_id must be unique.' AS description
FROM (
  SELECT
    lead_id
  FROM `<project_id>.<curated_dataset>.lead`
  WHERE lead_id IS NOT NULL
  GROUP BY lead_id
  HAVING COUNT(*) > 1
);

-- test: not_null_created_on
-- The 'created_on' timestamp is the watermark and partitioning key. It must not be null.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_created_on' AS test_name,
  'The created_on timestamp (watermark) must not be null.' AS description
FROM `<project_id>.<curated_dataset>.lead`
WHERE created_on IS NULL;

-- test: referential_integrity_customer_id
-- Validates that every non-null customer_id in the lead table corresponds to an
-- existing record in the customer table. This confirms the referential integrity
-- logic in the MERGE statement's USING clause.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'referential_integrity_customer_id' AS test_name,
  'All non-null lead.customer_id values must exist in the customer table.' AS description
FROM `<project_id>.<curated_dataset>.lead` AS l
LEFT JOIN `<project_id>.<curated_dataset>.customer` AS c
  ON l.customer_id = c.customer_id
WHERE
  l.customer_id IS NOT NULL
  AND c.customer_id IS NULL;

-- test: accepted_values_status
-- The 'status' field should conform to a set of expected values.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'accepted_values_status' AS test_name,
  'Lead status must be one of the predefined values.' AS description
FROM `<project_id>.<curated_dataset>.lead`
WHERE status NOT IN ('New', 'Contacted', 'Qualified', 'Unqualified', 'Nurturing');