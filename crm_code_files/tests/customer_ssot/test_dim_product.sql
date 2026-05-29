-- File: tests/customer_ssot/test_dim_product.sql
-- Description: Unit tests for the curated dim_product table.

-- test: not_null_productid
-- Ensures the primary key column `productid` is never NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_productid' AS test_name
FROM
  `${project_id}.${curated_dataset}.dim_product`
WHERE
  productid IS NULL;

-- test: unique_productid
-- Ensures that every `productid` is unique.
SELECT
  IF(COUNT(productid) = COUNT(DISTINCT productid), 'PASS', 'FAIL') AS result,
  'unique_productid' AS test_name
FROM
  `${project_id}.${curated_dataset}.dim_product`;

-- test: not_null_price
-- Verifies that the SAFE_CAST on `price` did not result in unexpected NULLs for products that should have a price.
-- This test assumes products can have a price of 0 but not NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_price' AS test_name
FROM
  `${project_id}.${curated_dataset}.dim_product`
WHERE
  price IS NULL;

-- test: range_check_price
-- Product price should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_price' AS test_name
FROM
  `${project_id}.${curated_dataset}.dim_product`
WHERE
  price < 0;