/*
  Unit tests for the crm_gold.fact_quote_details table.
  These tests verify the data integrity and quality of the transformed quote line-item data.
*/

-- test: not_null_fact_quote_details_primary_keys
-- The composite primary key columns `quoteid` and `productid` must not be NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_fact_quote_details_primary_keys' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.fact_quote_details`
WHERE
  quoteid IS NULL OR productid IS NULL;

-- test: unique_fact_quote_details_primary_key
-- The composite primary key (`quoteid`, `productid`) must be unique.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_fact_quote_details_primary_key' AS test_name
FROM (
  SELECT
    quoteid,
    productid
  FROM
    `your-gcp-project-id.your_gold_dataset.fact_quote_details`
  WHERE
    quoteid IS NOT NULL AND productid IS NOT NULL
  GROUP BY
    quoteid,
    productid
  HAVING
    COUNT(*) > 1
);

-- test: referential_integrity_fact_quote_details_quoteid
-- Each `quoteid` must exist in `fact_quotes`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_fact_quote_details_quoteid' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.fact_quote_details` AS t
LEFT JOIN
  `your-gcp-project-id.your_gold_dataset.fact_quotes` AS ref
  ON t.quoteid = ref.quoteid
WHERE
  t.quoteid IS NOT NULL AND ref.quoteid IS NULL;

-- test: referential_integrity_fact_quote_details_productid
-- Each `productid` must exist in `dim_product`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_fact_quote_details_productid' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.fact_quote_details` AS t
LEFT JOIN
  `your-gcp-project-id.your_gold_dataset.dim_product` AS ref
  ON t.productid = ref.productid
WHERE
  t.productid IS NOT NULL AND ref.productid IS NULL;

-- test: range_check_fact_quote_details_quantity
-- Quantity should be a positive value.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_fact_quote_details_quantity' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.fact_quote_details`
WHERE
  quantity <= 0;

-- test: consistency_check_fact_quote_details_extendedamount
-- The extended amount should equal quantity * price per unit, within a small tolerance for floating point inaccuracies.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'consistency_check_fact_quote_details_extendedamount' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.fact_quote_details`
WHERE
  ABS(SAFE_DIVIDE(extendedamount, quantity) - priceperunit) > 0.01
  AND quantity > 0;