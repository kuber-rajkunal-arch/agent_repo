/*
  Unit tests for the curated.fact_quote_details table.
  These tests verify the data integrity and quality of the transformed quote line-item data.
*/

-- test: not_null_fact_quote_details_primary_keys
-- The composite primary key columns `quoteid` and `productid` must not be NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_fact_quote_details_primary_keys' AS test_name
FROM
  `your-gcp-project-id.curated_dataset.fact_quote_details`
WHERE
  quoteid IS NULL OR productid IS NULL;

-- test: unique_fact_quote_details_primary_key
-- The composite primary key (`quoteid`, `productid`) must be unique.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_fact_quote_details_primary_key' AS test_name
FROM (
  SELECT
    quoteid,
    productid
  FROM
    `your-gcp-project-id.curated_dataset.fact_quote_details`
  WHERE
    quoteid IS NOT NULL AND productid IS NOT NULL
  GROUP BY
    quoteid,
    productid
  HAVING
    COUNT(*) > 1
);

-- test: referential_integrity_fact_quote_details_foreign_keys
-- All foreign keys must exist in their respective parent tables.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_fact_quote_details_foreign_keys' AS test_name
FROM (
  SELECT 'quoteid' AS fk_column FROM `your-gcp-project-id.curated_dataset.fact_quote_details` t LEFT JOIN `your-gcp-project-id.curated_dataset.fact_quotes` r ON t.quoteid = r.quoteid WHERE t.quoteid IS NOT NULL AND r.quoteid IS NULL
  UNION ALL
  SELECT 'productid' AS fk_column FROM `your-gcp-project-id.curated_dataset.fact_quote_details` t LEFT JOIN `your-gcp-project-id.curated_dataset.dim_product` r ON t.productid = r.productid WHERE t.productid IS NOT NULL AND r.productid IS NULL
);

-- test: range_check_fact_quote_details_quantity
-- Quantity should be a positive value.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_fact_quote_details_quantity' AS test_name
FROM
  `your-gcp-project-id.curated_dataset.fact_quote_details`
WHERE
  quantity <= 0;

-- test: consistency_check_fact_quote_details_extendedamount
-- The extended amount should equal quantity * price per unit, within a small tolerance for floating point inaccuracies.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'consistency_check_fact_quote_details_extendedamount' AS test_name
FROM
  `your-gcp-project-id.curated_dataset.fact_quote_details`
WHERE
  quantity > 0 AND priceperunit >= 0 AND extendedamount >= 0
  AND ABS(extendedamount - (quantity * priceperunit)) > 0.01;