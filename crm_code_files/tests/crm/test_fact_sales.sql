-- ============================================================================
-- Unit Tests for `fact_sales`
-- ============================================================================

-- test: not_null_salesorderid
-- The primary key `salesorderid` must be populated for every record.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_salesorderid' AS test_name,
  'The primary key `salesorderid` must be populated for every record.' AS description
FROM `your_project_id.curated_dataset.fact_sales`
WHERE salesorderid IS NULL;

-- test: unique_salesorderid
-- The primary key `salesorderid` must be unique across the table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_salesorderid' AS test_name,
  'The primary key `salesorderid` must be unique across the table.' AS description
FROM (
  SELECT
    salesorderid
  FROM `your_project_id.curated_dataset.fact_sales`
  WHERE salesorderid IS NOT NULL
  GROUP BY 1
  HAVING COUNT(*) > 1
);

-- test: not_null_foreign_keys
-- Foreign keys to dimension tables (opportunityid, customerid, accountid, salesrepid) must be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_foreign_keys' AS test_name,
  'Foreign keys to dimension tables must be populated.' AS description
FROM `your_project_id.curated_dataset.fact_sales`
WHERE opportunityid IS NULL OR customerid IS NULL OR accountid IS NULL OR salesrepid IS NULL;

-- test: non_negative_totalamount
-- The `totalamount` of a sale should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'non_negative_totalamount' AS test_name,
  'The `totalamount` of a sale should not be negative.' AS description
FROM `your_project_id.curated_dataset.fact_sales`
WHERE totalamount < 0;

-- test: referential_integrity_opportunityid
-- Every `opportunityid` must have a corresponding entry in `dim_opportunity`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_opportunityid' AS test_name,
  'Every `opportunityid` must have a corresponding entry in `dim_opportunity`.' AS description
FROM `your_project_id.curated_dataset.fact_sales` AS fs
LEFT JOIN `your_project_id.curated_dataset.dim_opportunity` AS d_opp
  ON fs.opportunityid = d_opp.opportunityid
WHERE
  fs.opportunityid IS NOT NULL
  AND d_opp.opportunityid IS NULL;

-- test: referential_integrity_customerid
-- Every `customerid` must have a corresponding entry in `dim_customer`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customerid' AS test_name,
  'Every `customerid` must have a corresponding entry in `dim_customer`.' AS description
FROM `your_project_id.curated_dataset.fact_sales` AS fs
LEFT JOIN `your_project_id.curated_dataset.dim_customer` AS d_cust
  ON fs.customerid = d_cust.customerid
WHERE
  fs.customerid IS NOT NULL
  AND d_cust.customerid IS NULL;