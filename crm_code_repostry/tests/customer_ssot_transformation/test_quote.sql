-- Unit tests for the curated 'quote' table.
-- These tests verify primary key, foreign key, and financial integrity after the sp_load_quote procedure runs.

-- test: not_null_quote_id
-- The primary key `quote_id` must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_id' AS test_name,
  'All quote_id records must be not-null.' AS description
FROM `your-gcp-project-id.Curated.quote`
WHERE quote_id IS NULL;

-- test: unique_quote_id
-- The primary key `quote_id` must be unique across all records.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_quote_id' AS test_name,
  'All quote_id records must be unique.' AS description
FROM (
  SELECT
    quote_id
  FROM `your-gcp-project-id.Curated.quote`
  WHERE quote_id IS NOT NULL
  GROUP BY quote_id
  HAVING COUNT(*) > 1
);

-- test: referential_quote_customer_id
-- Any non-null `customer_id` in the `quote` table must exist in the `customer` table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_quote_customer_id' AS test_name,
  'All non-null quote.customer_id must exist in customer.customer_id.' AS description
FROM (
  SELECT
    q.customer_id
  FROM `your-gcp-project-id.Curated.quote` AS q
  LEFT JOIN `your-gcp-project-id.Curated.customer` AS c
    ON q.customer_id = c.customer_id
  WHERE
    q.customer_id IS NOT NULL
    AND c.customer_id IS NULL
);

-- test: referential_quote_opportunity_id
-- Any non-null `opportunity_id` in the `quote` table must exist in the `opportunity` table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_quote_opportunity_id' AS test_name,
  'All non-null quote.opportunity_id must exist in opportunity.opportunity_id.' AS description
FROM (
  SELECT
    q.opportunity_id
  FROM `your-gcp-project-id.Curated.quote` AS q
  LEFT JOIN `your-gcp-project-id.Curated.opportunity` AS o
    ON q.opportunity_id = o.opportunity_id
  WHERE
    q.opportunity_id IS NOT NULL
    AND o.opportunity_id IS NULL
);

-- test: financial_integrity_quote_total_amount
-- The `total_amount` on a quote header must equal the sum of `total_amount` from its corresponding quote detail lines.
-- This mirrors the financial integrity check in the sp_load_quote procedure.
WITH
  quote_detail_agg AS (
    SELECT
      quote_id,
      SUM(total_amount) AS calculated_total
    FROM `your-gcp-project-id.Curated.quote_detail`
    GROUP BY quote_id
  ),
  failed_quotes AS (
    SELECT
      q.quote_id,
      q.total_amount AS header_total,
      COALESCE(qda.calculated_total, 0) AS detail_sum_total
    FROM `your-gcp-project-id.Curated.quote` AS q
    LEFT JOIN quote_detail_agg AS qda
      ON q.quote_id = qda.quote_id
    -- The check allows for a small tolerance for floating point inaccuracies, matching the source procedure.
    WHERE ABS(q.total_amount - COALESCE(qda.calculated_total, 0)) > 0.01
  )
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'financial_integrity_quote_total_amount' AS test_name,
  'quote.total_amount must match the sum of its quote_detail.total_amount.' AS description
FROM failed_quotes;