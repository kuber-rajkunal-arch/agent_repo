/*
  Unit tests for the Curated.lead table, targeting the customer_transformation.sql script.
  This script performs a basic MERGE without inline quality checks. These tests
  serve as post-load validation to detect potential data quality issues like orphans.
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
FROM `Curated.lead`
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
  FROM `Curated.lead`
  WHERE lead_id IS NOT NULL
  GROUP BY lead_id
  HAVING COUNT(*) > 1
);

-- test: referential_integrity_customer_id
-- Post-load check: Validates that every non-null customer_id in the lead table
-- corresponds to an existing record in the customer table. A failure here indicates
-- an orphan record was loaded from the source.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'referential_integrity_customer_id' AS test_name,
  'All non-null lead.customer_id values must exist in the customer table.' AS description
FROM `Curated.lead` AS l
LEFT JOIN `Curated.customer` AS c
  ON l.customer_id = c.customer_id
WHERE
  l.customer_id IS NOT NULL
  AND c.customer_id IS NULL;