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
  'not_null_opportunity_id' AS test_name,
  'All opportunity_id values must be non-null.' AS description
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
  'unique_opportunity_id' AS test_name,
  'Each opportunity_id must be unique.' AS description
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
  'not_null_customer_id' AS test_name,
  'The customer_id must not be null, as per source logic.' AS description
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
  'referential_integrity_customer_id' AS test_name,
  'All opportunity.customer_id values must exist in the customer table.' AS description
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
  'referential_integrity_originating_lead_id' AS test_name,
  'All non-null opportunity.originating_lead_id values must exist in the lead table.' AS description
FROM `<project_id>.<curated_dataset>.opportunity` AS o
LEFT JOIN `<project_id>.<curated_dataset>.lead` AS l
  ON o.originating_lead_id = l.lead_id
WHERE
  o.originating_lead_id IS NOT NULL
  AND l.lead_id IS NULL;

-- test: range_check_probability
-- The probability of an opportunity closing should be between 0 and 1, inclusive.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'range_check_probability' AS test_name,
  'Probability must be between 0 and 1.' AS description
FROM `<project_id>.<curated_dataset>.opportunity`
WHERE
  probability < 0 OR probability > 1;

-- test: accepted_values_stage
-- The 'stage' field should conform to a set of expected values.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'accepted_values_stage' AS test_name,
  'Opportunity stage must be one of the predefined values.' AS description
FROM `<project_id>.<curated_dataset>.opportunity`
WHERE stage NOT IN ('Prospecting', 'Qualification', 'Proposal', 'Negotiation', 'Closed Won', 'Closed Lost');