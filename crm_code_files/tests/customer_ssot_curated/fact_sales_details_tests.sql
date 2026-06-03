/*
  Unit tests for the curated.fact_sales_details table.
  These tests verify the data integrity and quality of the transformed sales line-item data.
*/

-- test: not_null_fact_sales_details_salesdetailid
-- The primary key `salesdetailid` must not be NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_fact_sales_details_salesdetailid' AS test_name
FROM
  `your-gcp-project-id.curated_dataset.fact_sales_details`
WHERE
  salesdetailid IS NULL;

-- test: unique_fact_sales_details_salesdetailid
-- The primary key `salesdetailid` must be unique.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_fact_sales_details_salesdetailid' AS test_name
FROM (
  SELECT
    salesdetailid
  FROM
    `your-gcp-project-id.curated_dataset.fact_sales_details`
  WHERE
    salesdetailid IS NOT NULL
  GROUP BY
    salesdetailid
  HAVING
    COUNT(*) > 1
);

-- test: referential_integrity_fact_sales_details_foreign_keys
-- All foreign keys must exist in their respective parent tables.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_fact_sales_details_foreign_keys' AS test_name
FROM (
  SELECT 'salesorderid' AS fk_column FROM `your-gcp-project-id.curated_dataset.fact_sales_details` t LEFT JOIN `your-gcp-project-id.curated_dataset.fact_sales` r ON t.salesorderid = r.salesorderid WHERE t.salesorderid IS NOT NULL AND r.salesorderid IS NULL
  UNION ALL
  SELECT 'productid' AS fk_column FROM `your-gcp-project-id.curated_dataset.fact_sales_details` t LEFT JOIN `your-gcp-project-id.curated_dataset.dim_product` r ON t.productid = r.productid WHERE t.productid IS NOT NULL AND r.productid IS NULL
);

-- test: range_check_fact_sales_details_quantity
-- Quantity sold should be a positive value.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_fact_sales_details_quantity' AS test_name
FROM
  `your-gcp-project-id.curated_dataset.fact_sales_details`
WHERE
  quantity <= 0;

-- test: consistency_check_fact_sales_details_extendedamount
-- The extended amount should equal quantity * price per unit, within a small tolerance for floating point inaccuracies.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'consistency_check_fact_sales_details_extendedamount' AS test_name
FROM
  `your-gcp-project-id.curated_dataset.fact_sales_details`
WHERE
  quantity > 0 AND priceperunit >= 0 AND extendedamount >= 0
  AND ABS(extendedamount - (quantity * priceperunit)) > 0.01;