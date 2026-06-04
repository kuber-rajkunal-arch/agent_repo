/*
  Unit tests for the incremental load of the Curated.quote_detail table.
  These tests validate data integrity, referential integrity, and financial
  calculations for quote line items.
*/

-- test: not_null_quote_detail_id
-- The primary key for the quote_detail table must not be null.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_quote_detail_id' AS test_name
FROM `<project_id>.<curated_dataset>.quote_detail`
WHERE quote_detail_id IS NULL;

-- test: unique_quote_detail_id
-- The primary key for the quote_detail table must be unique.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'unique_quote_detail_id' AS test_name
FROM (
  SELECT
    quote_detail_id
  FROM `<project_id>.<curated_dataset>.quote_detail`
  WHERE quote_detail_id IS NOT NULL
  GROUP BY quote_detail_id
  HAVING COUNT(*) > 1
);

-- test: referential_integrity_quote_id
-- Validates that every quote_id in the quote_detail table corresponds to an
-- existing record in the curated quote table. This confirms that the logic to
-- only load details for 'valid_incremental_quotes' is working correctly.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'referential_integrity_quote_id' AS test_name
FROM `<project_id>.<curated_dataset>.quote_detail` AS qd
LEFT JOIN `<project_id>.<curated_dataset>.quote` AS q
  ON qd.quote_id = q.quote_id
WHERE
  qd.quote_id IS NOT NULL
  AND q.quote_id IS NULL;

-- test: financial_integrity_line_item_total
-- This test infers a business rule that the line item total_amount should be
-- calculated as: quantity * unit_price * (1 - discount). It checks for any
-- significant deviation, ensuring the quality of the source data being loaded.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'financial_integrity_line_item_total' AS test_name
FROM `<project_id>.<curated_dataset>.quote_detail`
WHERE
  -- Using an epsilon for float comparison to handle potential inaccuracies
  ABS(total_amount - (quantity * unit_price * (1.0 - COALESCE(discount, 0)))) > 0.01;