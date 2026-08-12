/*
  Unit tests for the Customer SSOT curated tables.
  These tests validate the data integrity of the tables populated by the `customer_ssot.sql` script.
  Tables tested:
  - Curated.customer
  - Curated.lead
  - Curated.opportunity
  - Curated.quote
  - Curated.quote_detail
*/

-- =============================================================================
-- Tests for Curated.customer
-- =============================================================================

-- test: customer_unique_customer_id
-- The customer_id must be unique in the customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'customer_unique_customer_id' AS test_name
FROM (
  SELECT
    customer_id,
    COUNT(*) AS num_records
  FROM
    `Curated.customer`
  WHERE
    customer_id IS NOT NULL
  GROUP BY
    customer_id
  HAVING
    num_records > 1
);

-- test: customer_not_null_customer_id
-- The customer_id should never be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'customer_not_null_customer_id' AS test_name
FROM
  `Curated.customer`
WHERE
  customer_id IS NULL;

-- test: customer_not_null_name
-- The customer name should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'customer_not_null_name' AS test_name
FROM
  `Curated.customer`
WHERE
  name IS NULL;

-- test: customer_not_null_created_on
-- The created_on timestamp, used for watermarking, should never be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'customer_not_null_created_on' AS test_name
FROM
  `Curated.customer`
WHERE
  created_on IS NULL;

-- test: customer_not_null_is_active
-- The is_active flag should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'customer_not_null_is_active' AS test_name
FROM
  `Curated.customer`
WHERE
  is_active IS NULL;

-- =============================================================================
-- Tests for Curated.lead
-- =============================================================================

-- test: lead_unique_lead_id
-- The lead_id must be unique in the lead table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'lead_unique_lead_id' AS test_name
FROM (
  SELECT
    lead_id,
    COUNT(*) AS num_records
  FROM
    `Curated.lead`
  WHERE
    lead_id IS NOT NULL
  GROUP BY
    lead_id
  HAVING
    num_records > 1
);

-- test: lead_not_null_lead_id
-- The lead_id should never be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'lead_not_null_lead_id' AS test_name
FROM
  `Curated.lead`
WHERE
  lead_id IS NULL;

-- test: lead_not_null_status
-- The lead status should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'lead_not_null_status' AS test_name
FROM
  `Curated.lead`
WHERE
  status IS NULL;

-- test: lead_not_null_created_on
-- The created_on timestamp, used for watermarking, should never be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'lead_not_null_created_on' AS test_name
FROM
  `Curated.lead`
WHERE
  created_on IS NULL;

-- test: lead_referential_customer_id
-- Every non-null customer_id in the lead table must exist in the customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'lead_referential_customer_id' AS test_name
FROM
  `Curated.lead` AS l
LEFT JOIN
  `Curated.customer` AS c
  ON l.customer_id = c.customer_id
WHERE
  l.customer_id IS NOT NULL AND c.customer_id IS NULL;

-- =============================================================================
-- Tests for Curated.opportunity
-- =============================================================================

-- test: opportunity_unique_opportunity_id
-- The opportunity_id must be unique in the opportunity table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_unique_opportunity_id' AS test_name
FROM (
  SELECT
    opportunity_id,
    COUNT(*) AS num_records
  FROM
    `Curated.opportunity`
  WHERE
    opportunity_id IS NOT NULL
  GROUP BY
    opportunity_id
  HAVING
    num_records > 1
);

-- test: opportunity_not_null_opportunity_id
-- The opportunity_id should never be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_not_null_opportunity_id' AS test_name
FROM
  `Curated.opportunity`
WHERE
  opportunity_id IS NULL;

-- test: opportunity_not_null_customer_id
-- Every opportunity must be associated with a customer.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_not_null_customer_id' AS test_name
FROM
  `Curated.opportunity`
WHERE
  customer_id IS NULL;

-- test: opportunity_not_null_stage
-- The opportunity stage should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_not_null_stage' AS test_name
FROM
  `Curated.opportunity`
WHERE
  stage IS NULL;

-- test: opportunity_not_null_status
-- The opportunity status should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_not_null_status' AS test_name
FROM
  `Curated.opportunity`
WHERE
  status IS NULL;

-- test: opportunity_not_null_created_on
-- The created_on timestamp, used for watermarking, should never be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_not_null_created_on' AS test_name
FROM
  `Curated.opportunity`
WHERE
  created_on IS NULL;

-- test: opportunity_range_estimated_value
-- The estimated_value of an opportunity should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_range_estimated_value' AS test_name
FROM
  `Curated.opportunity`
WHERE
  estimated_value < 0;

-- test: opportunity_range_probability
-- The probability of an opportunity should be between 0 and 1.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_range_probability' AS test_name
FROM
  `Curated.opportunity`
WHERE
  probability < 0 OR probability > 1;

-- test: opportunity_referential_customer_id
-- Every customer_id in the opportunity table must exist in the customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_referential_customer_id' AS test_name
FROM
  `Curated.opportunity` AS o
LEFT JOIN
  `Curated.customer` AS c
  ON o.customer_id = c.customer_id
WHERE
  o.customer_id IS NOT NULL AND c.customer_id IS NULL;

-- test: opportunity_referential_originating_lead_id
-- Every non-null originating_lead_id in the opportunity table must exist in the lead table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_referential_originating_lead_id' AS test_name
FROM
  `Curated.opportunity` AS o
LEFT JOIN
  `Curated.lead` AS l
  ON o.originating_lead_id = l.lead_id
WHERE
  o.originating_lead_id IS NOT NULL AND l.lead_id IS NULL;

-- =============================================================================
-- Tests for Curated.quote
-- =============================================================================

-- test: quote_unique_quote_id
-- The quote_id must be unique in the quote table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_unique_quote_id' AS test_name
FROM (
  SELECT
    quote_id,
    COUNT(*) AS num_records
  FROM
    `Curated.quote`
  WHERE
    quote_id IS NOT NULL
  GROUP BY
    quote_id
  HAVING
    num_records > 1
);

-- test: quote_not_null_quote_id
-- The quote_id should never be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_not_null_quote_id' AS test_name
FROM
  `Curated.quote`
WHERE
  quote_id IS NULL;

-- test: quote_unique_quote_number
-- The quote_number must be unique in the quote table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_unique_quote_number' AS test_name
FROM (
  SELECT
    quote_number,
    COUNT(*) AS num_records
  FROM
    `Curated.quote`
  WHERE
    quote_number IS NOT NULL
  GROUP BY
    quote_number
  HAVING
    num_records > 1
);

-- test: quote_not_null_quote_number
-- The quote_number should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_not_null_quote_number' AS test_name
FROM
  `Curated.quote`
WHERE
  quote_number IS NULL;

-- test: quote_not_null_opportunity_id
-- Every quote must be associated with an opportunity.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_not_null_opportunity_id' AS test_name
FROM
  `Curated.quote`
WHERE
  opportunity_id IS NULL;

-- test: quote_not_null_customer_id
-- Every quote must be associated with a customer.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_not_null_customer_id' AS test_name
FROM
  `Curated.quote`
WHERE
  customer_id IS NULL;

-- test: quote_not_null_status
-- The quote status should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_not_null_status' AS test_name
FROM
  `Curated.quote`
WHERE
  status IS NULL;

-- test: quote_not_null_created_on
-- The created_on timestamp, used for watermarking, should never be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_not_null_created_on' AS test_name
FROM
  `Curated.quote`
WHERE
  created_on IS NULL;

-- test: quote_range_total_amount
-- The total_amount of a quote should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_range_total_amount' AS test_name
FROM
  `Curated.quote`
WHERE
  total_amount < 0;

-- test: quote_referential_opportunity_id
-- Every opportunity_id in the quote table must exist in the opportunity table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_referential_opportunity_id' AS test_name
FROM
  `Curated.quote` AS q
LEFT JOIN
  `Curated.opportunity` AS o
  ON q.opportunity_id = o.opportunity_id
WHERE
  q.opportunity_id IS NOT NULL AND o.opportunity_id IS NULL;

-- test: quote_referential_customer_id
-- Every customer_id in the quote table must exist in the customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_referential_customer_id' AS test_name
FROM
  `Curated.quote` AS q
LEFT JOIN
  `Curated.customer` AS c
  ON q.customer_id = c.customer_id
WHERE
  q.customer_id IS NOT NULL AND c.customer_id IS NULL;

-- =============================================================================
-- Tests for Curated.quote_detail
-- =============================================================================

-- test: quote_detail_unique_quote_detail_id
-- The quote_detail_id must be unique in the quote_detail table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_unique_quote_detail_id' AS test_name
FROM (
  SELECT
    quote_detail_id,
    COUNT(*) AS num_records
  FROM
    `Curated.quote_detail`
  WHERE
    quote_detail_id IS NOT NULL
  GROUP BY
    quote_detail_id
  HAVING
    num_records > 1
);

-- test: quote_detail_not_null_quote_detail_id
-- The quote_detail_id should never be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_not_null_quote_detail_id' AS test_name
FROM
  `Curated.quote_detail`
WHERE
  quote_detail_id IS NULL;

-- test: quote_detail_not_null_quote_id
-- Every quote detail must be associated with a quote.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_not_null_quote_id' AS test_name
FROM
  `Curated.quote_detail`
WHERE
  quote_id IS NULL;

-- test: quote_detail_not_null_product_name
-- The product_name should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_not_null_product_name' AS test_name
FROM
  `Curated.quote_detail`
WHERE
  product_name IS NULL;

-- test: quote_detail_range_quantity
-- The quantity of a product should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_range_quantity' AS test_name
FROM
  `Curated.quote_detail`
WHERE
  quantity < 0;

-- test: quote_detail_range_unit_price
-- The unit_price of a product should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_range_unit_price' AS test_name
FROM
  `Curated.quote_detail`
WHERE
  unit_price < 0;

-- test: quote_detail_range_discount
-- The discount should be between 0 and 1 (inclusive).
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_range_discount' AS test_name
FROM
  `Curated.quote_detail`
WHERE
  discount < 0 OR discount > 1;

-- test: quote_detail_range_total_amount
-- The total_amount for a line item should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_range_total_amount' AS test_name
FROM
  `Curated.quote_detail`
WHERE
  total_amount < 0;

-- test: quote_detail_referential_quote_id
-- Every quote_id in the quote_detail table must exist in the quote table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_referential_quote_id' AS test_name
FROM
  `Curated.quote_detail` AS qd
LEFT JOIN
  `Curated.quote` AS q
  ON qd.quote_id = q.quote_id
WHERE
  qd.quote_id IS NOT NULL AND q.quote_id IS NULL;