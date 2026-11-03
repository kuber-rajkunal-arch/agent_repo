/*
Unit Tests for: lead
Description: Tests the data integrity of the curated lead table.
*/

-- Placeholder for the GCP project and dataset variables.
-- Replace 'your-gcp-project-id' and 'Curated' with your actual project and dataset.
DECLARE gcp_project_id STRING DEFAULT 'your-gcp-project-id';
DECLARE curated_dataset STRING DEFAULT 'Curated';

-- test: not_null_lead_id
-- The primary key 'lead_id' must not contain null values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_lead_id' AS test_name
FROM
  `your-gcp-project-id.Curated.lead`
WHERE
  lead_id IS NULL;

-- test: unique_lead_id
-- The primary key 'lead_id' must be unique across all records.
SELECT
  IF(COUNT(lead_id) = COUNT(DISTINCT lead_id), 'PASS', 'FAIL') AS result,
  'unique_lead_id' AS test_name
FROM
  `your-gcp-project-id.Curated.lead`;

-- test: referential_integrity_customer_id
-- Each 'customer_id' in the lead table must exist in the customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customer_id' AS test_name
FROM
  `your-gcp-project-id.Curated.lead` AS l
LEFT JOIN
  `your-gcp-project-id.Curated.customer` AS c
  ON l.customer_id = c.customer_id
WHERE
  l.customer_id IS NOT NULL AND c.customer_id IS NULL;

-- test: domain_status
-- The 'status' field should fall within an expected set of values for a lead lifecycle.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'domain_status' AS test_name
FROM
  `your-gcp-project-id.Curated.lead`
WHERE
  status NOT IN ('New', 'Contacted', 'Qualified', 'Unqualified', 'Nurturing') AND status IS NOT NULL;

-- test: conditional_qualified_on_not_null
-- If a lead's status is 'Qualified', the 'qualified_on' date must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'conditional_qualified_on_not_null' AS test_name
FROM
  `your-gcp-project-id.Curated.lead`
WHERE
  status = 'Qualified' AND qualified_on IS NULL;

-- test: conditional_customer_id_not_null_on_qualified
-- A qualified lead should be associated with a customer record.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'conditional_customer_id_not_null_on_qualified' AS test_name
FROM
  `your-gcp-project-id.Curated.lead`
WHERE
  status = 'Qualified' AND customer_id IS NULL;