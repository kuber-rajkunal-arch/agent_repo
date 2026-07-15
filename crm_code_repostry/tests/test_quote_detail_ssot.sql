/*
  Unit tests for the Curated.quote_detail table.
  These tests validate the data integrity of the quote line items.
*/

-- test: unique_quote_detail_id
-- Ensures that every quote line item has a unique identifier.
SELECT
  IF(COUNT(quote_detail_id) = COUNT(DISTINCT quote_detail_id), 'PASS', 'FAIL') AS result,
  'unique_quote_detail_id' AS test_name
FROM
  `Curated.quote_detail`;

-- test: not_null_quote_detail_id
-- The primary key for the quote_detail table must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_detail_id' AS test_name
FROM
  `Curated.quote_detail`
WHERE
  quote_detail_id IS NULL;

-- test: not_null_quote_id
-- Every quote line item must be associated with a parent quote.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_id' AS test_name
FROM
  `Curated.quote_detail`
WHERE
  quote_id IS NULL;

-- test: referential_integrity_quote_id
-- The quote_id on a line item must exist in the parent quote table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_quote_id' AS test_name
FROM
  `Curated.quote_detail` AS qd
LEFT JOIN
  `Curated.quote` AS q
  ON qd.quote_id = q.quote_id
WHERE
  q.quote_id IS NULL;

-- test: range_check_quantity
-- The quantity of a product on a quote line must be a positive number.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_quantity' AS test_name
FROM
  `Curated.quote_detail`
WHERE
  quantity <= 0;

-- test: range_check_unit_price
-- The unit price for a product cannot be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_unit_price' AS test_name
FROM
  `Curated.quote_detail`
WHERE
  unit_price < 0;

-- test: range_check_discount
-- The discount must be a valid percentage, represented as a decimal between 0 and 1.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_discount' AS test_name
FROM
  `Curated.quote_detail`
WHERE
  discount < 0
  OR discount > 1;

-- test: consistency_check_total_amount
-- Checks if total_amount is consistent with quantity, unit_price, and discount.
-- Allows for a small tolerance for floating point arithmetic.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'consistency_check_total_amount' AS test_name
FROM
  `Curated.quote_detail`
WHERE
  ABS( (quantity * unit_price * (
    1 - discount
  )) - total_amount ) > 0.01;