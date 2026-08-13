/*
  Unit tests for the Curated.quote_detail table, targeting the customer_transformation.sql script.
  This script performs a basic MERGE without inline quality checks. These tests
  serve as post-load validation of referential and financial integrity.
*/

-- test: not_null_quote_detail_id
-- The primary key for the quote_detail table must not be null.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_quote_detail_id' AS test_name,
  'All quote_detail_id values must be non-null.' AS description
FROM `Curated.quote_detail`
WHERE quote_detail_id IS NULL;

-- test: unique_quote_detail_id
-- The primary key for the quote_detail table must be unique.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'unique_quote_detail_id' AS test_name,
  'Each quote_detail_id must be unique.' AS description
FROM (
  SELECT
    quote_detail_id
  FROM `Curated.quote_detail`
  WHERE quote_detail_id IS NOT NULL
  GROUP BY quote_detail_id
  HAVING COUNT(*) > 1
);

-- test: referential_integrity_quote_id
-- Post-load check: Validates that every quote_id in the quote_detail table
-- corresponds to an existing record in the quote table.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'referential_integrity_quote_id' AS test_name,
  'All quote_detail.quote_id values must exist in the quote table.' AS description
FROM `Curated.quote_detail` AS qd
LEFT JOIN `Curated.quote` AS q
  ON qd.quote_id = q.quote_id
WHERE
  qd.quote_id IS NOT NULL
  AND q.quote_id IS NULL;

-- test: financial_integrity_line_item_total
-- Post-load check: Infers that total_amount should be calculated as:
-- quantity * unit_price * (1 - discount). A failure indicates a source data quality issue.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'financial_integrity_line_item_total' AS test_name,
  'Line item total_amount should equal quantity * unit_price * (1 - discount).' AS description
FROM `Curated.quote_detail`
WHERE
  ABS(total_amount - (quantity * unit_price * (1.0 - COALESCE(discount, 0)))) > 0.01;