-- =================================================================================================
-- Unit Tests for crm_code_files/customer_ssot.sql - quote table
--
-- Description: These tests validate the data integrity of the `quote` table after the
--              incremental load.
-- =================================================================================================

-- test: not_null_quote_id
-- A quote must always have a primary key.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_id' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.quote`
WHERE quote_id IS NULL;

-- test: unique_quote_id
-- The quote_id must be unique to serve as a primary key.
SELECT
  IF(COUNT(quote_id) = COUNT(DISTINCT quote_id), 'PASS', 'FAIL') AS result,
  'unique_quote_id' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.quote`;

-- test: fk_quote_opportunity_id_exists
-- Every quote must be linked to a valid, existing opportunity.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'fk_quote_opportunity_id_exists' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.quote` AS q
LEFT JOIN `{{ project_id }}.{{ curated_dataset }}.opportunity` AS o
  ON q.opportunity_id = o.opportunity_id
WHERE q.opportunity_id IS NOT NULL AND o.opportunity_id IS NULL;

-- test: fk_quote_customer_id_exists
-- Every quote must be linked to a valid, existing customer.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'fk_quote_customer_id_exists' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.quote` AS q
LEFT JOIN `{{ project_id }}.{{ curated_dataset }}.customer` AS c
  ON q.customer_id = c.customer_id
WHERE q.customer_id IS NOT NULL AND c.customer_id IS NULL;

-- test: chronological_valid_dates
-- A quote's 'valid_to' date cannot be before its 'valid_from' date.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'chronological_valid_dates' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.quote`
WHERE valid_to < valid_from;

-- test: positive_total_amount
-- The total amount of a quote should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'positive_total_amount' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.quote`
WHERE total_amount < 0;