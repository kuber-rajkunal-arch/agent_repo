/*
  Unit tests for the Curated.quote table, targeting the customer_transformation.sql script.
  This script performs a basic MERGE without inline quality checks. These tests
  serve as post-load validation of referential and financial integrity.
*/

-- test: not_null_quote_id
-- The primary key for the quote table must not be null.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_quote_id' AS test_name,
  'All quote_id values must be non-null.' AS description
FROM `Curated.quote`
WHERE quote_id IS NULL;

-- test: unique_quote_id
-- The primary key for the quote table must be unique.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'unique_quote_id' AS test_name,
  'Each quote_id must be unique.' AS description
FROM (
  SELECT
    quote_id
  FROM `Curated.quote`
  WHERE quote_id IS NOT NULL
  GROUP BY quote_id
  HAVING COUNT(*) > 1
);

-- test: referential_integrity_customer_id
-- Post-load check: Validates that every customer_id in the quote table
-- corresponds to an existing record in the customer table.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'referential_integrity_customer_id' AS test_name,
  'All quote.customer_id values must exist in the customer table.' AS description
FROM `Curated.quote` AS q
LEFT JOIN `Curated.customer` AS c
  ON q.customer_id = c.customer_id
WHERE
  q.customer_id IS NOT NULL
  AND c.customer_id IS NULL;

-- test: referential_integrity_opportunity_id
-- Post-load check: Validates that every opportunity_id in the quote table
-- corresponds to an existing record in the opportunity table.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'referential_integrity_opportunity_id' AS test_name,
  'All quote.opportunity_id values must exist in the opportunity table.' AS description
FROM `Curated.quote` AS q
LEFT JOIN `Curated.opportunity` AS o
  ON q.opportunity_id = o.opportunity_id
WHERE
  q.opportunity_id IS NOT NULL
  AND o.opportunity_id IS NULL;

-- test: financial_integrity_total_amount
-- Post-load check: Validates that the total_amount on a quote header matches the sum of its
-- line item totals. A failure indicates an inconsistency in the source data.
WITH
QuoteDetailTotals AS (
  SELECT
    quote_id,
    SUM(total_amount) AS calculated_total
  FROM `Curated.quote_detail`
  GROUP BY quote_id
),
MismatchedTotals AS (
  SELECT
    q.quote_id
  FROM `Curated.quote` AS q
  JOIN QuoteDetailTotals AS qdt
    ON q.quote_id = qdt.quote_id
  WHERE ABS(q.total_amount - qdt.calculated_total) > 0.01
)
SELECT
  IF(
    (SELECT COUNT(*) FROM MismatchedTotals) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'financial_integrity_total_amount' AS test_name,
  'Quote header total_amount should match the sum of its detail lines.' AS description;