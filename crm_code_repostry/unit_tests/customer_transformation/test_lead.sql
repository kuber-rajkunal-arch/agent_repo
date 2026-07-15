-- ===================================================================================
--
-- Unit Tests for Curated.lead
--
-- ===================================================================================

-- test: not_null_lead_id
-- The primary key `lead_id` must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_lead_id' AS test_name,
  'The primary key `lead_id` must not be null.' AS description
FROM
  `Curated.lead`
WHERE
  lead_id IS NULL;

-- test: unique_lead_id
-- The primary key `lead_id` must be unique.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_lead_id' AS test_name,
  'The primary key `lead_id` must be unique.' AS description
FROM (
  SELECT
    lead_id
  FROM
    `Curated.lead`
  WHERE
    lead_id IS NOT NULL
  GROUP BY
    lead_id
  HAVING
    COUNT(*) > 1
);

-- test: not_null_created_on
-- The `created_on` timestamp is a critical field and should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_created_on' AS test_name,
  'The `created_on` timestamp should always be populated.' AS description
FROM
  `Curated.lead`
WHERE
  created_on IS NULL;

-- test: referential_integrity_customer_id
-- If `customer_id` is present, it must exist in the `Curated.customer` table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customer_id' AS test_name,
  'If `customer_id` is present, it must exist in `Curated.customer`.' AS description
FROM (
  SELECT
    L.customer_id
  FROM
    `Curated.lead` AS L
    LEFT JOIN `Curated.customer` AS C ON L.customer_id = C.customer_id
  WHERE
    L.customer_id IS NOT NULL
    AND C.customer_id IS NULL
);

-- test: domain_status
-- The `status` field should only contain expected values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'domain_status' AS test_name,
  'The `status` field should only contain expected values.' AS description
FROM
  `Curated.lead`
WHERE
  status IS NOT NULL
  AND status NOT IN ('New', 'Contacted', 'Qualified', 'Unqualified', 'Lost');

-- test: conditional_qualified_on_not_null
-- If a lead's status is 'Qualified', the `qualified_on` timestamp must be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'conditional_qualified_on_not_null' AS test_name,
  'If status is `Qualified`, `qualified_on` must be populated.' AS description
FROM
  `Curated.lead`
WHERE
  status = 'Qualified'
  AND qualified_on IS NULL;

-- test: consistency_qualified_on_vs_created_on
-- The `qualified_on` timestamp, if present, should not be earlier than the `created_on` timestamp.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'consistency_qualified_on_vs_created_on' AS test_name,
  'The `qualified_on` timestamp should not be earlier than `created_on`.' AS description
FROM
  `Curated.lead`
WHERE
  qualified_on IS NOT NULL
  AND qualified_on < created_on;