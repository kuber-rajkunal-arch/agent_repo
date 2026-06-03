-- ============================================================================
-- Unit Tests for `dim_product`
-- ============================================================================

-- test: not_null_productid
-- The primary key `productid` must be populated for every record.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_productid' AS test_name,
  'The primary key `productid` must be populated for every record.' AS description
FROM `your_project_id.curated_dataset.dim_product`
WHERE productid IS NULL;

-- test: unique_productid
-- The primary key `productid` must be unique across the table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_productid' AS test_name,
  'The primary key `productid` must be unique across the table.' AS description
FROM (
  SELECT
    productid
  FROM `your_project_id.curated_dataset.dim_product`
  WHERE productid IS NOT NULL
  GROUP BY 1
  HAVING COUNT(*) > 1
);

-- test: not_null_name
-- The product `name` is a critical business identifier and should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_name' AS test_name,
  'The product `name` should always be populated.' AS description
FROM `your_project_id.curated_dataset.dim_product`
WHERE name IS NULL;

-- test: non_negative_price
-- The product `price` should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'non_negative_price' AS test_name,
  'The product `price` should not be negative.' AS description
FROM `your_project_id.curated_dataset.dim_product`
WHERE price < 0;