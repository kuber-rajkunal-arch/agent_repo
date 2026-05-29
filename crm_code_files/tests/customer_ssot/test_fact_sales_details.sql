-- File: tests/customer_ssot/test_fact_sales_details.sql
-- Description: Unit tests for the curated fact_sales_details table.

-- test: not_null_salesdetailid
-- Ensures the primary key column `salesdetailid` is never NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_salesdetailid' AS test_name
FROM
  `${project_id}.${curated_dataset}.fact_sales_details`
WHERE
  salesdetailid IS NULL;

-- test: unique_salesdetailid
-- Ensures that every `salesdetailid` is unique.
SELECT
  IF(COUNT(salesdetailid) = COUNT(DISTINCT salesdetailid), 'PASS', 'FAIL') AS result,
  'unique_salesdetailid' AS test_name
FROM
  `${project_id}.${curated_dataset}.fact_sales_details`;

-- test: range_check_quantity
-- Quantity should be a positive value.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_quantity' AS test_name
FROM
  `${project_id}.${curated_dataset}.fact_sales_details`
WHERE
  quantity <= 0;

-- test: referential_integrity_salesorderid
-- Verifies that every `salesorderid` in fact_sales_details exists in the fact_sales table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_salesorderid' AS test_name
FROM (
  SELECT
    fsd.salesorderid
  FROM
    `${project_id}.${curated_dataset}.fact_sales_details` AS fsd
  LEFT JOIN
    `${project_id}.${curated_dataset}.fact_sales` AS fs
    ON fsd.salesorderid = fs.salesorderid
  WHERE
    fs.salesorderid IS NULL
    AND fsd.salesorderid IS NOT NULL
);

-- test: referential_integrity_productid
-- Verifies that every `productid` in fact_sales_details exists in the dim_product table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_productid' AS test_name
FROM (
  SELECT
    fsd.productid
  FROM
    `${project_id}.${curated_dataset}.fact_sales_details` AS fsd
  LEFT JOIN
    `${project_id}.${curated_dataset}.dim_product` AS p
    ON fsd.productid = p.productid
  WHERE
    p.productid IS NULL
    AND fsd.productid IS NOT NULL
);