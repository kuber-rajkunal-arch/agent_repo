-- Unit tests for the curated 'opportunity' table.
-- These tests verify primary key and foreign key integrity after the sp_load_opportunity procedure runs.

-- test: not_null_opportunity_id
-- The primary key `opportunity_id` must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_opportunity_id' AS test_name,
  'All opportunity_id records must be not-null.' AS description
FROM `your-gcp-project-id.Curated.opportunity`
WHERE opportunity_id IS NULL;

-- test: unique_opportunity_id
-- The primary key `opportunity_id` must be unique across all records.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_opportunity_id' AS test_name,
  'All opportunity_id records must be unique.' AS description
FROM (
  SELECT
    opportunity_id
  FROM `your-gcp-project-id.Curated.opportunity`
  WHERE opportunity_id IS NOT NULL
  GROUP BY opportunity_id
  HAVING COUNT(*) > 1
);

-- test: referential_opportunity_customer_id
-- Any non-null `customer_id` in the `opportunity` table must exist in the `customer` table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_opportunity_customer_id' AS test_name,
  'All non-null opportunity.customer_id must exist in customer.customer_id.' AS description
FROM (
  SELECT
    o.customer_id
  FROM `your-gcp-project-id.Curated.opportunity` AS o
  LEFT JOIN `your-gcp-project-id.Curated.customer` AS c
    ON o.customer_id = c.customer_id
  WHERE
    o.customer_id IS NOT NULL
    AND c.customer_id IS NULL
);

-- test: referential_opportunity_originating_lead_id
-- Any non-null `originating_lead_id` in the `opportunity` table must exist in the `lead` table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_opportunity_originating_lead_id' AS test_name,
  'All non-null opportunity.originating_lead_id must exist in lead.lead_id.' AS description
FROM (
  SELECT
    o.originating_lead_id
  FROM `your-gcp-project-id.Curated.opportunity` AS o
  LEFT JOIN `your-gcp-project-id.Curated.lead` AS l
    ON o.originating_lead_id = l.lead_id
  WHERE
    o.originating_lead_id IS NOT NULL
    AND l.lead_id IS NULL
);