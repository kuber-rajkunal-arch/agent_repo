/*
  Unit tests for the Curated.lead table.
  These tests validate the output of the crm_transformation.sql script.
*/

-- Declare variables to match the source script's parameterization
DECLARE v_project_id STRING DEFAULT 'your_project_id';
DECLARE v_curated_dataset STRING DEFAULT 'Curated';

-- test: unique_lead_id
-- The lead_id must be unique to serve as a primary key.
SELECT
  IF(
    COUNT(lead_id) = COUNT(DISTINCT lead_id),
    'PASS',
    'FAIL'
  ) AS result,
  'unique_lead_id' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.lead`;

-- test: not_null_lead_id
-- The primary key for the lead table cannot be null.
SELECT
  IF(
    COUNTIF(lead_id IS NULL) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_lead_id' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.lead`;

-- test: not_null_created_on
-- The created_on timestamp is a critical audit field and should never be null.
SELECT
  IF(
    COUNTIF(created_on IS NULL) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_created_on' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.lead`;

-- test: referential_customer_id
-- If a lead is associated with a customer, that customer_id must exist in the customer table.
SELECT
  IF(
    COUNT(L.customer_id) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'referential_customer_id' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.lead` AS L
LEFT JOIN `${v_project_id}.${v_curated_dataset}.customer` AS C
  ON L.customer_id = C.customer_id
WHERE L.customer_id IS NOT NULL AND C.customer_id IS NULL;

-- test: chronology_qualified_created
-- If a lead is qualified, the qualified_on date must be on or after the created_on date.
SELECT
  IF(
    COUNTIF(qualified_on < created_on) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'chronology_qualified_created' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.lead`
WHERE qualified_on IS NOT NULL;