-- =================================================================================================
-- Unit Tests for crm_code_files/customer_ssot.sql - quote_detail table
--
-- Description: These tests validate the data integrity of the `quote_detail` table after the
--              incremental load.
-- =================================================================================================

-- test: not_null_quote_detail_id
-- A quote line item must always have a primary key.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_detail_id' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.quote_detail`
WHERE quote_detail_id IS NULL;

-- test: unique_quote_detail_id
-- The quote_detail_id must be unique to serve as a primary key.
SELECT
  IF(COUNT(quote_detail_id) = COUNT(DISTINCT quote_detail_id), 'PASS', 'FAIL') AS result,
  'unique_quote_detail_id' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.quote_detail`;

-- test: fk_quote_detail_quote_id_exists
-- Every quote line item must be linked to a valid, existing quote.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'fk_quote_detail_quote_id_exists' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.quote_detail` AS qd
LEFT JOIN `{{ project_id }}.{{ curated_dataset }}.quote` AS q
  ON qd.quote_id = q.quote_id
WHERE qd.quote_id IS NOT NULL AND q.quote_id IS NULL;

-- test: positive_quantity
-- The quantity of a product on a quote should be positive.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'positive_quantity' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.quote_detail`
WHERE quantity <= 0;

-- test: non_negative_unit_price
-- The unit price of a product should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'non_negative_unit_price' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.quote_detail`
WHERE unit_price < 0;

-- test: range_discount
-- The discount must be a percentage between 0 and 1 (inclusive).
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_discount' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.quote_detail`
WHERE discount < 0 OR discount > 1;

-- test: consistency_total_amount
-- The total_amount should equal the calculated value from quantity, price, and discount.
-- A small tolerance (0.01) is used to account for floating point inaccuracies.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'consistency_total_amount' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.quote_detail`
WHERE
  ABS(total_amount - (quantity * unit_price * (1 - discount))) > 0.01;