-- Unit tests for the curated 'lead' table.
-- These tests verify primary key and foreign key integrity after the sp_load_lead procedure runs.

-- test: not_null_lead_id
-- The primary key `lead_id` must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_lead_id' AS test_name,
  'All lead_id records must be not-null.' AS description
FROM `your-gcp-project-id.Curated.lead`
WHERE lead_id IS NULL;

-- test: unique_lead_id
-- The primary key `lead_id` must be unique across all records.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_lead_id' AS test_name,
  'All lead_id records must be unique.' AS description
FROM (
  SELECT
    lead_id
  FROM `your-gcp-project-id.Curated.lead`
  WHERE lead_id IS NOT NULL
  GROUP BY lead_id
  HAVING COUNT(*) > 1
);

-- test: referential_lead_customer_id
-- Any non-null `customer_id` in the `lead` table must exist in the `customer` table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_lead_customer_id' AS test_name,
  'All non-null lead.customer_id must exist in customer.customer_id.' AS description
FROM (
  SELECT
    l.customer_id
  FROM `your-gcp-project-id.Curated.lead` AS l
  LEFT JOIN `your-gcp-project-id.Curated.customer` AS c
    ON l.customer_id = c.customer_id
  WHERE
    l.customer_id IS NOT NULL
    AND c.customer_id IS NULL
);