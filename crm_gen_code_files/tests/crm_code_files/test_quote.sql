/*
  Unit tests for the Curated.quote table.
  These tests validate the data integrity, uniqueness, referential integrity,
  and financial calculations of the quote table after transformation.
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
FROM `your_gcp_project_id.Curated.quote`
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
  FROM `your_gcp_project_id.Curated.quote`
  WHERE quote_id IS NOT NULL
  GROUP BY quote_id
  HAVING COUNT(*) > 1
);

-- test: not_null_created_on
-- The creation timestamp is the partitioning key and must not be null.
SELECT
  IF(
    COUNT(*) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'not_null_created_on' AS test_name
FROM `your_gcp_project_id.Curated.quote`
WHERE created_on IS NULL;

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
FROM `your_gcp_project_id.Curated.quote` AS q
LEFT JOIN `your_gcp_project_id.Curated.customer` AS c
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
FROM `your_gcp_project_id.Curated.quote` AS q
LEFT JOIN `your_gcp_project_id.Curated.opportunity` AS o
  ON q.opportunity_id = o.opportunity_id
WHERE
  q.opportunity_id IS NOT NULL
  AND o.opportunity_id IS NULL;

-- test: financial_integrity_total_amount
-- Validates that the total_amount on a quote header matches the sum of its
-- line item totals from quote_detail. This test applies only to quotes
-- that have associated line items.
WITH
QuoteDetailTotals AS (
  -- Recalculate total amount from detail lines
  SELECT
    quote_id,
    SUM(total_amount) AS calculated_total
  FROM `your_gcp_project_id.Curated.quote_detail`
  GROUP BY quote_id
),
MismatchedTotals AS (
  -- Find quotes where the header total does not match the sum of its lines
  SELECT
    q.quote_id
  FROM `your_gcp_project_id.Curated.quote` AS q
  JOIN QuoteDetailTotals AS qdt
    ON q.quote_id = qdt.quote_id
  -- Using an epsilon for float comparison to handle potential inaccuracies
  WHERE ABS(q.total_amount - qdt.calculated_total) > 0.01
)
SELECT
  IF(
    (SELECT COUNT(*) FROM MismatchedTotals) = 0,
    'PASS',
    'FAIL'
  ) AS result,
  'financial_integrity_total_amount' AS test_name;