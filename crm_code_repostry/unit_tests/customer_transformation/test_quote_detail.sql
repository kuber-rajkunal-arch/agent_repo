-- ===================================================================================
--
-- Unit Tests for Curated.quote_detail
--
-- ===================================================================================

-- test: not_null_quote_detail_id
-- The primary key `quote_detail_id` must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_detail_id' AS test_name,
  'The primary key `quote_detail_id` must not be null.' AS description
FROM
  `Curated.quote_detail`
WHERE
  quote_detail_id IS NULL;

-- test: unique_quote_detail_id
-- The primary key `quote_detail_id` must be unique.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_quote_detail_id' AS test_name,
  'The primary key `quote_detail_id` must be unique.' AS description
FROM (
  SELECT
    quote_detail_id
  FROM
    `Curated.quote_detail`
  WHERE
    quote_detail_id IS NOT NULL
  GROUP BY
    quote_detail_id
  HAVING
    COUNT(*) > 1
);

-- test: not_null_quote_id
-- The foreign key `quote_id` must not be null, as a detail line must belong to a quote.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_id' AS test_name,
  'The foreign key `quote_id` must not be null.' AS description
FROM
  `Curated.quote_detail`
WHERE
  quote_id IS NULL;

-- test: referential_integrity_quote_id
-- The `quote_id` must exist in the `Curated.quote` table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_quote_id' AS test_name,
  'The `quote_id` must exist in the `Curated.quote` table.' AS description
FROM (
  SELECT
    QD.quote_id
  FROM
    `Curated.quote_detail` AS QD
    LEFT JOIN `Curated.quote` AS Q ON QD.quote_id = Q.quote_id
  WHERE
    QD.quote_id IS NOT NULL
    AND Q.quote_id IS NULL
);

-- test: range_quantity
-- The `quantity` of a line item should be a positive number.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_quantity' AS test_name,
  'The `quantity` of a line item should be a positive number.' AS description
FROM
  `Curated.quote_detail`
WHERE
  quantity IS NOT NULL
  AND quantity <= 0;

-- test: range_unit_price
-- The `unit_price` should be non-negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_unit_price' AS test_name,
  'The `unit_price` should be non-negative.' AS description
FROM
  `Curated.quote_detail`
WHERE
  unit_price IS NOT NULL
  AND unit_price < 0;

-- test: consistency_total_amount_calculation
-- The `total_amount` should be consistent with quantity, unit_price, and discount.
-- This test assumes `discount` is a fixed amount, not a percentage.
-- A small tolerance (0.01) is used for floating point comparison.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'consistency_total_amount_calculation' AS test_name,
  '`total_amount` should be consistent with (qty * price) - discount.' AS description
FROM
  `Curated.quote_detail`
WHERE
  ABS(
    (
      COALESCE(quantity, 0) * COALESCE(unit_price, 0) - COALESCE(discount, 0)
    ) - COALESCE(total_amount, 0)
  ) > 0.01;