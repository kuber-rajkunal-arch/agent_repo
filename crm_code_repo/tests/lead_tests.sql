/*
--------------------------------------------------------------------------------
--
-- Test File: lead_tests.sql
--
-- Purpose: Unit tests for the `lead` table.
--
-- Author: Senior Software/Quality Engineer
--
--------------------------------------------------------------------------------
*/

-- =============================================================================
-- Tests for the `lead` table
-- =============================================================================

-- test: lead_not_null_lead_id
-- The primary key `lead_id` must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'lead_not_null_lead_id' AS test_name
FROM `your_project_id.your_curated_dataset.lead`
WHERE lead_id IS NULL;

-- test: lead_unique_lead_id
-- The primary key `lead_id` must be unique.
SELECT
  IF(
    (SELECT COUNT(lead_id) FROM `your_project_id.your_curated_dataset.lead`) =
    (SELECT COUNT(DISTINCT lead_id) FROM `your_project_id.your_curated_dataset.lead`),
    'PASS', 'FAIL'
  ) AS result,
  'lead_unique_lead_id' AS test_name;

-- test: lead_not_null_status
-- The `status` field should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'lead_not_null_status' AS test_name
FROM `your_project_id.your_curated_dataset.lead`
WHERE status IS NULL;

-- test: lead_not_null_created_on
-- The `created_on` timestamp should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'lead_not_null_created_on' AS test_name
FROM `your_project_id.your_curated_dataset.lead`
WHERE created_on IS NULL;

-- test: lead_fk_customer_id
-- The `customer_id` must exist in the `customer` table if it is not null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'lead_fk_customer_id' AS test_name
FROM `your_project_id.your_curated_dataset.lead` AS l
LEFT JOIN `your_project_id.your_curated_dataset.customer` AS c
  ON l.customer_id = c.customer_id
WHERE
  l.customer_id IS NOT NULL
  AND c.customer_id IS NULL;

-- test: lead_valid_timestamps
-- The `qualified_on` timestamp, if present, must be on or after `created_on`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'lead_valid_timestamps' AS test_name
FROM `your_project_id.your_curated_dataset.lead`
WHERE qualified_on IS NOT NULL AND qualified_on < created_on;

-- test: lead_accepted_values_lead_source
-- The `lead_source` field should only contain expected values.
-- Note: This list is an example. Update with all valid lead sources.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'lead_accepted_values_lead_source' AS test_name
FROM `your_project_id.your_curated_dataset.lead`
WHERE
  lead_source NOT IN ('Web', 'Referral', 'Partner', 'Trade Show', 'Direct')
  AND lead_source IS NOT NULL;

-- test: lead_accepted_values_status
-- The `status` field should only contain expected values.
-- Note: This list is an example. Update with all valid lead statuses.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'lead_accepted_values_status' AS test_name
FROM `your_project_id.your_curated_dataset.lead`
WHERE
  status NOT IN ('New', 'Contacted', 'Qualified', 'Unqualified', 'Nurture')
  AND status IS NOT NULL;