-- =================================================================================================
-- Unit Tests for crm_code_files/customer_ssot.sql - opportunity table
--
-- Description: These tests validate the data integrity of the `opportunity` table after the
--              incremental load.
-- =================================================================================================

-- test: not_null_opportunity_id
-- An opportunity must always have a primary key.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_opportunity_id' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.opportunity`
WHERE opportunity_id IS NULL;

-- test: unique_opportunity_id
-- The opportunity_id must be unique to serve as a primary key.
SELECT
  IF(COUNT(opportunity_id) = COUNT(DISTINCT opportunity_id), 'PASS', 'FAIL') AS result,
  'unique_opportunity_id' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.opportunity`;

-- test: not_null_stage_and_status
-- Stage and status are critical fields for sales pipeline tracking.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_stage_and_status' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.opportunity`
WHERE stage IS NULL OR status IS NULL;

-- test: fk_opportunity_customer_id_exists
-- Every opportunity must be linked to a valid, existing customer.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'fk_opportunity_customer_id_exists' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.opportunity` AS o
LEFT JOIN `{{ project_id }}.{{ curated_dataset }}.customer` AS c
  ON o.customer_id = c.customer_id
WHERE o.customer_id IS NOT NULL AND c.customer_id IS NULL;

-- test: fk_opportunity_originating_lead_id_exists
-- If an opportunity originated from a lead, that lead must exist.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'fk_opportunity_originating_lead_id_exists' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.opportunity` AS o
LEFT JOIN `{{ project_id }}.{{ curated_dataset }}.lead` AS l
  ON o.originating_lead_id = l.lead_id
WHERE o.originating_lead_id IS NOT NULL AND l.lead_id IS NULL;

-- test: range_probability
-- The probability of closing an opportunity must be between 0 and 1 (inclusive).
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_probability' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.opportunity`
WHERE probability < 0 OR probability > 1;

-- test: chronological_close_date
-- The estimated close date cannot be before the opportunity was created.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'chronological_close_date' AS test_name
FROM `{{ project_id }}.{{ curated_dataset }}.opportunity`
WHERE close_date < DATE(created_on);