-- =============================================================================
-- Unit Tests for curated.opportunity
--
-- These tests validate the data integrity of the `opportunity` table after
-- the MERGE operation.
-- =============================================================================

-- test: not_null_opportunity_id
-- The opportunity_id is the primary key and should never be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_opportunity_id' AS test_name
FROM `your_project_id.your_curated_dataset.opportunity`
WHERE opportunity_id IS NULL;

-- test: unique_opportunity_id
-- The opportunity_id must be unique to serve as a primary key.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_opportunity_id' AS test_name
FROM (
  SELECT
    opportunity_id
  FROM `your_project_id.your_curated_dataset.opportunity`
  WHERE opportunity_id IS NOT NULL
  GROUP BY
    opportunity_id
  HAVING
    COUNT(*) > 1
);

-- test: not_null_customer_id
-- Every opportunity must be associated with a customer.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_customer_id' AS test_name
FROM `your_project_id.your_curated_dataset.opportunity`
WHERE customer_id IS NULL;

-- test: referential_integrity_customer_id
-- The customer_id in the opportunity table must exist in the customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customer_id' AS test_name
FROM `your_project_id.your_curated_dataset.opportunity` AS o
LEFT JOIN `your_project_id.your_curated_dataset.customer` AS c
  ON o.customer_id = c.customer_id
WHERE
  o.customer_id IS NOT NULL
  AND c.customer_id IS NULL;

-- test: referential_integrity_originating_lead_id
-- If an opportunity originated from a lead, that lead_id must exist in the lead table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_originating_lead_id' AS test_name
FROM `your_project_id.your_curated_dataset.opportunity` AS o
LEFT JOIN `your_project_id.your_curated_dataset.lead` AS l
  ON o.originating_lead_id = l.lead_id
WHERE
  o.originating_lead_id IS NOT NULL
  AND l.lead_id IS NULL;

-- test: range_check_probability
-- Probability must be between 0 and 1, inclusive.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_probability' AS test_name
FROM `your_project_id.your_curated_dataset.opportunity`
WHERE probability IS NOT NULL AND (probability < 0 OR probability > 1);

-- test: non_negative_estimated_value
-- The estimated value of an opportunity cannot be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'non_negative_estimated_value' AS test_name
FROM `your_project_id.your_curated_dataset.opportunity`
WHERE estimated_value < 0;

-- test: close_date_after_created_on
-- The close_date cannot be before the created_on date.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'close_date_after_created_on' AS test_name
FROM `your_project_id.your_curated_dataset.opportunity`
WHERE close_date < created_on;