/*
  Unit tests for the Curated.quote_detail table.
  These tests validate the output of the crm_transformation.sql script.
*/

-- Declare variables to match the source script's parameterization
DECLARE v_project_id STRING DEFAULT 'your_project_id';
DECLARE v_curated_dataset STRING DEFAULT 'Curated';

-- test: unique_quote_detail_id
-- The quote_detail_id must be unique to serve as a primary key.
SELECT
  IF(
    COUNT(quote_detail_id) = COUNT(DISTINCT quote_detail_id),
    'PASS',
    'FAIL'
  ) AS result,
  'unique_quote_detail_id' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.quote_detail`;

-- test: not_null_quote_detail_id
-- The primary key for the quote_detail table cannot be null.
SELECT
  IF(
    COUNTIF(quote_detail_id IS NULL) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_quote_detail_id' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.quote_detail`;

-- test: not_null_quote_id
-- A quote detail line must be associated with a parent quote.
SELECT
  IF(
    COUNTIF(quote_id IS NULL) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_quote_id' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.quote_detail`;

-- test: referential_quote_id
-- The quote_id on a quote detail line must exist in the quote table.
SELECT
  IF(
    COUNT(QD.quote_id) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'referential_quote_id' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.quote_detail` AS QD
LEFT JOIN `${v_project_id}.${v_curated_dataset}.quote` AS Q
  ON QD.quote_id = Q.quote_id
WHERE Q.quote_id IS NULL;

-- test: range_quantity
-- The quantity of a product must be a positive number.
SELECT
  IF(
    COUNTIF(quantity <= 0) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'range_quantity' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.quote_detail`
WHERE quantity IS NOT NULL;

-- test: range_unit_price
-- The unit price cannot be negative.
SELECT
  IF(
    COUNTIF(unit_price < 0) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'range_unit_price' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.quote_detail`
WHERE unit_price IS NOT NULL;

-- test: range_discount
-- The discount should be a proportion between 0 and 1 (inclusive).
SELECT
  IF(
    COUNTIF(discount < 0 OR discount > 1) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'range_discount' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.quote_detail`
WHERE discount IS NOT NULL;

-- test: consistency_total_amount
-- The total_amount should equal quantity * unit_price * (1 - discount).
-- A small tolerance (0.01) is used to account for floating point inaccuracies.
SELECT
  IF(
    COUNTIF(
      ABS(
        total_amount - (
          SAFE_MULTIPLY(
            SAFE_MULTIPLY(quantity, unit_price),
            (1 - COALESCE(discount, 0))
          )
        )
      ) > 0.01
    ) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'consistency_total_amount' AS test_name
FROM `${v_project_id}.${v_curated_dataset}.quote_detail`
WHERE
  quantity IS NOT NULL
  AND unit_price IS NOT NULL
  AND total_amount IS NOT NULL;