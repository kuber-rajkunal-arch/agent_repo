/*
  Unit tests for the crm_gold.fact_sales_details table.
  These tests verify the data integrity and quality of the transformed sales line-item data.
*/

-- test: not_null_fact_sales_details_salesdetailid
-- The primary key `salesdetailid` must not be NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_fact_sales_details_salesdetailid' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.fact_sales_details`
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
    `your-gcp-project-id.your_gold_dataset.fact_sales_details`
  WHERE
    salesdetailid IS NOT NULL
  GROUP BY
    salesdetailid
  HAVING
    COUNT(*) > 1
);

-- test: referential_integrity_fact_sales_details_salesorderid
-- Each `salesorderid` must exist in `fact_sales`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_fact_sales_details_salesorderid' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.fact_sales_details` AS t
LEFT JOIN
  `your-gcp-project-id.your_gold_dataset.fact_sales` AS ref
  ON t.salesorderid = ref.salesorderid
WHERE
  t.salesorderid IS NOT NULL AND ref.salesorderid IS NULL;

-- test: referential_integrity_fact_sales_details_productid
-- Each `productid` must exist in `dim_product`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_fact_sales_details_productid' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.fact_sales_details` AS t
LEFT JOIN
  `your-gcp-project-id.your_gold_dataset.dim_product` AS ref
  ON t.productid = ref.productid
WHERE
  t.productid IS NOT NULL AND ref.productid IS NULL;

-- test: range_check_fact_sales_details_quantity
-- Quantity sold should be a positive value.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_fact_sales_details_quantity' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.fact_sales_details`
WHERE
  quantity <= 0;

-- test: consistency_check_fact_sales_details_extendedamount
-- The extended amount should equal quantity * price per unit, within a small tolerance for floating point inaccuracies.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'consistency_check_fact_sales_details_extendedamount' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.fact_sales_details`
WHERE
  ABS(SAFE_DIVIDE(extendedamount, quantity) - priceperunit) > 0.01
  AND quantity > 0;