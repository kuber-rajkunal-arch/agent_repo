/*
  Unit tests for the Curated.quote table.
  These tests validate the output of the crm_transformation.sql script.
*/

-- Declare variables to match the source script's parameterization
DECLARE v_project_id STRING DEFAULT 'your_project_id';
DECLARE v_curated_dataset STRING DEFAULT 'Curated';

-- test: unique_quote_id
-- The quote_id must be unique to serve as a primary key.
SELECT
  IF(
    COUNT(quote_id) = COUNT(DISTINCT quote_id),
    'PASS',
    'FAIL'
  ) AS result,
  'unique_quote_id' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.quote`;

-- test: not_null_quote_id
-- The primary key for the quote table cannot be null.
SELECT
  IF(
    COUNTIF(quote_id IS NULL) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_quote_id' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.quote`;

-- test: not_null_opportunity_id
-- A quote must be associated with an opportunity.
SELECT
  IF(
    COUNTIF(opportunity_id IS NULL) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_opportunity_id' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.quote`;

-- test: referential_opportunity_id
-- The opportunity_id on a quote must exist in the opportunity table.
SELECT
  IF(
    COUNT(Q.opportunity_id) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'referential_opportunity_id' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.quote` AS Q
LEFT JOIN `${v_project_id}.${v_curated_dataset}.opportunity` AS O
  ON Q.opportunity_id = O.opportunity_id
WHERE O.opportunity_id IS NULL;

-- test: referential_customer_id
-- The customer_id on a quote must exist in the customer table.
SELECT
  IF(
    COUNT(Q.customer_id) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'referential_customer_id' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.quote` AS Q
LEFT JOIN `${v_project_id}.${v_curated_dataset}.customer` AS C
  ON Q.customer_id = C.customer_id
WHERE Q.customer_id IS NOT NULL AND C.customer_id IS NULL;

-- test: range_total_amount
-- The total amount of a quote cannot be negative.
SELECT
  IF(
    COUNTIF(total_amount < 0) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'range_total_amount' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.quote`
WHERE total_amount IS NOT NULL;

-- test: chronology_valid_dates
-- The valid_to date must be on or after the valid_from date.
SELECT
  IF(
    COUNTIF(valid_to < valid_from) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'chronology_valid_dates' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.quote`
WHERE valid_to IS NOT NULL AND valid_from IS NOT NULL;