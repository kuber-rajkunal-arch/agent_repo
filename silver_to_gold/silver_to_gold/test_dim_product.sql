-- =============================================================================
-- Unit Tests for `curated_dataset.dim_product`
-- =============================================================================

-- test: not_null_productid
-- Ensures that the primary key `productid` is never null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_productid' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_product`
WHERE
  productid IS NULL;

-- test: unique_productid
-- Ensures that the primary key `productid` is unique across the table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_productid' AS test_name
FROM (
  SELECT
    productid,
    COUNT(*) AS id_count
  FROM
    `gcp-cloud-source-repo.curated_dataset.dim_product`
  WHERE
    productid IS NOT NULL
  GROUP BY
    productid
  HAVING
    id_count > 1
);

-- test: not_null_name
-- The product name is a critical business field and should not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_name' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_product`
WHERE
  name IS NULL;

-- test: non_negative_price
-- The product price should not be negative. A null may indicate a failed SAFE_CAST.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'non_negative_price' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_product`
WHERE
  price < 0;