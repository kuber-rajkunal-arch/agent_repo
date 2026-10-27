/*
  Unit tests for the Curated.customer table.
  These tests validate the output of the crm_transformation.sql script.
*/

-- Declare variables to match the source script's parameterization
DECLARE v_project_id STRING DEFAULT 'your_project_id';
DECLARE v_curated_dataset STRING DEFAULT 'Curated';

-- test: unique_customer_id
-- The customer_id must be unique to serve as a primary key.
SELECT
  IF(
    COUNT(customer_id) = COUNT(DISTINCT customer_id),
    'PASS',
    'FAIL'
  ) AS result,
  'unique_customer_id' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.customer`;

-- test: not_null_customer_id
-- The primary key for the customer table cannot be null.
SELECT
  IF(
    COUNTIF(customer_id IS NULL) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_customer_id' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.customer`;

-- test: not_null_created_on
-- The created_on timestamp is a critical audit field and should never be null.
SELECT
  IF(
    COUNTIF(created_on IS NULL) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_created_on' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.customer`;

-- test: not_null_modified_on
-- The modified_on timestamp is used for watermarking and auditing; it should never be null.
SELECT
  IF(
    COUNTIF(modified_on IS NULL) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_modified_on' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.customer`;

-- test: domain_is_active
-- The is_active flag should only contain boolean values (TRUE or FALSE).
SELECT
  IF(
    COUNTIF(is_active IS NULL OR is_active NOT IN (TRUE, FALSE)) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'domain_is_active' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.customer`;

-- test: chronology_created_modified
-- The modified_on date should always be greater than or equal to the created_on date.
SELECT
  IF(
    COUNTIF(modified_on < created_on) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'chronology_created_modified' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.customer`;