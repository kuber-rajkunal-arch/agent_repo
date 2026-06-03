/*
  Unit tests for the curated.fact_sales table.
  These tests verify the data integrity and quality of the transformed sales order data.
*/

-- test: not_null_fact_sales_salesorderid
-- The primary key `salesorderid` must not contain any NULL values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_fact_sales_salesorderid' AS test_name
FROM
  `your-gcp-project-id.curated_dataset.fact_sales`
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
    `your-gcp-project-id.curated_dataset.fact_sales`
  WHERE
    salesorderid IS NOT NULL
  GROUP BY
    salesorderid
  HAVING
    COUNT(*) > 1
);

-- test: referential_integrity_fact_sales_foreign_keys
-- All foreign keys in `fact_sales` must have a corresponding entry in their respective dimension tables.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_fact_sales_foreign_keys' AS test_name
FROM
(
  SELECT 'opportunityid' AS fk_column FROM `your-gcp-project-id.curated_dataset.fact_sales` t LEFT JOIN `your-gcp-project-id.curated_dataset.dim_opportunity` r ON t.opportunityid = r.opportunityid WHERE t.opportunityid IS NOT NULL AND r.opportunityid IS NULL
  UNION ALL
  SELECT 'customerid' AS fk_column FROM `your-gcp-project-id.curated_dataset.fact_sales` t LEFT JOIN `your-gcp-project-id.curated_dataset.dim_customer` r ON t.customerid = r.customerid WHERE t.customerid IS NOT NULL AND r.customerid IS NULL
  UNION ALL
  SELECT 'accountid' AS fk_column FROM `your-gcp-project-id.curated_dataset.fact_sales` t LEFT JOIN `your-gcp-project-id.curated_dataset.dim_account` r ON t.accountid = r.accountid WHERE t.accountid IS NOT NULL AND r.accountid IS NULL
  UNION ALL
  SELECT 'salesrepid' AS fk_column FROM `your-gcp-project-id.curated_dataset.fact_sales` t LEFT JOIN `your-gcp-project-id.curated_dataset.dim_sales_rep` r ON t.salesrepid = r.salesrepid WHERE t.salesrepid IS NOT NULL AND r.salesrepid IS NULL
);

-- test: range_check_fact_sales_totalamount
-- The total amount of a sale should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_fact_sales_totalamount' AS test_name
FROM
  `your-gcp-project-id.curated_dataset.fact_sales`
WHERE
  totalamount < 0;

-- test: not_null_fact_sales_createdon
-- The partitioning key `createdon` should not be NULL, as it's critical for table performance and management.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_fact_sales_createdon' AS test_name
FROM
  `your-gcp-project-id.curated_dataset.fact_sales`
WHERE
  createdon IS NULL;