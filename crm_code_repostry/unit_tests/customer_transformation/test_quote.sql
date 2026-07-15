-- ===================================================================================
--
-- Unit Tests for Curated.quote
--
-- ===================================================================================

-- test: not_null_quote_id
-- The primary key `quote_id` must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_id' AS test_name,
  'The primary key `quote_id` must not be null.' AS description
FROM
  `Curated.quote`
WHERE
  quote_id IS NULL;

-- test: unique_quote_id
-- The primary key `quote_id` must be unique.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_quote_id' AS test_name,
  'The primary key `quote_id` must be unique.' AS description
FROM (
  SELECT
    quote_id
  FROM
    `Curated.quote`
  WHERE
    quote_id IS NOT NULL
  GROUP BY
    quote_id
  HAVING
    COUNT(*) > 1
);

-- test: not_null_created_on
-- The `created_on` timestamp is a critical field and should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_created_on' AS test_name,
  'The `created_on` timestamp should always be populated.' AS description
FROM
  `Curated.quote`
WHERE
  created_on IS NULL;

-- test: referential_integrity_opportunity_id
-- The `opportunity_id` must exist in the `Curated.opportunity` table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_opportunity_id' AS test_name,
  'The `opportunity_id` must exist in `Curated.opportunity`.' AS description
FROM (
  SELECT
    Q.opportunity_id
  FROM
    `Curated.quote` AS Q
    LEFT JOIN `Curated.opportunity` AS O ON Q.opportunity_id = O.opportunity_id
  WHERE
    Q.opportunity_id IS NOT NULL
    AND O.opportunity_id IS NULL
);

-- test: referential_integrity_customer_id
-- The `customer_id` must exist in the `Curated.customer` table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customer_id' AS test_name,
  'The `customer_id` must exist in `Curated.customer`.' AS description
FROM (
  SELECT
    Q.customer_id
  FROM
    `Curated.quote` AS Q
    LEFT JOIN `Curated.customer` AS C ON Q.customer_id = C.customer_id
  WHERE
    Q.customer_id IS NOT NULL
    AND C.customer_id IS NULL
);

-- test: domain_status
-- The `status` field should only contain expected values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'domain_status' AS test_name,
  'The `status` field should only contain expected values.' AS description
FROM
  `Curated.quote`
WHERE
  status IS NOT NULL
  AND status NOT IN ('Draft', 'Active', 'Won', 'Lost', 'Expired');

-- test: range_total_amount
-- The `total_amount` should be non-negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_total_amount' AS test_name,
  'The `total_amount` should be non-negative.' AS description
FROM
  `Curated.quote`
WHERE
  total_amount IS NOT NULL
  AND total_amount < 0;

-- test: consistency_valid_to_vs_valid_from
-- The `valid_to` date must not be earlier than the `valid_from` date.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'consistency_valid_to_vs_valid_from' AS test_name,
  'The `valid_to` date must not be earlier than `valid_from`.' AS description
FROM
  `Curated.quote`
WHERE
  valid_to < valid_from;

-- test: financial_integrity_total_amount
-- The `total_amount` in the quote header must match the sum of `total_amount` from its detail lines.
-- A small tolerance (0.01) is used for floating point comparison.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'financial_integrity_total_amount' AS test_name,
  'Header `total_amount` must match sum of detail line totals.' AS description
FROM (
  SELECT
    Q.quote_id,
    Q.total_amount AS header_total,
    SUM(QD.total_amount) AS calculated_detail_total
  FROM
    `Curated.quote` AS Q
    JOIN `Curated.quote_detail` AS QD ON Q.quote_id = QD.quote_id
  GROUP BY
    Q.quote_id,
    Q.total_amount
)
WHERE
  ABS(header_total - calculated_detail_total) > 0.01;