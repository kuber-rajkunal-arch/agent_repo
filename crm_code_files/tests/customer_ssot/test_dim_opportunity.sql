-- File: tests/customer_ssot/test_dim_opportunity.sql
-- Description: Unit tests for the curated dim_opportunity table.

-- test: not_null_opportunityid
-- Ensures the primary key column `opportunityid` is never NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_opportunityid' AS test_name
FROM
  `${project_id}.${curated_dataset}.dim_opportunity`
WHERE
  opportunityid IS NULL;

-- test: unique_opportunityid
-- Ensures that every `opportunityid` is unique.
SELECT
  IF(COUNT(opportunityid) = COUNT(DISTINCT opportunityid), 'PASS', 'FAIL') AS result,
  'unique_opportunityid' AS test_name
FROM
  `${project_id}.${curated_dataset}.dim_opportunity`;

-- test: not_null_createdon
-- Verifies that the SAFE_CAST on `createdon` did not result in unexpected NULLs.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_createdon' AS test_name
FROM
  `${project_id}.${curated_dataset}.dim_opportunity`
WHERE
  createdon IS NULL;

-- test: referential_integrity_customerid
-- Verifies that every `customerid` in dim_opportunity exists in the dim_customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customerid' AS test_name
FROM (
  SELECT
    opp.customerid
  FROM
    `${project_id}.${curated_dataset}.dim_opportunity` AS opp
  LEFT JOIN
    `${project_id}.${curated_dataset}.dim_customer` AS cust
    ON opp.customerid = cust.customerid
  WHERE
    cust.customerid IS NULL
    AND opp.customerid IS NOT NULL
);

-- test: referential_integrity_salesrepid
-- Verifies that every `salesrepid` in dim_opportunity exists in the dim_sales_rep table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_salesrepid' AS test_name
FROM (
  SELECT
    opp.salesrepid
  FROM
    `${project_id}.${curated_dataset}.dim_opportunity` AS opp
  LEFT JOIN
    `${project_id}.${curated_dataset}.dim_sales_rep` AS rep
    ON opp.salesrepid = rep.salesrepid
  WHERE
    rep.salesrepid IS NULL
    AND opp.salesrepid IS NOT NULL
);