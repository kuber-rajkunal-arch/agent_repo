-- =============================================================================
-- Unit Tests for `curated_dataset.fact_sales`
-- =============================================================================

-- test: not_null_salesorderid
-- Ensures that the primary key `salesorderid` is never null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_salesorderid' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.fact_sales`
WHERE
  salesorderid IS NULL;

-- test: unique_salesorderid
-- Ensures that the primary key `salesorderid` is unique across the table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_salesorderid' AS test_name
FROM (
  SELECT
    salesorderid,
    COUNT(*) AS id_count
  FROM
    `gcp-cloud-source-repo.curated_dataset.fact_sales`
  WHERE
    salesorderid IS NOT NULL
  GROUP BY
    salesorderid
  HAVING
    id_count > 1
);

-- test: not_null_foreign_keys
-- A sale must be linked to an opportunity, customer, and account.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_foreign_keys' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.fact_sales`
WHERE
  opportunityid IS NULL OR customerid IS NULL OR accountid IS NULL;

-- test: non_negative_totalamount
-- The total amount of a sale should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'non_negative_totalamount' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.fact_sales`
WHERE
  totalamount < 0;

-- test: referential_integrity_opportunityid
-- Ensures that every `opportunityid` in `fact_sales` exists in `dim_opportunity`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_opportunityid' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.fact_sales` AS t
LEFT JOIN
  `gcp-cloud-source-repo.curated_dataset.dim_opportunity` AS ref
ON
  t.opportunityid = ref.opportunityid
WHERE
  t.opportunityid IS NOT NULL AND ref.opportunityid IS NULL;

-- test: referential_integrity_customerid
-- Ensures that every `customerid` in `fact_sales` exists in `dim_customer`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customerid' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.fact_sales` AS t
LEFT JOIN
  `gcp-cloud-source-repo.curated_dataset.dim_customer` AS ref
ON
  t.customerid = ref.customerid
WHERE
  t.customerid IS NOT NULL AND ref.customerid IS NULL;

-- test: referential_integrity_salesrepid
-- Ensures that every `salesrepid` in `fact_sales` exists in `dim_sales_rep`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_salesrepid' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.fact_sales` AS t
LEFT JOIN
  `gcp-cloud-source-repo.curated_dataset.dim_sales_rep` AS ref
ON
  t.salesrepid = ref.salesrepid
WHERE
  t.salesrepid IS NOT NULL AND ref.salesrepid IS NULL;