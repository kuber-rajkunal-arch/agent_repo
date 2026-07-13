--
-- Unit tests for the curated opportunity table.
-- These tests validate the data integrity of the `<project_id>.<curated_dataset>.opportunity` table
-- after the MERGE operation from `crm_code/customer_ssot.sql` is executed.
--

-- test: not_null_opportunity_id
-- The primary key `opportunity_id` must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_opportunity_id' AS test_name
FROM
  `<project_id>.<curated_dataset>.opportunity`
WHERE
  opportunity_id IS NULL;

-- test: unique_opportunity_id
-- The primary key `opportunity_id` must be unique across all records.
SELECT
  IF(COUNT(opportunity_id) = COUNT(DISTINCT opportunity_id), 'PASS', 'FAIL') AS result,
  'unique_opportunity_id' AS test_name
FROM
  `<project_id>.<curated_dataset>.opportunity`;

-- test: not_null_customer_id
-- The foreign key `customer_id` must not be null, as an opportunity must be linked to a customer.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_customer_id' AS test_name
FROM
  `<project_id>.<curated_dataset>.opportunity`
WHERE
  customer_id IS NULL;

-- test: referential_integrity_customer_id
-- The `customer_id` must exist in the `customer` table.
-- This confirms the `EXISTS` check in the source query is effective.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customer_id' AS test_name
FROM (
  SELECT DISTINCT customer_id
  FROM `<project_id>.<curated_dataset>.opportunity`
) AS o
LEFT JOIN `<project_id>.<curated_dataset>.customer` AS c
  ON o.customer_id = c.customer_id
WHERE
  c.customer_id IS NULL;

-- test: referential_integrity_originating_lead_id
-- If `originating_lead_id` is populated, it must exist in the `lead` table.
-- This confirms the `EXISTS` check in the source query is effective.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_originating_lead_id' AS test_name
FROM
  `<project_id>.<curated_dataset>.opportunity` AS o
WHERE
  o.originating_lead_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1
    FROM `<project_id>.<curated_dataset>.lead` AS l
    WHERE l.lead_id = o.originating_lead_id
  );

-- test: valid_probability_range
-- The `probability` field should be between 0 and 1, inclusive.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'valid_probability_range' AS test_name
FROM
  `<project_id>.<curated_dataset>.opportunity`
WHERE
  NOT (probability >= 0 AND probability <= 1);

-- test: chronological_close_date
-- The `close_date` must be on or after the `created_on` date.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'chronological_close_date' AS test_name
FROM
  `<project_id>.<curated_dataset>.opportunity`
WHERE
  close_date < DATE(created_on);