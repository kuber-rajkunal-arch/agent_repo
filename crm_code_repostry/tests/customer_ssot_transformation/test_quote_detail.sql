-- Unit tests for the curated 'quote_detail' table.
-- These tests verify primary key integrity and basic value constraints after the sp_load_quote_detail procedure runs.

-- test: not_null_quote_detail_id
-- The primary key `quote_detail_id` must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_detail_id' AS test_name,
  'All quote_detail_id records must be not-null.' AS description
FROM `your-gcp-project-id.Curated.quote_detail`
WHERE quote_detail_id IS NULL;

-- test: unique_quote_detail_id
-- The primary key `quote_detail_id` must be unique across all records.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_quote_detail_id' AS test_name,
  'All quote_detail_id records must be unique.' AS description
FROM (
  SELECT
    quote_detail_id
  FROM `your-gcp-project-id.Curated.quote_detail`
  WHERE quote_detail_id IS NOT NULL
  GROUP BY quote_detail_id
  HAVING COUNT(*) > 1
);

-- test: not_null_quote_detail_quote_id
-- The foreign key `quote_id` is mandatory for linking a detail line to a quote header.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_detail_quote_id' AS test_name,
  'All quote_detail records must have a non-null quote_id.' AS description
FROM `your-gcp-project-id.Curated.quote_detail`
WHERE quote_id IS NULL;

-- test: positive_value_quote_detail_quantity
-- The quantity of a line item should be a positive number.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'positive_value_quote_detail_quantity' AS test_name,
  'All quote_detail quantities should be greater than zero.' AS description
FROM `your-gcp-project-id.Curated.quote_detail`
WHERE quantity <= 0;

-- test: non_negative_value_quote_detail_unit_price
-- The unit price of a line item should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'non_negative_value_quote_detail_unit_price' AS test_name,
  'All quote_detail unit prices should be non-negative.' AS description
FROM `your-gcp-project-id.Curated.quote_detail`
WHERE unit_price < 0;