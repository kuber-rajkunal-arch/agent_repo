-- =============================================================================
-- Unit Tests for `curated_dataset.fact_sales_details`
-- =============================================================================

-- test: not_null_salesdetailid
-- Ensures that the primary key `salesdetailid` is never null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_salesdetailid' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.fact_sales_details`
WHERE
  salesdetailid IS NULL;

-- test: unique_salesdetailid
-- Ensures that the primary key `salesdetailid` is unique across the table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_salesdetailid' AS test_name
FROM (
  SELECT
    salesdetailid,
    COUNT(*) AS id_count
  FROM
    `gcp-cloud-source-repo.curated_dataset.fact_sales_details`
  WHERE
    salesdetailid IS NOT NULL
  GROUP BY
    salesdetailid
  HAVING
    id_count > 1
);

-- test: positive_quantity
-- The quantity of a product in a sales detail must be greater than zero.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'positive_quantity' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.fact_sales_details`
WHERE
  quantity <= 0;

-- test: non_negative_priceperunit
-- The price per unit should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'non_negative_priceperunit' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.fact_sales_details`
WHERE
  priceperunit < 0;

-- test: consistency_check_extendedamount
-- The extended amount should equal quantity * priceperunit (within a small tolerance for floating point).
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'consistency_check_extendedamount' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.fact_sales_details`
WHERE
  ABS((quantity * priceperunit) - extendedamount) > 0.01;

-- test: referential_integrity_salesorderid
-- Ensures that every `salesorderid` in `fact_sales_details` exists in `fact_sales`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_salesorderid' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.fact_sales_details` AS t
LEFT JOIN
  `gcp-cloud-source-repo.curated_dataset.fact_sales` AS ref
ON
  t.salesorderid = ref.salesorderid
WHERE
  t.salesorderid IS NOT NULL AND ref.salesorderid IS NULL;

-- test: referential_integrity_productid
-- Ensures that every `productid` in `fact_sales_details` exists in `dim_product`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_productid' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.fact_sales_details` AS t
LEFT JOIN
  `gcp-cloud-source-repo.curated_dataset.dim_product` AS ref
ON
  t.productid = ref.productid
WHERE
  t.productid IS NOT NULL AND ref.productid IS NULL;