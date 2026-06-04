/*
  Unit tests for the incremental load of the Curated.quote table.
  These tests validate data integrity, referential integrity, and the specific
  financial integrity checks applied during the MERGE operation.
*/

-- test: not_null_quote_id
-- The primary key for the quote table must not be null.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_quote_id' AS test_name
FROM `<project_id>.<curated_dataset>.quote`
WHERE quote_id IS NULL;

-- test: unique_quote_id
-- The primary key for the quote table must be unique.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'unique_quote_id' AS test_name
FROM (
  SELECT
    quote_id
  FROM `<project_id>.<curated_dataset>.quote`
  WHERE quote_id IS NOT NULL
  GROUP BY quote_id
  HAVING COUNT(*) > 1
);

-- test: referential_integrity_customer_id
-- Validates that every customer_id in the quote table corresponds
-- to an existing record in the customer table.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'referential_integrity_customer_id' AS test_name
FROM `<project_id>.<curated_dataset>.quote` AS q
LEFT JOIN `<project_id>.<curated_dataset>.customer` AS c
  ON q.customer_id = c.customer_id
WHERE
  q.customer_id IS NOT NULL
  AND c.customer_id IS NULL;

-- test: referential_integrity_opportunity_id
-- Validates that every opportunity_id in the quote table corresponds
-- to an existing record in the opportunity table.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'referential_integrity_opportunity_id' AS test_name
FROM `<project_id>.<curated_dataset>.quote` AS q
LEFT JOIN `<project_id>.<curated_dataset>.opportunity` AS o
  ON q.opportunity_id = o.opportunity_id
WHERE
  q.opportunity_id IS NOT NULL
  AND o.opportunity_id IS NULL;

-- test: financial_integrity_total_amount
-- Validates that every quote loaded into the curated table satisfies the financial
-- integrity check from the source MERGE statement. The header total_amount must
-- equal the sum of its line item totals from the raw staging table (or 0 if no lines).
WITH
  RawQuoteDetailTotals AS (
    -- Recalculate total amount from raw detail lines
    SELECT
      quote_id,
      SUM(total_amount) AS calculated_total
    FROM `<project_id>.<raw_dataset>.stg_quote_detail`
    GROUP BY quote_id
  ),
  MismatchedTotals AS (
    -- Find curated quotes where the header total does not match the sum of its raw lines
    SELECT
      q.quote_id
    FROM `<project_id>.<curated_dataset>.quote` AS q
    LEFT JOIN RawQuoteDetailTotals AS r_qdt
      ON q.quote_id = r_qdt.quote_id
    -- The check in the source MERGE is `hdr.total_amount = COALESCE(dtl.calculated_total_amount, 0)`.
    -- We use an epsilon for float comparison to handle potential inaccuracies.
    WHERE ABS(q.total_amount - COALESCE(r_qdt.calculated_total, 0)) > 0.01
  )
SELECT
  IF(
    (SELECT COUNT(*) FROM MismatchedTotals) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'financial_integrity_total_amount' AS test_name;