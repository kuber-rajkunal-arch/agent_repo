/*
Unit Tests for: quote_detail
Description: Tests the data integrity of the curated quote_detail table.
*/

-- Placeholder for the GCP project and dataset variables.
-- Replace 'your-gcp-project-id' and 'Curated' with your actual project and dataset.
DECLARE gcp_project_id STRING DEFAULT 'your-gcp-project-id';
DECLARE curated_dataset STRING DEFAULT 'Curated';

-- test: not_null_quote_detail_id
-- The primary key 'quote_detail_id' must not contain null values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_detail_id' AS test_name
FROM
  `your-gcp-project-id.Curated.quote_detail`
WHERE
  quote_detail_id IS NULL;

-- test: unique_quote_detail_id
-- The primary key 'quote_detail_id' must be unique across all records.
SELECT
  IF(
    COUNT(quote_detail_id) = COUNT(DISTINCT quote_detail_id),
    'PASS',
    'FAIL'
  ) AS result,
  'unique_quote_detail_id' AS test_name
FROM
  `your-gcp-project-id.Curated.quote_detail`;

-- test: referential_integrity_quote_id
-- Each 'quote_id' in the quote_detail table must exist in the quote table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_quote_id' AS test_name
FROM
  `your-gcp-project-id.Curated.quote_detail` AS qd
LEFT JOIN
  `your-gcp-project-id.Curated.quote` AS q
  ON qd.quote_id = q.quote_id
WHERE
  qd.quote_id IS NOT NULL AND q.quote_id IS NULL;

-- test: positive_quantity
-- The 'quantity' of a line item must be greater than zero.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'positive_quantity' AS test_name
FROM
  `your-gcp-project-id.Curated.quote_detail`
WHERE
  quantity IS NOT NULL AND quantity <= 0;

-- test: positive_unit_price
-- The 'unit_price' of a line item cannot be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'positive_unit_price' AS test_name
FROM
  `your-gcp-project-id.Curated.quote_detail`
WHERE
  unit_price IS NOT NULL AND unit_price < 0;

-- test: range_discount
-- The 'discount' should be a factor between 0 and 1 (e.g., 0.1 for 10%).
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_discount' AS test_name
FROM
  `your-gcp-project-id.Curated.quote_detail`
WHERE
  discount IS NOT NULL AND (discount < 0 OR discount > 1);

-- test: consistency_total_amount
-- The 'total_amount' should equal the calculated value from quantity, price, and discount.
-- A small tolerance (0.01) is used to account for floating-point inaccuracies.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'consistency_total_amount' AS test_name
FROM
  `your-gcp-project-id.Curated.quote_detail`
WHERE
  -- Only test where all components are not null
  quantity IS NOT NULL AND unit_price IS NOT NULL AND discount IS NOT NULL AND total_amount IS NOT NULL
  AND ABS(
    (quantity * unit_price * (1 - discount)) - total_amount
  ) > 0.01;