-- Tests for crm_raw_data_gold.dim_sales_rep

-- test: not_null_dim_sales_rep_salesrepid
-- The primary key `salesrepid` must not contain any NULL values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_dim_sales_rep_salesrepid' AS test_name
FROM
  `gcp-cloud-source-repo.crm_raw_data_gold.dim_sales_rep`
WHERE
  salesrepid IS NULL;

-- test: unique_dim_sales_rep_salesrepid
-- The primary key `salesrepid` must be unique across all records.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_dim_sales_rep_salesrepid' AS test_name
FROM (
  SELECT
    salesrepid
  FROM
    `gcp-cloud-source-repo.crm_raw_data_gold.dim_sales_rep`
  WHERE
    salesrepid IS NOT NULL
  GROUP BY
    salesrepid
  HAVING
    COUNT(*) > 1
);