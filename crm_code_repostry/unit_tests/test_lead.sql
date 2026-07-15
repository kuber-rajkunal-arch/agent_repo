/*
  Unit tests for the 'curated.lead' table.
  These tests validate the data integrity of the final lead table
  after the transformation script has been executed.
*/

-- test: not_null_lead_id
-- The primary key 'lead_id' should never be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_lead_id' AS test_name
FROM `curated.lead`
WHERE lead_id IS NULL;

-- test: unique_lead_id
-- The primary key 'lead_id' must be unique across all records.
SELECT
  IF(COUNT(lead_id) = COUNT(DISTINCT lead_id), 'PASS', 'FAIL') AS result,
  'unique_lead_id' AS test_name
FROM `curated.lead`;

-- test: not_null_topic
-- The lead's topic is a critical field and should not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_topic' AS test_name
FROM `curated.lead`
WHERE topic IS NULL;

-- test: not_null_status
-- The lead's status should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_status' AS test_name
FROM `curated.lead`
WHERE status IS NULL;

-- test: not_null_created_on
-- The creation timestamp is essential for tracking and should not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_created_on' AS test_name
FROM `curated.lead`
WHERE created_on IS NULL;

-- test: domain_status
-- The 'status' field should conform to a predefined set of values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'domain_status' AS test_name
FROM `curated.lead`
WHERE status NOT IN ('New', 'Contacted', 'Qualified', 'Unqualified', 'Lost');

-- test: referential_customer_id
-- Any non-null 'customer_id' in the lead table must exist in the customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_customer_id' AS test_name
FROM `curated.lead` AS l
LEFT JOIN `curated.customer` AS c
  ON l.customer_id = c.customer_id
WHERE
  l.customer_id IS NOT NULL
  AND c.customer_id IS NULL;