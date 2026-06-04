/*
--------------------------------------------------------------------------------
--
-- Test File: quote_tests.sql
--
-- Purpose: Unit tests for the `quote` table.
--
-- Author: Senior Software/Quality Engineer
--
--------------------------------------------------------------------------------
*/

-- =============================================================================
-- Tests for the `quote` table
-- =============================================================================

-- test: quote_not_null_quote_id
-- The primary key `quote_id` must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_not_null_quote_id' AS test_name
FROM `your_project_id.your_curated_dataset.quote`
WHERE quote_id IS NULL;

-- test: quote_unique_quote_id
-- The primary key `quote_id` must be unique.
SELECT
  IF(
    (SELECT COUNT(quote_id) FROM `your_project_id.your_curated_dataset.quote`) =
    (SELECT COUNT(DISTINCT quote_id) FROM `your_project_id.your_curated_dataset.quote`),
    'PASS', 'FAIL'
  ) AS result,
  'quote_unique_quote_id' AS test_name;

-- test: quote_unique_quote_number
-- The natural key `quote_number` should be unique among non-null values.
SELECT
  IF(
    (SELECT COUNT(quote_number) FROM `your_project_id.your_curated_dataset.quote` WHERE quote_number IS NOT NULL) =
    (SELECT COUNT(DISTINCT quote_number) FROM `your_project_id.your_curated_dataset.quote` WHERE quote_number IS NOT NULL),
    'PASS', 'FAIL'
  ) AS result,
  'quote_unique_quote_number' AS test_name;

-- test: quote_fk_opportunity_id
-- The `opportunity_id` must exist in the `opportunity` table if it is not null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_fk_opportunity_id' AS test_name
FROM `your_project_id.your_curated_dataset.quote` AS q
LEFT JOIN `your_project_id.your_curated_dataset.opportunity` AS o
  ON q.opportunity_id = o.opportunity_id
WHERE
  q.opportunity_id IS NOT NULL
  AND o.opportunity_id IS NULL;

-- test: quote_fk_customer_id
-- The `customer_id` must exist in the `customer` table if it is not null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_fk_customer_id' AS test_name
FROM `your_project_id.your_curated_dataset.quote` AS q
LEFT JOIN `your_project_id.your_curated_dataset.customer` AS c
  ON q.customer_id = c.customer_id
WHERE
  q.customer_id IS NOT NULL
  AND c.customer_id IS NULL;

-- test: quote_valid_dates
-- The `valid_to` date must be on or after the `valid_from` date.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_valid_dates' AS test_name
FROM `your_project_id.your_curated_dataset.quote`
WHERE
  valid_to IS NOT NULL
  AND valid_from IS NOT NULL
  AND valid_to < valid_from;

-- test: quote_valid_total_amount
-- The `total_amount` must not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_valid_total_amount' AS test_name
FROM `your_project_id.your_curated_dataset.quote`
WHERE
  total_amount IS NOT NULL
  AND total_amount < 0;

-- test: quote_accepted_values_status
-- The `status` field should only contain expected values.
-- Note: This list is an example. Update with all valid quote statuses.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_accepted_values_status' AS test_name
FROM `your_project_id.your_curated_dataset.quote`
WHERE
  status NOT IN ('Draft', 'Active', 'Won', 'Lost', 'Expired')
  AND status IS NOT NULL;