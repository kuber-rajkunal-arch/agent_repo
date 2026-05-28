/*
  Unit tests for the crm_gold.dim_product table.
  These tests verify the data integrity and quality of the transformed product data.
*/

-- test: not_null_dim_product_productid
-- The primary key `productid` must not contain any NULL values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_dim_product_productid' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.dim_product`
WHERE
  productid IS NULL;

-- test: unique_dim_product_productid
-- The primary key `productid` must be unique across all records.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_dim_product_productid' AS test_name
FROM (
  SELECT
    productid
  FROM
    `your-gcp-project-id.your_gold_dataset.dim_product`
  WHERE
    productid IS NOT NULL
  GROUP BY
    productid
  HAVING
    COUNT(*) > 1
);

-- test: range_check_dim_product_price
-- The price of a product should not be negative. This verifies the SAFE_CAST and source data quality.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_dim_product_price' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.dim_product`
WHERE
  price < 0;

-- test: trimmed_check_dim_product_fields
-- All string fields should have no leading/trailing whitespace, verifying the TRIM() transformation.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'trimmed_check_dim_product_fields' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.dim_product`
WHERE
  name <> TRIM(name)
  OR category <> TRIM(category)
  OR currencycode <> TRIM(currencycode);