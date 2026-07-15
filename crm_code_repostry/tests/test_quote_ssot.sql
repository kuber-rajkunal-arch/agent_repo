/*
  Unit tests for the Curated.quote table.
  These tests validate the data integrity of the quote single source of truth.
*/

-- test: unique_quote_id
-- Ensures that every quote has a unique identifier.
SELECT
  IF(COUNT(quote_id) = COUNT(DISTINCT quote_id), 'PASS', 'FAIL') AS result,
  'unique_quote_id' AS test_name
FROM
  `Curated.quote`;

-- test: not_null_quote_id
-- The primary key for the quote table must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_id' AS test_name
FROM
  `Curated.quote`
WHERE
  quote_id IS NULL;

-- test: not_null_opportunity_id
-- Every quote must be associated with an opportunity.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_opportunity_id' AS test_name
FROM
  `Curated.quote`
WHERE
  opportunity_id IS NULL;

-- test: not_null_customer_id
-- Every quote must be associated with a customer.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_customer_id' AS test_name
FROM
  `Curated.quote`
WHERE
  customer_id IS NULL;

-- test: referential_integrity_opportunity_id
-- The opportunity_id on a quote must exist in the opportunity table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_opportunity_id' AS test_name
FROM
  `Curated.quote` AS q
LEFT JOIN
  `Curated.opportunity` AS o
  ON q.opportunity_id = o.opportunity_id
WHERE
  o.opportunity_id IS NULL;

-- test: referential_integrity_customer_id
-- The customer_id on a quote must exist in the customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customer_id' AS test_name
FROM
  `Curated.quote` AS q
LEFT JOIN
  `Curated.customer` AS c
  ON q.customer_id = c.customer_id
WHERE
  c.customer_id IS NULL;

-- test: range_check_total_amount
-- The total amount of a quote cannot be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_total_amount' AS test_name
FROM
  `Curated.quote`
WHERE
  total_amount < 0;

-- test: chronological_order_valid_to
-- A quote's 'valid_to' date must be on or after its 'valid_from' date.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'chronological_order_valid_to' AS test_name
FROM
  `Curated.quote`
WHERE
  valid_to IS NOT NULL
  AND valid_from IS NOT NULL
  AND valid_to < valid_from;