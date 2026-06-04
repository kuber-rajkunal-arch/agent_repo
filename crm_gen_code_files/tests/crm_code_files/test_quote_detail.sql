/*
  Unit tests for the Curated.quote_detail table.
  These tests validate the data integrity, uniqueness, and referential
  integrity of the quote line items table after transformation.
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
FROM `your_gcp_project_id.Curated.quote_detail`
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
  FROM `your_gcp_project_id.Curated.quote_detail`
  WHERE quote_detail_id IS NOT NULL
  GROUP BY quote_detail_id
  HAVING COUNT(*) > 1
);

-- test: not_null_quote_id
-- The foreign key to the quote header table must not be null.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_quote_id' AS test_name
FROM `your_gcp_project_id.Curated.quote_detail`
WHERE quote_id IS NULL;

-- test: referential_integrity_quote_id
-- Validates that every quote_id in the quote_detail table corresponds
-- to an existing record in the quote table. This confirms the referential
-- integrity logic in the MERGE statement's USING clause.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'referential_integrity_quote_id' AS test_name
FROM `your_gcp_project_id.Curated.quote_detail` AS qd
LEFT JOIN `your_gcp_project_id.Curated.quote` AS q
  ON qd.quote_id = q.quote_id
WHERE
  qd.quote_id IS NOT NULL
  AND q.quote_id IS NULL;

-- test: financial_integrity_line_item_total
-- This test infers that total_amount should be calculated as:
-- quantity * unit_price * (1 - discount).
-- It checks for any significant deviation, allowing for floating point inaccuracies.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'financial_integrity_line_item_total' AS test_name
FROM `your_gcp_project_id.Curated.quote_detail`
WHERE
  -- Using an epsilon for float comparison
  ABS(total_amount - (quantity * unit_price * (1.0 - COALESCE(discount, 0)))) > 0.01;