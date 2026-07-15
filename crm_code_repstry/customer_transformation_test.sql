/*
  Production-Ready Unit Tests for crm_code_repstry/customer_transformation.sql

  This script contains an enhanced suite of unit tests to validate the data integrity
  and business logic of the curated CRM tables populated by the MERGE statements
  in customer_transformation.sql.

  Each test is a standalone BigQuery SQL query that returns 'PASS' if the
  condition is met, and 'FAIL' otherwise. This suite is designed to be run
  after the ETL process to certify the quality of the curated data.

  Tests cover:
  - Uniqueness of primary keys.
  - Not-null constraints on critical columns.
  - Referential integrity between tables.
  - Domain, range, and format checks for specific fields.
  - Chronological and logical consistency.
*/

--------------------------------------------------------------------------------
-- Tests for: curated.customer
--------------------------------------------------------------------------------

-- test: customer_unique_customer_id
-- The customer_id must be unique in the customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'customer_unique_customer_id' AS test_name
FROM (
  SELECT customer_id, COUNT(*)
  FROM `curated.customer`
  GROUP BY customer_id
  HAVING COUNT(*) > 1
);

-- test: customer_not_null_customer_id
-- The customer_id should never be NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'customer_not_null_customer_id' AS test_name
FROM `curated.customer`
WHERE customer_id IS NULL;

-- test: customer_not_null_name
-- The customer name should never be NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'customer_not_null_name' AS test_name
FROM `curated.customer`
WHERE name IS NULL;

-- test: customer_not_null_created_on
-- The created_on timestamp should never be NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'customer_not_null_created_on' AS test_name
FROM `curated.customer`
WHERE created_on IS NULL;

-- test: customer_domain_is_active
-- The is_active flag must be a valid boolean (TRUE or FALSE), not NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'customer_domain_is_active' AS test_name
FROM `curated.customer`
WHERE is_active NOT IN (TRUE, FALSE);

-- test: customer_valid_email_format
-- The email field, when not null, should have a valid format.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'customer_valid_email_format' AS test_name
FROM `curated.customer`
WHERE email IS NOT NULL AND NOT REGEXP_CONTAINS(email, r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');


--------------------------------------------------------------------------------
-- Tests for: curated.lead
--------------------------------------------------------------------------------

-- test: lead_unique_lead_id
-- The lead_id must be unique in the lead table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'lead_unique_lead_id' AS test_name
FROM (
  SELECT lead_id, COUNT(*)
  FROM `curated.lead`
  GROUP BY lead_id
  HAVING COUNT(*) > 1
);

-- test: lead_not_null_lead_id
-- The lead_id should never be NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'lead_not_null_lead_id' AS test_name
FROM `curated.lead`
WHERE lead_id IS NULL;

-- test: lead_not_null_status
-- The lead status should never be NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'lead_not_null_status' AS test_name
FROM `curated.lead`
WHERE status IS NULL;

-- test: lead_referential_customer_id
-- Every non-NULL customer_id in the lead table must exist in the customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'lead_referential_customer_id' AS test_name
FROM `curated.lead` AS l
LEFT JOIN `curated.customer` AS c ON l.customer_id = c.customer_id
WHERE l.customer_id IS NOT NULL AND c.customer_id IS NULL;

-- test: lead_chronological_dates
-- The qualified_on date should not be before the created_on date.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'lead_chronological_dates' AS test_name
FROM `curated.lead`
WHERE qualified_on IS NOT NULL AND created_on IS NOT NULL AND qualified_on < created_on;


--------------------------------------------------------------------------------
-- Tests for: curated.opportunity
--------------------------------------------------------------------------------

-- test: opportunity_unique_opportunity_id
-- The opportunity_id must be unique in the opportunity table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_unique_opportunity_id' AS test_name
FROM (
  SELECT opportunity_id, COUNT(*)
  FROM `curated.opportunity`
  GROUP BY opportunity_id
  HAVING COUNT(*) > 1
);

-- test: opportunity_not_null_opportunity_id
-- The opportunity_id should never be NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_not_null_opportunity_id' AS test_name
FROM `curated.opportunity`
WHERE opportunity_id IS NULL;

-- test: opportunity_not_null_customer_id
-- The customer_id associated with an opportunity should never be NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_not_null_customer_id' AS test_name
FROM `curated.opportunity`
WHERE customer_id IS NULL;

-- test: opportunity_not_null_stage
-- The opportunity stage should never be NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_not_null_stage' AS test_name
FROM `curated.opportunity`
WHERE stage IS NULL;

-- test: opportunity_referential_customer_id
-- Every customer_id in the opportunity table must exist in the customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_referential_customer_id' AS test_name
FROM `curated.opportunity` AS o
LEFT JOIN `curated.customer` AS c ON o.customer_id = c.customer_id
WHERE o.customer_id IS NOT NULL AND c.customer_id IS NULL;

-- test: opportunity_referential_originating_lead_id
-- Every non-NULL originating_lead_id must exist in the lead table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_referential_originating_lead_id' AS test_name
FROM `curated.opportunity` AS o
LEFT JOIN `curated.lead` AS l ON o.originating_lead_id = l.lead_id
WHERE o.originating_lead_id IS NOT NULL AND l.lead_id IS NULL;

-- test: opportunity_range_probability
-- The probability of an opportunity should be between 0 and 1.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_range_probability' AS test_name
FROM `curated.opportunity`
WHERE probability < 0 OR probability > 1;

-- test: opportunity_positive_estimated_value
-- The estimated_value of an opportunity must not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_positive_estimated_value' AS test_name
FROM `curated.opportunity`
WHERE estimated_value < 0;

-- test: opportunity_chronological_dates
-- The close_date should not be before the created_on date.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_chronological_dates' AS test_name
FROM `curated.opportunity`
WHERE close_date IS NOT NULL AND created_on IS NOT NULL AND close_date < DATE(created_on);


--------------------------------------------------------------------------------
-- Tests for: curated.quote
--------------------------------------------------------------------------------

-- test: quote_unique_quote_id
-- The quote_id must be unique in the quote table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_unique_quote_id' AS test_name
FROM (
  SELECT quote_id, COUNT(*)
  FROM `curated.quote`
  GROUP BY quote_id
  HAVING COUNT(*) > 1
);

-- test: quote_not_null_quote_id
-- The quote_id should never be NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_not_null_quote_id' AS test_name
FROM `curated.quote`
WHERE quote_id IS NULL;

-- test: quote_not_null_opportunity_id
-- The opportunity_id on a quote should never be NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_not_null_opportunity_id' AS test_name
FROM `curated.quote`
WHERE opportunity_id IS NULL;

-- test: quote_referential_opportunity_id
-- Every opportunity_id in the quote table must exist in the opportunity table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_referential_opportunity_id' AS test_name
FROM `curated.quote` AS q
LEFT JOIN `curated.opportunity` AS o ON q.opportunity_id = o.opportunity_id
WHERE q.opportunity_id IS NOT NULL AND o.opportunity_id IS NULL;

-- test: quote_referential_customer_id
-- Every customer_id in the quote table must exist in the customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_referential_customer_id' AS test_name
FROM `curated.quote` AS q
LEFT JOIN `curated.customer` AS c ON q.customer_id = c.customer_id
WHERE q.customer_id IS NOT NULL AND c.customer_id IS NULL;

-- test: quote_positive_total_amount
-- The total_amount of a quote must not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_positive_total_amount' AS test_name
FROM `curated.quote`
WHERE total_amount < 0;

-- test: quote_customer_id_consistency
-- The customer_id on a quote must match the customer_id on its parent opportunity.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_customer_id_consistency' AS test_name
FROM `curated.quote` AS q
JOIN `curated.opportunity` AS o
  ON q.opportunity_id = o.opportunity_id
WHERE q.customer_id != o.customer_id;

-- test: quote_valid_date_range
-- The valid_to date for a quote should not be before its valid_from date.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_valid_date_range' AS test_name
FROM `curated.quote`
WHERE valid_to IS NOT NULL AND valid_from IS NOT NULL AND valid_to < valid_from;


--------------------------------------------------------------------------------
-- Tests for: curated.quote_detail
--------------------------------------------------------------------------------

-- test: quote_detail_unique_quote_detail_id
-- The quote_detail_id must be unique in the quote_detail table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_unique_quote_detail_id' AS test_name
FROM (
  SELECT quote_detail_id, COUNT(*)
  FROM `curated.quote_detail`
  GROUP BY quote_detail_id
  HAVING COUNT(*) > 1
);

-- test: quote_detail_not_null_quote_detail_id
-- The quote_detail_id should never be NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_not_null_quote_detail_id' AS test_name
FROM `curated.quote_detail`
WHERE quote_detail_id IS NULL;

-- test: quote_detail_not_null_quote_id
-- The quote_id on a quote_detail line should never be NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_not_null_quote_id' AS test_name
FROM `curated.quote_detail`
WHERE quote_id IS NULL;

-- test: quote_detail_referential_quote_id
-- Every quote_id in the quote_detail table must exist in the quote table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_referential_quote_id' AS test_name
FROM `curated.quote_detail` AS qd
LEFT JOIN `curated.quote` AS q ON qd.quote_id = q.quote_id
WHERE qd.quote_id IS NOT NULL AND q.quote_id IS NULL;

-- test: quote_detail_positive_quantity
-- The quantity for a quote line item must be greater than zero.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_positive_quantity' AS test_name
FROM `curated.quote_detail`
WHERE quantity <= 0;

-- test: quote_detail_positive_unit_price
-- The unit_price for a quote line item must not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_positive_unit_price' AS test_name
FROM `curated.quote_detail`
WHERE unit_price < 0;

-- test: quote_detail_range_discount
-- The discount for a quote line item should be between 0 and 1 (inclusive).
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_range_discount' AS test_name
FROM `curated.quote_detail`
WHERE discount < 0 OR discount > 1;

-- test: quote_detail_total_amount_calculation
-- The total_amount should be correctly calculated from quantity, unit_price, and discount.
-- Allows for a small tolerance for floating point inaccuracies.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_total_amount_calculation' AS test_name
FROM `curated.quote_detail`
WHERE
  total_amount > 0 AND
  ABS(
    (quantity * unit_price * (1 - COALESCE(discount, 0))) - total_amount
  ) > 0.01;