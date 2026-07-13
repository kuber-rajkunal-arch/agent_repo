--
-- Unit tests for the curated quote table.
-- These tests validate the data integrity of the `<project_id>.<curated_dataset>.quote` table
-- after the MERGE operation from `crm_code/customer_ssot.sql` is executed.
--

-- test: not_null_quote_id
-- The primary key `quote_id` must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_id' AS test_name
FROM
  `<project_id>.<curated_dataset>.quote`
WHERE
  quote_id IS NULL;

-- test: unique_quote_id
-- The primary key `quote_id` must be unique across all records.
SELECT
  IF(COUNT(quote_id) = COUNT(DISTINCT quote_id), 'PASS', 'FAIL') AS result,
  'unique_quote_id' AS test_name
FROM
  `<project_id>.<curated_dataset>.quote`;

-- test: referential_integrity_customer_id
-- The `customer_id` must exist in the `customer` table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customer_id' AS test_name
FROM (
  SELECT DISTINCT customer_id
  FROM `<project_id>.<curated_dataset>.quote`
) AS q
LEFT JOIN `<project_id>.<curated_dataset>.customer` AS c
  ON q.customer_id = c.customer_id
WHERE
  c.customer_id IS NULL;

-- test: referential_integrity_opportunity_id
-- The `opportunity_id` must exist in the `opportunity` table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_opportunity_id' AS test_name
FROM (
  SELECT DISTINCT opportunity_id
  FROM `<project_id>.<curated_dataset>.quote`
) AS q
LEFT JOIN `<project_id>.<curated_dataset>.opportunity` AS o
  ON q.opportunity_id = o.opportunity_id
WHERE
  o.opportunity_id IS NULL;

-- test: financial_integrity_total_amount
-- The `total_amount` on the quote header must equal the sum of `total_amount` from its detail lines.
-- This validates the critical financial integrity check from the source query.
WITH
  quote_detail_agg AS (
    SELECT
      quote_id,
      SUM(total_amount) AS calculated_total_amount
    FROM
      `<project_id>.<curated_dataset>.quote_detail`
    GROUP BY
      quote_id
  )
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'financial_integrity_total_amount' AS test_name
FROM
  `<project_id>.<curated_dataset>.quote` AS hdr
  LEFT JOIN quote_detail_agg AS dtl ON hdr.quote_id = dtl.quote_id
WHERE
  -- Use a small tolerance for floating point comparisons.
  ABS(hdr.total_amount - COALESCE(dtl.calculated_total_amount, 0)) > 0.01;

-- test: valid_date_range
-- The `valid_to` date must be on or after the `valid_from` date.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'valid_date_range' AS test_name
FROM
  `<project_id>.<curated_dataset>.quote`
WHERE
  valid_to < valid_from;