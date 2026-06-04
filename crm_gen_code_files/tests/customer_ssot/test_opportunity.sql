/*
  Unit tests for the incremental load of the Curated.opportunity table.
  These tests validate data integrity, uniqueness, and referential
  integrity of the opportunity table after the watermark-based MERGE operation.
*/

-- test: not_null_opportunity_id
-- The primary key for the opportunity table must not be null.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_opportunity_id' AS test_name
FROM `<project_id>.<curated_dataset>.opportunity`
WHERE opportunity_id IS NULL;

-- test: unique_opportunity_id
-- The primary key for the opportunity table must be unique.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'unique_opportunity_id' AS test_name
FROM (
  SELECT
    opportunity_id
  FROM `<project_id>.<curated_dataset>.opportunity`
  WHERE opportunity_id IS NOT NULL
  GROUP BY opportunity_id
  HAVING COUNT(*) > 1
);

-- test: not_null_customer_id
-- The source MERGE logic requires an existing customer, so customer_id should never be null.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_customer_id' AS test_name
FROM `<project_id>.<curated_dataset>.opportunity`
WHERE customer_id IS NULL;

-- test: referential_integrity_customer_id
-- Validates that every customer_id in the opportunity table corresponds
-- to an existing record in the customer table.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'referential_integrity_customer_id' AS test_name
FROM `<project_id>.<curated_dataset>.opportunity` AS o
LEFT JOIN `<project_id>.<curated_dataset>.customer` AS c
  ON o.customer_id = c.customer_id
WHERE
  o.customer_id IS NOT NULL
  AND c.customer_id IS NULL;

-- test: referential_integrity_originating_lead_id
-- Validates that every non-null originating_lead_id in the opportunity table
-- corresponds to an existing record in the lead table.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'referential_integrity_originating_lead_id' AS test_name
FROM `<project_id>.<curated_dataset>.opportunity` AS o
LEFT JOIN `<project_id>.<curated_dataset>.lead` AS l
  ON o.originating_lead_id = l.lead_id
WHERE
  o.originating_lead_id IS NOT NULL
  AND l.lead_id IS NULL;