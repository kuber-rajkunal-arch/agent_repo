/*
  Unit tests for the 'curated.quote' table.
  These tests validate the data integrity of the final quote table
  after the transformation script has been executed. The tests cover key integrity,
  referential integrity, business logic, and domain constraints.
*/

-- test: not_null_quote_id
-- The primary key 'quote_id' should never be null.
SELECT
  IF(COUNTIF(quote_id IS NULL) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_id' AS test_name
FROM `curated.quote`;

-- test: unique_quote_id
-- The primary key 'quote_id' must be unique across all records.
SELECT
  IF(COUNT(quote_id) = COUNT(DISTINCT quote_id), 'PASS', 'FAIL') AS result,
  'unique_quote_id' AS test_name
FROM `curated.quote`;

-- test: not_null_quote_number
-- The business key 'quote_number' should not be null.
SELECT
  IF(COUNTIF(quote_number IS NULL) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_number' AS test_name
FROM `curated.quote`;

-- test: unique_quote_number
-- The business key 'quote_number' should be unique.
SELECT
  IF(COUNT(quote_number) = COUNT(DISTINCT quote_number), 'PASS', 'FAIL') AS result,
  'unique_quote_number' AS test_name
FROM `curated.quote`;

-- test: not_null_opportunity_id
-- Every quote must be associated with an opportunity.
SELECT
  IF(COUNTIF(opportunity_id IS NULL) = 0, 'PASS', 'FAIL') AS result,
  'not_null_opportunity_id' AS test_name
FROM `curated.quote`;

-- test: not_null_customer_id
-- Every quote must be associated with a customer.
SELECT
  IF(COUNTIF(customer_id IS NULL) = 0, 'PASS', 'FAIL') AS result,
  'not_null_customer_id' AS test_name
FROM `curated.quote`;

-- test: referential_opportunity_id
-- The 'opportunity_id' in the quote table must exist in the opportunity table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_opportunity_id' AS test_name
FROM `curated.quote` AS q
LEFT JOIN `curated.opportunity` AS o
  ON q.opportunity_id = o.opportunity_id
WHERE
  q.opportunity_id IS NOT NULL
  AND o.opportunity_id IS NULL;

-- test: referential_customer_id
-- The 'customer_id' in the quote table must exist in the customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_customer_id' AS test_name
FROM `curated.quote` AS q
LEFT JOIN `curated.customer` AS c
  ON q.customer_id = c.customer_id
WHERE
  q.customer_id IS NOT NULL
  AND c.customer_id IS NULL;

-- test: range_total_amount
-- The 'total_amount' should be non-negative.
SELECT
  IF(COUNTIF(total_amount < 0) = 0, 'PASS', 'FAIL') AS result,
  'range_total_amount' AS test_name
FROM `curated.quote`
WHERE total_amount IS NOT NULL;

-- test: logic_valid_dates
-- The 'valid_to' date should not be before the 'valid_from' date.
SELECT
  IF(COUNTIF(valid_to < valid_from) = 0, 'PASS', 'FAIL') AS result,
  'logic_valid_dates' AS test_name
FROM `curated.quote`
WHERE valid_from IS NOT NULL AND valid_to IS NOT NULL;

-- test: domain_status
-- The 'status' field should conform to a predefined set of values.
SELECT
  IF(COUNTIF(status NOT IN ('Draft', 'Presented', 'Accepted', 'Expired', 'Declined')) = 0, 'PASS', 'FAIL') AS result,
  'domain_status' AS test_name
FROM `curated.quote`
WHERE status IS NOT NULL;