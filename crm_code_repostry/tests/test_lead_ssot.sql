/*
  Unit tests for the Curated.lead table.
  These tests validate the data integrity of the lead single source of truth.
*/

-- test: unique_lead_id
-- Ensures that every lead has a unique identifier.
SELECT
  IF(COUNT(lead_id) = COUNT(DISTINCT lead_id), 'PASS', 'FAIL') AS result,
  'unique_lead_id' AS test_name
FROM
  `Curated.lead`;

-- test: not_null_lead_id
-- The primary key for the lead table must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_lead_id' AS test_name
FROM
  `Curated.lead`
WHERE
  lead_id IS NULL;

-- test: not_null_created_on
-- The created_on timestamp is used for watermarking and should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_created_on' AS test_name
FROM
  `Curated.lead`
WHERE
  created_on IS NULL;

-- test: not_null_status
-- The lead status is a critical field for tracking its lifecycle.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_status' AS test_name
FROM
  `Curated.lead`
WHERE
  status IS NULL;

-- test: not_null_owner_id
-- Every lead should be assigned to an owner.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_owner_id' AS test_name
FROM
  `Curated.lead`
WHERE
  owner_id IS NULL;

-- test: referential_integrity_customer_id
-- If a lead is associated with a customer, that customer must exist in the customer table.
-- customer_id can be NULL for unqualified leads.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customer_id' AS test_name
FROM
  `Curated.lead` AS l
LEFT JOIN
  `Curated.customer` AS c
  ON l.customer_id = c.customer_id
WHERE
  l.customer_id IS NOT NULL
  AND c.customer_id IS NULL;

-- test: chronological_order_qualified_on
-- A lead cannot be qualified before it was created.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'chronological_order_qualified_on' AS test_name
FROM
  `Curated.lead`
WHERE
  qualified_on IS NOT NULL
  AND qualified_on < created_on;