/*
  Unit tests for the Curated.opportunity table, targeting the customer_transformation.sql script.
  This script performs a basic MERGE without inline quality checks. These tests
  serve as post-load validation to detect potential data quality issues like orphans.
*/

-- test: not_null_opportunity_id
-- The primary key for the opportunity table must not be null.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_opportunity_id' AS test_name,
  'All opportunity_id values must be non-null.' AS description
FROM `Curated.opportunity`
WHERE opportunity_id IS NULL;

-- test: unique_opportunity_id
-- The primary key for the opportunity table must be unique.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'unique_opportunity_id' AS test_name,
  'Each opportunity_id must be unique.' AS description
FROM (
  SELECT
    opportunity_id
  FROM `Curated.opportunity`
  WHERE opportunity_id IS NOT NULL
  GROUP BY opportunity_id
  HAVING COUNT(*) > 1
);

-- test: referential_integrity_customer_id
-- Post-load check: Validates that every customer_id in the opportunity table
-- corresponds to an existing record in the customer table.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'referential_integrity_customer_id' AS test_name,
  'All opportunity.customer_id values must exist in the customer table.' AS description
FROM `Curated.opportunity` AS o
LEFT JOIN `Curated.customer` AS c
  ON o.customer_id = c.customer_id
WHERE
  o.customer_id IS NOT NULL
  AND c.customer_id IS NULL;

-- test: referential_integrity_originating_lead_id
-- Post-load check: Validates that every non-null originating_lead_id
-- corresponds to an existing record in the lead table.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'referential_integrity_originating_lead_id' AS test_name,
  'All non-null opportunity.originating_lead_id values must exist in the lead table.' AS description
FROM `Curated.opportunity` AS o
LEFT JOIN `Curated.lead` AS l
  ON o.originating_lead_id = l.lead_id
WHERE
  o.originating_lead_id IS NOT NULL
  AND l.lead_id IS NULL;