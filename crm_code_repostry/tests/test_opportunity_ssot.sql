/*
  Unit tests for the Curated.opportunity table.
  These tests validate the data integrity of the opportunity single source of truth.
*/

-- test: unique_opportunity_id
-- Ensures that every opportunity has a unique identifier.
SELECT
  IF(COUNT(opportunity_id) = COUNT(DISTINCT opportunity_id), 'PASS', 'FAIL') AS result,
  'unique_opportunity_id' AS test_name
FROM
  `Curated.opportunity`;

-- test: not_null_opportunity_id
-- The primary key for the opportunity table must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_opportunity_id' AS test_name
FROM
  `Curated.opportunity`
WHERE
  opportunity_id IS NULL;

-- test: not_null_customer_id
-- Every opportunity must be associated with a customer.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_customer_id' AS test_name
FROM
  `Curated.opportunity`
WHERE
  customer_id IS NULL;

-- test: not_null_stage
-- The sales stage is a critical field for pipeline analysis.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_stage' AS test_name
FROM
  `Curated.opportunity`
WHERE
  stage IS NULL;

-- test: referential_integrity_customer_id
-- The customer_id on an opportunity must exist in the customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customer_id' AS test_name
FROM
  `Curated.opportunity` AS o
LEFT JOIN
  `Curated.customer` AS c
  ON o.customer_id = c.customer_id
WHERE
  c.customer_id IS NULL;

-- test: referential_integrity_originating_lead_id
-- If an opportunity originated from a lead, that lead must exist in the lead table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_originating_lead_id' AS test_name
FROM
  `Curated.opportunity` AS o
LEFT JOIN
  `Curated.lead` AS l
  ON o.originating_lead_id = l.lead_id
WHERE
  o.originating_lead_id IS NOT NULL
  AND l.lead_id IS NULL;

-- test: range_check_probability
-- The probability of closing an opportunity must be between 0 and 1.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_probability' AS test_name
FROM
  `Curated.opportunity`
WHERE
  probability < 0
  OR probability > 1;

-- test: range_check_estimated_value
-- The estimated value of an opportunity cannot be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_estimated_value' AS test_name
FROM
  `Curated.opportunity`
WHERE
  estimated_value < 0;

-- test: chronological_order_close_date
-- The estimated close date cannot be before the opportunity creation date.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'chronological_order_close_date' AS test_name
FROM
  `Curated.opportunity`
WHERE
  close_date IS NOT NULL
  AND close_date < DATE(created_on);