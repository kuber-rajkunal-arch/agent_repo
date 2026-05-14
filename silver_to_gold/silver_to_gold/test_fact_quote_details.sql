-- =============================================================================
-- Unit Tests for `curated_dataset.fact_quote_details`
-- =============================================================================

-- test: not_null_composite_key
-- Ensures that the composite primary key components `quoteid` and `productid` are never null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_composite_key' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.fact_quote_details`
WHERE
  quoteid IS NULL OR productid IS NULL;

-- test: unique_composite_key
-- Ensures that the composite primary key (`quoteid`, `productid`) is unique.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_composite_key' AS test_name
FROM (
  SELECT
    quoteid,
    productid,
    COUNT(*) AS key_count
  FROM
    `gcp-cloud-source-repo.curated_dataset.fact_quote_details`
  WHERE
    quoteid IS NOT NULL AND productid IS NOT NULL
  GROUP BY
    quoteid,
    productid
  HAVING
    key_count > 1
);

-- test: positive_quantity
-- The quantity of a product in a quote detail must be greater than zero.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'positive_quantity' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.fact_quote_details`
WHERE
  quantity <= 0;

-- test: non_negative_priceperunit
-- The price per unit should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'non_negative_priceperunit' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.fact_quote_details`
WHERE
  priceperunit < 0;

-- test: consistency_check_extendedamount
-- The extended amount should equal quantity * priceperunit (within a small tolerance for floating point).
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'consistency_check_extendedamount' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.fact_quote_details`
WHERE
  ABS((quantity * priceperunit) - extendedamount) > 0.01;

-- test: referential_integrity_quoteid
-- Ensures that every `quoteid` in `fact_quote_details` exists in `fact_quotes`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_quoteid' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.fact_quote_details` AS t
LEFT JOIN
  `gcp-cloud-source-repo.curated_dataset.fact_quotes` AS ref
ON
  t.quoteid = ref.quoteid
WHERE
  t.quoteid IS NOT NULL AND ref.quoteid IS NULL;

-- test: referential_integrity_productid
-- Ensures that every `productid` in `fact_quote_details` exists in `dim_product`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_productid' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.fact_quote_details` AS t
LEFT JOIN
  `gcp-cloud-source-repo.curated_dataset.dim_product` AS ref
ON
  t.productid = ref.productid
WHERE
  t.productid IS NOT NULL AND ref.productid IS NULL;