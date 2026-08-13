/*
  Unit tests for the Curated.lead table, targeting the crm_transformation.sql script.
  These tests validate the data integrity, uniqueness, and referential
  integrity of the lead table after the full transformation.
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
FROM `your_gcp_project_id.Curated.lead`
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
  FROM `your_gcp_project_id.Curated.lead`
  WHERE lead_id IS NOT NULL
  GROUP BY lead_id
  HAVING COUNT(*) > 1
);

-- test: not_null_created_on
-- The creation timestamp is the partitioning key and must not be null.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_created_on' AS test_name,
  'The created_on timestamp (partition key) must not be null.' AS description
FROM `your_gcp_project_id.Curated.lead`
WHERE created_on IS NULL;

-- test: referential_integrity_customer_id
-- Validates that every non-null customer_id in the lead table
-- corresponds to an existing record in the customer table. This confirms
-- the referential integrity logic in the MERGE statement's USING clause.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'referential_integrity_customer_id' AS test_name,
  'All non-null lead.customer_id values must exist in the customer table.' AS description
FROM `your_gcp_project_id.Curated.lead` AS l
LEFT JOIN `your_gcp_project_id.Curated.customer` AS c
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
FROM `your_gcp_project_id.Curated.lead`
WHERE status NOT IN ('New', 'Contacted', 'Qualified', 'Unqualified', 'Nurturing');