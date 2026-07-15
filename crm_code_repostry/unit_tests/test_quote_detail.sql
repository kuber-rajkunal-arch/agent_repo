/*
  Unit tests for the 'curated.quote_detail' table.
  These tests validate the data integrity of the final quote_detail table
  after the transformation script has been executed. The tests cover key integrity,
  referential integrity, value ranges, and calculation logic.
*/

-- test: not_null_quote_detail_id
-- The primary key 'quote_detail_id' should never be null.
SELECT
  IF(COUNTIF(quote_detail_id IS NULL) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_detail_id' AS test_name
FROM `curated.quote_detail`;

-- test: unique_quote_detail_id
-- The primary key 'quote_detail_id' must be unique across all records.
SELECT
  IF(COUNT(quote_detail_id) = COUNT(DISTINCT quote_detail_id), 'PASS', 'FAIL') AS result,
  'unique_quote_detail_id' AS test_name
FROM `curated.quote_detail`;

-- test: not_null_quote_id
-- Every quote line item must be associated with a quote.
SELECT
  IF(COUNTIF(quote_id IS NULL) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_id' AS test_name
FROM `curated.quote_detail`;

-- test: not_null_product_name
-- The product name is a critical field and should not be null.
SELECT
  IF(COUNTIF(product_name IS NULL) = 0, 'PASS', 'FAIL') AS result,
  'not_null_product_name' AS test_name
FROM `curated.quote_detail`;

-- test: referential_quote_id
-- The 'quote_id' in the quote_detail table must exist in the quote table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_quote_id' AS test_name
FROM `curated.quote_detail` AS qd
LEFT JOIN `curated.quote` AS q
  ON qd.quote_id = q.quote_id
WHERE
  qd.quote_id IS NOT NULL
  AND q.quote_id IS NULL;

-- test: range_quantity
-- The 'quantity' of a product must be a positive number.
SELECT
  IF(COUNTIF(quantity <= 0) = 0, 'PASS', 'FAIL') AS result,
  'range_quantity' AS test_name
FROM `curated.quote_detail`
WHERE quantity IS NOT NULL;

-- test: range_unit_price
-- The 'unit_price' should be non-negative.
SELECT
  IF(COUNTIF(unit_price < 0) = 0, 'PASS', 'FAIL') AS result,
  'range_unit_price' AS test_name
FROM `curated.quote_detail`
WHERE unit_price IS NOT NULL;

-- test: range_discount
-- The 'discount' field should be a value between 0 and 1, inclusive.
SELECT
  IF(COUNTIF(discount < 0 OR discount > 1) = 0, 'PASS', 'FAIL') AS result,
  'range_discount' AS test_name
FROM `curated.quote_detail`
WHERE discount IS NOT NULL;

-- test: logic_total_amount_calculation
-- The 'total_amount' should equal quantity * unit_price * (1 - discount).
-- A small tolerance is used to account for floating point inaccuracies.
SELECT
  IF(COUNTIF(ABS(total_amount - (quantity * unit_price * (1 - discount))) > 0.01) = 0, 'PASS', 'FAIL') AS result,
  'logic_total_amount_calculation' AS test_name
FROM `curated.quote_detail`
WHERE
  total_amount IS NOT NULL
  AND quantity IS NOT NULL
  AND unit_price IS NOT NULL
  AND discount IS NOT NULL;