/*
--------------------------------------------------------------------------------
--
-- Test File: opportunity_tests.sql
--
-- Purpose: Unit tests for the `opportunity` table.
--
-- Author: Senior Software/Quality Engineer
--
--------------------------------------------------------------------------------
*/

-- =============================================================================
-- Tests for the `opportunity` table
-- =============================================================================

-- test: opportunity_not_null_opportunity_id
-- The primary key `opportunity_id` must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_not_null_opportunity_id' AS test_name
FROM `your_project_id.your_curated_dataset.opportunity`
WHERE opportunity_id IS NULL;

-- test: opportunity_unique_opportunity_id
-- The primary key `opportunity_id` must be unique.
SELECT
  IF(
    (SELECT COUNT(opportunity_id) FROM `your_project_id.your_curated_dataset.opportunity`) =
    (SELECT COUNT(DISTINCT opportunity_id) FROM `your_project_id.your_curated_dataset.opportunity`),
    'PASS', 'FAIL'
  ) AS result,
  'opportunity_unique_opportunity_id' AS test_name;

-- test: opportunity_not_null_status
-- The `status` field should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_not_null_status' AS test_name
FROM `your_project_id.your_curated_dataset.opportunity`
WHERE status IS NULL;

-- test: opportunity_fk_customer_id
-- The `customer_id` must exist in the `customer` table if it is not null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_fk_customer_id' AS test_name
FROM `your_project_id.your_curated_dataset.opportunity` AS o
LEFT JOIN `your_project_id.your_curated_dataset.customer` AS c
  ON o.customer_id = c.customer_id
WHERE
  o.customer_id IS NOT NULL
  AND c.customer_id IS NULL;

-- test: opportunity_fk_originating_lead_id
-- The `originating_lead_id` must exist in the `lead` table if it is not null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_fk_originating_lead_id' AS test_name
FROM `your_project_id.your_curated_dataset.opportunity` AS o
LEFT JOIN `your_project_id.your_curated_dataset.lead` AS l
  ON o.originating_lead_id = l.lead_id
WHERE
  o.originating_lead_id IS NOT NULL
  AND l.lead_id IS NULL;

-- test: opportunity_valid_probability
-- The `probability` field must be between 0 and 1.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_valid_probability' AS test_name
FROM `your_project_id.your_curated_dataset.opportunity`
WHERE
  probability IS NOT NULL
  AND (probability < 0 OR probability > 1);

-- test: opportunity_valid_estimated_value
-- The `estimated_value` must not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_valid_estimated_value' AS test_name
FROM `your_project_id.your_curated_dataset.opportunity`
WHERE
  estimated_value IS NOT NULL
  AND estimated_value < 0;

-- test: opportunity_accepted_values_status
-- The `status` field should only contain expected values.
-- Note: This list is an example. Update with all valid opportunity statuses.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_accepted_values_status' AS test_name
FROM `your_project_id.your_curated_dataset.opportunity`
WHERE
  status NOT IN ('Open', 'Won', 'Lost')
  AND status IS NOT NULL;