-- ============================================================================
-- Unit Tests for `fact_quote_details`
-- ============================================================================

-- test: not_null_composite_pk
-- The composite primary key columns `quoteid` and `productid` must be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_composite_pk' AS test_name,
  'The composite primary key columns `quoteid` and `productid` must be populated.' AS description
FROM `your_project_id.curated_dataset.fact_quote_details`
WHERE quoteid IS NULL OR productid IS NULL;

-- test: unique_composite_pk
-- The combination of `quoteid` and `productid` must be unique.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_composite_pk' AS test_name,
  'The combination of `quoteid` and `productid` must be unique.' AS description
FROM (
  SELECT
    quoteid,
    productid
  FROM `your_project_id.curated_dataset.fact_quote_details`
  WHERE quoteid IS NOT NULL AND productid IS NOT NULL
  GROUP BY 1, 2
  HAVING COUNT(*) > 1
);

-- test: positive_quantity
-- The `quantity` for a quote line item must be greater than zero.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'positive_quantity' AS test_name,
  'The `quantity` for a quote line item must be greater than zero.' AS description
FROM `your_project_id.curated_dataset.fact_quote_details`
WHERE quantity <= 0;

-- test: non_negative_priceperunit
-- The `priceperunit` for a quote line item should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'non_negative_priceperunit' AS test_name,
  'The `priceperunit` for a quote line item should not be negative.' AS description
FROM `your_project_id.curated_dataset.fact_quote_details`
WHERE priceperunit < 0;

-- test: consistency_extendedamount
-- The `extendedamount` should equal `quantity` * `priceperunit`, within a small tolerance.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'consistency_extendedamount' AS test_name,
  'The `extendedamount` should equal `quantity` * `priceperunit`.' AS description
FROM `your_project_id.curated_dataset.fact_quote_details`
WHERE ABS((quantity * priceperunit) - extendedamount) > 0.01;

-- test: referential_integrity_quoteid
-- Every `quoteid` must have a corresponding entry in `fact_quotes`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_quoteid' AS test_name,
  'Every `quoteid` must have a corresponding entry in `fact_quotes`.' AS description
FROM `your_project_id.curated_dataset.fact_quote_details` AS fqd
LEFT JOIN `your_project_id.curated_dataset.fact_quotes` AS fq
  ON fqd.quoteid = fq.quoteid
WHERE
  fqd.quoteid IS NOT NULL
  AND fq.quoteid IS NULL;

-- test: referential_integrity_productid
-- Every `productid` must have a corresponding entry in `dim_product`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_productid' AS test_name,
  'Every `productid` must have a corresponding entry in `dim_product`.' AS description
FROM `your_project_id.curated_dataset.fact_quote_details` AS fqd
LEFT JOIN `your_project_id.curated_dataset.dim_product` AS dp
  ON fqd.productid = dp.productid
WHERE
  fqd.productid IS NOT NULL
  AND dp.productid IS NULL;