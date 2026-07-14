-- =============================================================================
-- Unit Tests for curated.quote
--
-- These tests validate the data integrity of the `quote` table after the
-- MERGE operation.
-- =============================================================================

-- test: not_null_quote_id
-- The quote_id is the primary key and should never be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_id' AS test_name
FROM `your_project_id.your_curated_dataset.quote`
WHERE quote_id IS NULL;

-- test: unique_quote_id
-- The quote_id must be unique to serve as a primary key.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_quote_id' AS test_name
FROM (
  SELECT
    quote_id
  FROM `your_project_id.your_curated_dataset.quote`
  WHERE quote_id IS NOT NULL
  GROUP BY
    quote_id
  HAVING
    COUNT(*) > 1
);

-- test: not_null_customer_id
-- Every quote must be associated with a customer.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_customer_id' AS test_name
FROM `your_project_id.your_curated_dataset.quote`
WHERE customer_id IS NULL;

-- test: referential_integrity_customer_id
-- The customer_id in the quote table must exist in the customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customer_id' AS test_name
FROM `your_project_id.your_curated_dataset.quote` AS q
LEFT JOIN `your_project_id.your_curated_dataset.customer` AS c
  ON q.customer_id = c.customer_id
WHERE
  q.customer_id IS NOT NULL
  AND c.customer_id IS NULL;

-- test: referential_integrity_opportunity_id
-- The opportunity_id in the quote table must exist in the opportunity table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_opportunity_id' AS test_name
FROM `your_project_id.your_curated_dataset.quote` AS q
LEFT JOIN `your_project_id.your_curated_dataset.opportunity` AS o
  ON q.opportunity_id = o.opportunity_id
WHERE
  q.opportunity_id IS NOT NULL
  AND o.opportunity_id IS NULL;

-- test: non_negative_total_amount
-- The total amount of a quote cannot be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'non_negative_total_amount' AS test_name
FROM `your_project_id.your_curated_dataset.quote`
WHERE total_amount < 0;

-- test: valid_to_after_valid_from
-- The valid_to date for a quote cannot be before its valid_from date.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'valid_to_after_valid_from' AS test_name
FROM `your_project_id.your_curated_dataset.quote`
WHERE valid_to < valid_from;