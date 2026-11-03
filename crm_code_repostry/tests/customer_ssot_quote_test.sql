/*
Unit Tests for: quote
Description: Tests the data integrity of the curated quote table.
*/

-- Placeholder for the GCP project and dataset variables.
-- Replace 'your-gcp-project-id' and 'Curated' with your actual project and dataset.
DECLARE gcp_project_id STRING DEFAULT 'your-gcp-project-id';
DECLARE curated_dataset STRING DEFAULT 'Curated';

-- test: not_null_quote_id
-- The primary key 'quote_id' must not contain null values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_id' AS test_name
FROM
  `your-gcp-project-id.Curated.quote`
WHERE
  quote_id IS NULL;

-- test: unique_quote_id
-- The primary key 'quote_id' must be unique across all records.
SELECT
  IF(COUNT(quote_id) = COUNT(DISTINCT quote_id), 'PASS', 'FAIL') AS result,
  'unique_quote_id' AS test_name
FROM
  `your-gcp-project-id.Curated.quote`;

-- test: referential_integrity_opportunity_id
-- Each 'opportunity_id' in the quote table must exist in the opportunity table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_opportunity_id' AS test_name
FROM
  `your-gcp-project-id.Curated.quote` AS q
LEFT JOIN
  `your-gcp-project-id.Curated.opportunity` AS o
  ON q.opportunity_id = o.opportunity_id
WHERE
  q.opportunity_id IS NOT NULL AND o.opportunity_id IS NULL;

-- test: domain_status
-- The 'status' field should fall within an expected set of values for a quote lifecycle.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'domain_status' AS test_name
FROM
  `your-gcp-project-id.Curated.quote`
WHERE
  status NOT IN ('Draft', 'Presented', 'Accepted', 'Expired', 'Canceled') AND status IS NOT NULL;

-- test: positive_total_amount
-- The 'total_amount' of a quote should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'positive_total_amount' AS test_name
FROM
  `your-gcp-project-id.Curated.quote`
WHERE
  total_amount IS NOT NULL AND total_amount < 0;

-- test: valid_date_range
-- The 'valid_to' date must be on or after the 'valid_from' date.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'valid_date_range' AS test_name
FROM
  `your-gcp-project-id.Curated.quote`
WHERE
  valid_to < valid_from;