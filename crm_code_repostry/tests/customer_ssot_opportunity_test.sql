/*
Unit Tests for: opportunity
Description: Tests the data integrity of the curated opportunity table.
*/

-- Placeholder for the GCP project and dataset variables.
-- Replace 'your-gcp-project-id' and 'Curated' with your actual project and dataset.
DECLARE gcp_project_id STRING DEFAULT 'your-gcp-project-id';
DECLARE curated_dataset STRING DEFAULT 'Curated';

-- test: not_null_opportunity_id
-- The primary key 'opportunity_id' must not contain null values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_opportunity_id' AS test_name
FROM
  `your-gcp-project-id.Curated.opportunity`
WHERE
  opportunity_id IS NULL;

-- test: unique_opportunity_id
-- The primary key 'opportunity_id' must be unique across all records.
SELECT
  IF(
    COUNT(opportunity_id) = COUNT(DISTINCT opportunity_id),
    'PASS',
    'FAIL'
  ) AS result,
  'unique_opportunity_id' AS test_name
FROM
  `your-gcp-project-id.Curated.opportunity`;

-- test: referential_integrity_customer_id
-- Each 'customer_id' in the opportunity table must exist in the customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customer_id' AS test_name
FROM
  `your-gcp-project-id.Curated.opportunity` AS o
LEFT JOIN
  `your-gcp-project-id.Curated.customer` AS c
  ON o.customer_id = c.customer_id
WHERE
  o.customer_id IS NOT NULL AND c.customer_id IS NULL;

-- test: referential_integrity_originating_lead_id
-- Each 'originating_lead_id' must exist in the lead table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_originating_lead_id' AS test_name
FROM
  `your-gcp-project-id.Curated.opportunity` AS o
LEFT JOIN
  `your-gcp-project-id.Curated.lead` AS l
  ON o.originating_lead_id = l.lead_id
WHERE
  o.originating_lead_id IS NOT NULL AND l.lead_id IS NULL;

-- test: range_probability
-- The 'probability' field should be a value between 0 and 1, inclusive.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_probability' AS test_name
FROM
  `your-gcp-project-id.Curated.opportunity`
WHERE
  probability IS NOT NULL AND (probability < 0 OR probability > 1);

-- test: positive_estimated_value
-- The 'estimated_value' of an opportunity should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'positive_estimated_value' AS test_name
FROM
  `your-gcp-project-id.Curated.opportunity`
WHERE
  estimated_value IS NOT NULL AND estimated_value < 0;

-- test: conditional_close_date_for_closed_stages
-- If an opportunity is in a 'Closed' stage, its 'close_date' must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'conditional_close_date_for_closed_stages' AS test_name
FROM
  `your-gcp-project-id.Curated.opportunity`
WHERE
  stage IN ('Closed Won', 'Closed Lost') AND close_date IS NULL;