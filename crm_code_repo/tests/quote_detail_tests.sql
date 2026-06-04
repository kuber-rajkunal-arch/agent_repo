/*
--------------------------------------------------------------------------------
--
-- Test File: quote_detail_tests.sql
--
-- Purpose: Unit tests for the `quote_detail` table.
--
-- Author: Senior Software/Quality Engineer
--
--------------------------------------------------------------------------------
*/

-- =============================================================================
-- Tests for the `quote_detail` table
-- =============================================================================

-- test: quote_detail_not_null_quote_detail_id
-- The primary key `quote_detail_id` must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_not_null_quote_detail_id' AS test_name
FROM `your_project_id.your_curated_dataset.quote_detail`
WHERE quote_detail_id IS NULL;

-- test: quote_detail_unique_quote_detail_id
-- The primary key `quote_detail_id` must be unique.
SELECT
  IF(
    (SELECT COUNT(quote_detail_id) FROM `your_project_id.your_curated_dataset.quote_detail`) =
    (SELECT COUNT(DISTINCT quote_detail_id) FROM `your_project_id.your_curated_dataset.quote_detail`),
    'PASS', 'FAIL'
  ) AS result,
  'quote_detail_unique_quote_detail_id' AS test_name;

-- test: quote_detail_not_null_quote_id
-- The foreign key `quote_id` must not be null, as a detail line cannot exist without a header.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_not_null_quote_id' AS test_name
FROM `your_project_id.your_curated_dataset.quote_detail`
WHERE quote_id IS NULL;

-- test: quote_detail_fk_quote_id
-- The `quote_id` must exist in the `quote` table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_fk_quote_id' AS test_name
FROM `your_project_id.your_curated_dataset.quote_detail` AS qd
LEFT JOIN `your_project_id.your_curated_dataset.quote` AS q
  ON qd.quote_id = q.quote_id
WHERE
  qd.quote_id IS NOT NULL
  AND q.quote_id IS NULL;

-- test: quote_detail_valid_quantity
-- The `quantity` must be a positive number.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_valid_quantity' AS test_name
FROM `your_project_id.your_curated_dataset.quote_detail`
WHERE
  quantity IS NOT NULL
  AND quantity <= 0;

-- test: quote_detail_valid_unit_price
-- The `unit_price` must not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_valid_unit_price' AS test_name
FROM `your_project_id.your_curated_dataset.quote_detail`
WHERE
  unit_price IS NOT NULL
  AND unit_price < 0;

-- test: quote_detail_consistent_total_amount
-- The `total_amount` for a line item should be consistent with its components.
-- This test assumes discount is a fixed amount. Adjust if it's a percentage.
-- A small tolerance (e.g., 0.01) is used for floating point comparisons.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_consistent_total_amount' AS test_name
FROM `your_project_id.your_curated_dataset.quote_detail`
WHERE
  ABS((quantity * unit_price) - COALESCE(discount, 0) - total_amount) > 0.01
  AND quantity IS NOT NULL
  AND unit_price IS NOT NULL
  AND total_amount IS NOT NULL;

-- test: quote_detail_rollup_to_quote_header
-- The sum of `total_amount` from detail lines must match the `total_amount` in the quote header.
-- A small tolerance (e.g., 0.01) is used for floating point comparisons.
WITH
  detail_sum AS (
    SELECT
      quote_id,
      SUM(total_amount) AS calculated_total
    FROM `your_project_id.your_curated_dataset.quote_detail`
    GROUP BY quote_id
  )
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_rollup_to_quote_header' AS test_name
FROM `your_project_id.your_curated_dataset.quote` AS q
JOIN detail_sum AS ds
  ON q.quote_id = ds.quote_id
WHERE
  ABS(q.total_amount - ds.calculated_total) > 0.01;