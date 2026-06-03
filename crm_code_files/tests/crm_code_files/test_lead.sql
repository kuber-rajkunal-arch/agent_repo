/*
  Unit tests for the Curated.lead table.
  These tests validate the data integrity, uniqueness, and referential
  integrity of the lead table after transformation.
*/

-- test: not_null_lead_id
-- The primary key for the lead table must not be null.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_lead_id' AS test_name
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
  'unique_lead_id' AS test_name
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
  'not_null_created_on' AS test_name
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
  'referential_integrity_customer_id' AS test_name
FROM `your_gcp_project_id.Curated.lead` AS l
LEFT JOIN `your_gcp_project_id.Curated.customer` AS c
  ON l.customer_id = c.customer_id
WHERE
  l.customer_id IS NOT NULL
  AND c.customer_id IS NULL;