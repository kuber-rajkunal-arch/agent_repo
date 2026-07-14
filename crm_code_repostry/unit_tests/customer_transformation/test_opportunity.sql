-- ===================================================================================
--
-- Unit Tests for Curated.opportunity
--
-- ===================================================================================

-- test: not_null_opportunity_id
-- The primary key `opportunity_id` must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_opportunity_id' AS test_name
FROM
  `Curated.opportunity`
WHERE
  opportunity_id IS NULL;

-- test: unique_opportunity_id
-- The primary key `opportunity_id` must be unique.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_opportunity_id' AS test_name
FROM (
  SELECT
    opportunity_id
  FROM
    `Curated.opportunity`
  WHERE
    opportunity_id IS NOT NULL
  GROUP BY
    opportunity_id
  HAVING
    COUNT(*) > 1
);

-- test: not_null_created_on
-- The `created_on` timestamp is a critical field and should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_created_on' AS test_name
FROM
  `Curated.opportunity`
WHERE
  created_on IS NULL;

-- test: referential_integrity_customer_id
-- If `customer_id` is present, it must exist in the `Curated.customer` table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customer_id' AS test_name
FROM (
  SELECT
    O.customer_id
  FROM
    `Curated.opportunity` AS O
    LEFT JOIN `Curated.customer` AS C ON O.customer_id = C.customer_id
  WHERE
    O.customer_id IS NOT NULL
    AND C.customer_id IS NULL
);

-- test: referential_integrity_originating_lead_id
-- If `originating_lead_id` is present, it must exist in the `Curated.lead` table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_originating_lead_id' AS test_name
FROM (
  SELECT
    O.originating_lead_id
  FROM
    `Curated.opportunity` AS O
    LEFT JOIN `Curated.lead` AS L ON O.originating_lead_id = L.lead_id
  WHERE
    O.originating_lead_id IS NOT NULL
    AND L.lead_id IS NULL
);

-- test: domain_status
-- The `status` field should only contain expected values ('Open', 'Won', 'Lost').
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'domain_status' AS test_name
FROM
  `Curated.opportunity`
WHERE
  status IS NOT NULL
  AND status NOT IN ('Open', 'Won', 'Lost');

-- test: range_probability
-- The `probability` field must be between 0 and 1, inclusive.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_probability' AS test_name
FROM
  `Curated.opportunity`
WHERE
  probability IS NOT NULL
  AND (probability < 0 OR probability > 1);

-- test: range_estimated_value
-- The `estimated_value` should be non-negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_estimated_value' AS test_name
FROM
  `Curated.opportunity`
WHERE
  estimated_value IS NOT NULL
  AND estimated_value < 0;

-- test: conditional_close_date_not_null
-- If an opportunity is 'Won' or 'Lost', the `close_date` must be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'conditional_close_date_not_null' AS test_name
FROM
  `Curated.opportunity`
WHERE
  status IN ('Won', 'Lost')
  AND close_date IS NULL;