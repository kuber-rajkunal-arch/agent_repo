/*
  Unit tests for the 'curated.opportunity' table.
  These tests validate the data integrity of the final opportunity table
  after the transformation script has been executed.
*/

-- test: not_null_opportunity_id
-- The primary key 'opportunity_id' should never be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_opportunity_id' AS test_name
FROM `curated.opportunity`
WHERE opportunity_id IS NULL;

-- test: unique_opportunity_id
-- The primary key 'opportunity_id' must be unique across all records.
SELECT
  IF(COUNT(opportunity_id) = COUNT(DISTINCT opportunity_id), 'PASS', 'FAIL') AS result,
  'unique_opportunity_id' AS test_name
FROM `curated.opportunity`;

-- test: not_null_name
-- The opportunity name is a critical field and should not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_name' AS test_name
FROM `curated.opportunity`
WHERE name IS NULL;

-- test: not_null_customer_id
-- Every opportunity must be associated with a customer.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_customer_id' AS test_name
FROM `curated.opportunity`
WHERE customer_id IS NULL;

-- test: not_null_stage
-- The opportunity stage is a critical field for sales pipeline tracking.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_stage' AS test_name
FROM `curated.opportunity`
WHERE stage IS NULL;

-- test: referential_customer_id
-- The 'customer_id' in the opportunity table must exist in the customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_customer_id' AS test_name
FROM `curated.opportunity` AS o
LEFT JOIN `curated.customer` AS c
  ON o.customer_id = c.customer_id
WHERE
  o.customer_id IS NOT NULL
  AND c.customer_id IS NULL;

-- test: referential_originating_lead_id
-- Any non-null 'originating_lead_id' must exist in the lead table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_originating_lead_id' AS test_name
FROM `curated.opportunity` AS o
LEFT JOIN `curated.lead` AS l
  ON o.originating_lead_id = l.lead_id
WHERE
  o.originating_lead_id IS NOT NULL
  AND l.lead_id IS NULL;

-- test: range_probability
-- The 'probability' field should be a value between 0 and 1, inclusive.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_probability' AS test_name
FROM `curated.opportunity`
WHERE probability < 0 OR probability > 1;

-- test: range_estimated_value
-- The 'estimated_value' should be non-negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_estimated_value' AS test_name
FROM `curated.opportunity`
WHERE estimated_value < 0;

-- test: domain_status
-- The 'status' field should conform to a predefined set of values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'domain_status' AS test_name
FROM `curated.opportunity`
WHERE status NOT IN ('Open', 'Won', 'Lost');