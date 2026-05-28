-- Tests for crm_raw_data_gold.fact_sales

-- test: not_null_fact_sales_salesorderid
-- The primary key `salesorderid` must not contain any NULL values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_fact_sales_salesorderid' AS test_name
FROM
  `gcp-cloud-source-repo.crm_raw_data_gold.fact_sales`
WHERE
  salesorderid IS NULL;

-- test: unique_fact_sales_salesorderid
-- The primary key `salesorderid` must be unique across all records.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_fact_sales_salesorderid' AS test_name
FROM (
  SELECT
    salesorderid
  FROM
    `gcp-cloud-source-repo.crm_raw_data_gold.fact_sales`
  WHERE
    salesorderid IS NOT NULL
  GROUP BY
    salesorderid
  HAVING
    COUNT(*) > 1
);

-- test: referential_integrity_fact_sales_opportunityid
-- Each non-NULL `opportunityid` must exist in `dim_opportunity`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_fact_sales_opportunityid' AS test_name
FROM
  `gcp-cloud-source-repo.crm_raw_data_gold.fact_sales` AS t
LEFT JOIN
  `gcp-cloud-source-repo.crm_raw_data_gold.dim_opportunity` AS ref
  ON t.opportunityid = ref.opportunityid
WHERE
  t.opportunityid IS NOT NULL AND ref.opportunityid IS NULL;

-- test: range_check_fact_sales_totalamount
-- The total amount of a sale should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_fact_sales_totalamount' AS test_name
FROM
  `gcp-cloud-source-repo.crm_raw_data_gold.fact_sales`
WHERE
  totalamount < 0;