/*
  Unit tests for the crm_gold.dim_sales_rep table.
  These tests verify the data integrity and quality of the transformed sales representative data.
*/

-- test: not_null_dim_sales_rep_salesrepid
-- The primary key `salesrepid` must not contain any NULL values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_dim_sales_rep_salesrepid' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.dim_sales_rep`
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
    `your-gcp-project-id.your_gold_dataset.dim_sales_rep`
  WHERE
    salesrepid IS NOT NULL
  GROUP BY
    salesrepid
  HAVING
    COUNT(*) > 1
);

-- test: trimmed_check_dim_sales_rep_fields
-- All string fields should have no leading/trailing whitespace, verifying the TRIM() transformation.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'trimmed_check_dim_sales_rep_fields' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.dim_sales_rep`
WHERE
  name <> TRIM(name)
  OR region <> TRIM(region);