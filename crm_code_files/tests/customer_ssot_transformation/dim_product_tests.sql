-- Tests for crm_raw_data_gold.dim_product

-- test: not_null_dim_product_productid
-- The primary key `productid` must not contain any NULL values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_dim_product_productid' AS test_name
FROM
  `gcp-cloud-source-repo.crm_raw_data_gold.dim_product`
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
    `gcp-cloud-source-repo.crm_raw_data_gold.dim_product`
  WHERE
    productid IS NOT NULL
  GROUP BY
    productid
  HAVING
    COUNT(*) > 1
);

-- test: range_check_dim_product_price
-- The price of a product should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_dim_product_price' AS test_name
FROM
  `gcp-cloud-source-repo.crm_raw_data_gold.dim_product`
WHERE
  price < 0;