/*
  Unit tests for the Curated.opportunity table.
  These tests validate the output of the crm_transformation.sql script.
*/

-- Declare variables to match the source script's parameterization
DECLARE v_project_id STRING DEFAULT 'your_project_id';
DECLARE v_curated_dataset STRING DEFAULT 'Curated';

-- test: unique_opportunity_id
-- The opportunity_id must be unique to serve as a primary key.
SELECT
  IF(
    COUNT(opportunity_id) = COUNT(DISTINCT opportunity_id),
    'PASS',
    'FAIL'
  ) AS result,
  'unique_opportunity_id' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.opportunity`;

-- test: not_null_opportunity_id
-- The primary key for the opportunity table cannot be null.
SELECT
  IF(
    COUNTIF(opportunity_id IS NULL) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_opportunity_id' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.opportunity`;

-- test: not_null_customer_id
-- An opportunity must be associated with a customer.
SELECT
  IF(
    COUNTIF(customer_id IS NULL) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_customer_id' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.opportunity`;

-- test: referential_customer_id
-- The customer_id on an opportunity must exist in the customer table.
SELECT
  IF(
    COUNT(O.customer_id) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'referential_customer_id' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.opportunity` AS O
LEFT JOIN `${v_project_id}.${v_curated_dataset}.customer` AS C
  ON O.customer_id = C.customer_id
WHERE C.customer_id IS NULL;

-- test: referential_originating_lead_id
-- If an opportunity originated from a lead, that lead_id must exist in the lead table.
SELECT
  IF(
    COUNT(O.originating_lead_id) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'referential_originating_lead_id' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.opportunity` AS O
LEFT JOIN `${v_project_id}.${v_curated_dataset}.lead` AS L
  ON O.originating_lead_id = L.lead_id
WHERE O.originating_lead_id IS NOT NULL AND L.lead_id IS NULL;

-- test: range_probability
-- The probability of closing an opportunity should be between 0 and 1 (inclusive).
SELECT
  IF(
    COUNTIF(probability < 0 OR probability > 1) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'range_probability' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.opportunity`
WHERE probability IS NOT NULL;

-- test: range_estimated_value
-- The estimated value of an opportunity cannot be negative.
SELECT
  IF(
    COUNTIF(estimated_value < 0) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'range_estimated_value' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.opportunity`
WHERE estimated_value IS NOT NULL;