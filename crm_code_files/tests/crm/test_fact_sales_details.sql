-- ============================================================================
-- Unit Tests for `fact_sales_details`
-- ============================================================================

-- test: not_null_salesdetailid
-- The primary key `salesdetailid` must be populated for every record.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_salesdetailid' AS test_name,
  'The primary key `salesdetailid` must be populated for every record.' AS description
FROM `your_project_id.curated_dataset.fact_sales_details`
WHERE salesdetailid IS NULL;

-- test: unique_salesdetailid
-- The primary key `salesdetailid` must be unique across the table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_salesdetailid' AS test_name,
  'The primary key `salesdetailid` must be unique across the table.' AS description
FROM (
  SELECT
    salesdetailid
  FROM `your_project_id.curated_dataset.fact_sales_details`
  WHERE salesdetailid IS NOT NULL
  GROUP BY 1
  HAVING COUNT(*) > 1
);

-- test: positive_quantity
-- The `quantity` for a sales line item must be greater than zero.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'positive_quantity' AS test_name,
  'The `quantity` for a sales line item must be greater than zero.' AS description
FROM `your_project_id.curated_dataset.fact_sales_details`
WHERE quantity <= 0;

-- test: non_negative_priceperunit
-- The `priceperunit` for a sales line item should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'non_negative_priceperunit' AS test_name,
  'The `priceperunit` for a sales line item should not be negative.' AS description
FROM `your_project_id.curated_dataset.fact_sales_details`
WHERE priceperunit < 0;

-- test: consistency_extendedamount
-- The `extendedamount` should equal `quantity` * `priceperunit`, within a small tolerance.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'consistency_extendedamount' AS test_name,
  'The `extendedamount` should equal `quantity` * `priceperunit`.' AS description
FROM `your_project_id.curated_dataset.fact_sales_details`
WHERE ABS((quantity * priceperunit) - extendedamount) > 0.01;

-- test: referential_integrity_salesorderid
-- Every `salesorderid` must have a corresponding entry in `fact_sales`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_salesorderid' AS test_name,
  'Every `salesorderid` must have a corresponding entry in `fact_sales`.' AS description
FROM `your_project_id.curated_dataset.fact_sales_details` AS fsd
LEFT JOIN `your_project_id.curated_dataset.fact_sales` AS fs
  ON fsd.salesorderid = fs.salesorderid
WHERE
  fsd.salesorderid IS NOT NULL
  AND fs.salesorderid IS NULL;

-- test: referential_integrity_productid
-- Every `productid` must have a corresponding entry in `dim_product`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_productid' AS test_name,
  'Every `productid` must have a corresponding entry in `dim_product`.' AS description
FROM `your_project_id.curated_dataset.fact_sales_details` AS fsd
LEFT JOIN `your_project_id.curated_dataset.dim_product` AS dp
  ON fsd.productid = dp.productid
WHERE
  fsd.productid IS NOT NULL
  AND dp.productid IS NULL;