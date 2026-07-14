-- =============================================================================
-- Unit Tests for curated.quote_detail
--
-- These tests validate the data integrity of the `quote_detail` table after
-- the MERGE operation.
-- =============================================================================

-- test: not_null_quote_detail_id
-- The quote_detail_id is the primary key and should never be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_detail_id' AS test_name
FROM `your_project_id.your_curated_dataset.quote_detail`
WHERE quote_detail_id IS NULL;

-- test: unique_quote_detail_id
-- The quote_detail_id must be unique to serve as a primary key.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_quote_detail_id' AS test_name
FROM (
  SELECT
    quote_detail_id
  FROM `your_project_id.your_curated_dataset.quote_detail`
  WHERE quote_detail_id IS NOT NULL
  GROUP BY
    quote_detail_id
  HAVING
    COUNT(*) > 1
);

-- test: not_null_quote_id
-- Every quote detail line must be associated with a quote.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_id' AS test_name
FROM `your_project_id.your_curated_dataset.quote_detail`
WHERE quote_id IS NULL;

-- test: referential_integrity_quote_id
-- The quote_id in the quote_detail table must exist in the quote table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_quote_id' AS test_name
FROM `your_project_id.your_curated_dataset.quote_detail` AS qd
LEFT JOIN `your_project_id.your_curated_dataset.quote` AS q
  ON qd.quote_id = q.quote_id
WHERE
  qd.quote_id IS NOT NULL
  AND q.quote_id IS NULL;

-- test: positive_quantity
-- The quantity of a product must be a positive number.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'positive_quantity' AS test_name
FROM `your_project_id.your_curated_dataset.quote_detail`
WHERE quantity <= 0;

-- test: non_negative_unit_price
-- The unit price of a product cannot be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'non_negative_unit_price' AS test_name
FROM `your_project_id.your_curated_dataset.quote_detail`
WHERE unit_price < 0;

-- test: range_check_discount
-- Discount must be between 0 and 1, inclusive.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_discount' AS test_name
FROM `your_project_id.your_curated_dataset.quote_detail`
WHERE discount IS NOT NULL AND (discount < 0 OR discount > 1);

-- test: calculated_total_amount
-- The total_amount should equal quantity * unit_price * (1 - discount).
-- A small tolerance is added for floating point inaccuracies.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'calculated_total_amount' AS test_name
FROM `your_project_id.your_curated_dataset.quote_detail`
WHERE
  quantity IS NOT NULL
  AND unit_price IS NOT NULL
  AND total_amount IS NOT NULL
  AND ABS(total_amount - (quantity * unit_price * (
    1 - COALESCE(discount, 0)
  ))) > 0.01;