-- ===================================================================================
--
-- Unit Tests for Curated.quote
--
-- ===================================================================================

-- test: not_null_quote_id
-- The primary key `quote_id` must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_id' AS test_name
FROM
  `Curated.quote`
WHERE
  quote_id IS NULL;

-- test: unique_quote_id
-- The primary key `quote_id` must be unique.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_quote_id' AS test_name
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
  'not_null_created_on' AS test_name
FROM
  `Curated.quote`
WHERE
  created_on IS NULL;

-- test: referential_integrity_opportunity_id
-- If `opportunity_id` is present, it must exist in the `Curated.opportunity` table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_opportunity_id' AS test_name
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
-- If `customer_id` is present, it must exist in the `Curated.customer` table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customer_id' AS test_name
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
  'domain_status' AS test_name
FROM
  `Curated.quote`
WHERE
  status IS NOT NULL
  AND status NOT IN ('Draft', 'Active', 'Won', 'Lost', 'Expired');

-- test: range_total_amount
-- The `total_amount` should be non-negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_total_amount' AS test_name
FROM
  `Curated.quote`
WHERE
  total_amount IS NOT NULL
  AND total_amount < 0;

-- test: consistency_valid_to_vs_valid_from
-- The `valid_to` date must not be earlier than the `valid_from` date.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'consistency_valid_to_vs_valid_from' AS test_name
FROM
  `Curated.quote`
WHERE
  valid_to < valid_from;