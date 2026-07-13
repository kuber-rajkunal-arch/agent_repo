--
-- Unit tests for the curated quote_detail table.
-- These tests validate the data integrity of the `<project_id>.<curated_dataset>.quote_detail` table
-- after the MERGE operation from `crm_code/customer_ssot.sql` is executed.
--

-- test: not_null_quote_detail_id
-- The primary key `quote_detail_id` must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_detail_id' AS test_name
FROM
  `<project_id>.<curated_dataset>.quote_detail`
WHERE
  quote_detail_id IS NULL;

-- test: unique_quote_detail_id
-- The primary key `quote_detail_id` must be unique across all records.
SELECT
  IF(COUNT(quote_detail_id) = COUNT(DISTINCT quote_detail_id), 'PASS', 'FAIL') AS result,
  'unique_quote_detail_id' AS test_name
FROM
  `<project_id>.<curated_dataset>.quote_detail`;

-- test: not_null_quote_id
-- The foreign key `quote_id` must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_id' AS test_name
FROM
  `<project_id>.<curated_dataset>.quote_detail`
WHERE
  quote_id IS NULL;

-- test: referential_integrity_quote_id
-- Every `quote_id` in `quote_detail` must exist in the `quote` table.
-- This ensures that details are only loaded for valid, existing quotes.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_quote_id' AS test_name
FROM (
  SELECT DISTINCT quote_id
  FROM `<project_id>.<curated_dataset>.quote_detail`
) AS dtl
LEFT JOIN `<project_id>.<curated_dataset>.quote` AS hdr
  ON dtl.quote_id = hdr.quote_id
WHERE
  hdr.quote_id IS NULL;

-- test: line_item_total_calculation
-- The `total_amount` for a line item should be correctly calculated.
-- Formula: quantity * unit_price * (1 - discount)
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'line_item_total_calculation' AS test_name
FROM
  `<project_id>.<curated_dataset>.quote_detail`
WHERE
  -- Use a small tolerance for floating point comparisons.
  ABS(total_amount - (quantity * unit_price * (1.0 - discount))) > 0.01;

-- test: positive_quantity
-- The `quantity` of a product must be a positive number.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'positive_quantity' AS test_name
FROM
  `<project_id>.<curated_dataset>.quote_detail`
WHERE
  quantity <= 0;

-- test: non_negative_unit_price
-- The `unit_price` cannot be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'non_negative_unit_price' AS test_name
FROM
  `<project_id>.<curated_dataset>.quote_detail`
WHERE
  unit_price < 0;