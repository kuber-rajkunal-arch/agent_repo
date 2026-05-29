-- File: tests/customer_ssot/test_fact_quote_details.sql
-- Description: Unit tests for the curated fact_quote_details table.

-- test: unique_composite_primary_key
-- The combination of quoteid and productid should be unique for each quote detail line.
-- This validates the MERGE logic on the composite key.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_composite_primary_key' AS test_name
FROM (
  SELECT
    quoteid,
    productid
  FROM
    `${project_id}.${curated_dataset}.fact_quote_details`
  GROUP BY
    quoteid,
    productid
  HAVING
    COUNT(*) > 1
);

-- test: not_null_primary_keys
-- Ensures the composite primary key columns are never NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_primary_keys' AS test_name
FROM
  `${project_id}.${curated_dataset}.fact_quote_details`
WHERE
  quoteid IS NULL
  OR productid IS NULL;

-- test: range_check_quantity
-- Quantity should be a positive value.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_quantity' AS test_name
FROM
  `${project_id}.${curated_dataset}.fact_quote_details`
WHERE
  quantity <= 0;

-- test: referential_integrity_quoteid
-- Verifies that every `quoteid` in fact_quote_details exists in the fact_quotes table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_quoteid' AS test_name
FROM (
  SELECT
    fqd.quoteid
  FROM
    `${project_id}.${curated_dataset}.fact_quote_details` AS fqd
  LEFT JOIN
    `${project_id}.${curated_dataset}.fact_quotes` AS fq
    ON fqd.quoteid = fq.quoteid
  WHERE
    fq.quoteid IS NULL
);

-- test: referential_integrity_productid
-- Verifies that every `productid` in fact_quote_details exists in the dim_product table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_productid' AS test_name
FROM (
  SELECT
    fqd.productid
  FROM
    `${project_id}.${curated_dataset}.fact_quote_details` AS fqd
  LEFT JOIN
    `${project_id}.${curated_dataset}.dim_product` AS p
    ON fqd.productid = p.productid
  WHERE
    p.productid IS NULL
);