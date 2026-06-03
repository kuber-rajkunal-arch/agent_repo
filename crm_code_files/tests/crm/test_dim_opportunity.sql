-- ============================================================================
-- Unit Tests for `dim_opportunity`
-- ============================================================================

-- test: not_null_opportunityid
-- The primary key `opportunityid` must be populated for every record.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_opportunityid' AS test_name,
  'The primary key `opportunityid` must be populated for every record.' AS description
FROM `your_project_id.curated_dataset.dim_opportunity`
WHERE opportunityid IS NULL;

-- test: unique_opportunityid
-- The primary key `opportunityid` must be unique across the table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_opportunityid' AS test_name,
  'The primary key `opportunityid` must be unique across the table.' AS description
FROM (
  SELECT
    opportunityid
  FROM `your_project_id.curated_dataset.dim_opportunity`
  WHERE opportunityid IS NOT NULL
  GROUP BY 1
  HAVING COUNT(*) > 1
);

-- test: non_negative_estimatedvalue
-- The `estimatedvalue` of an opportunity should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'non_negative_estimatedvalue' AS test_name,
  'The `estimatedvalue` of an opportunity should not be negative.' AS description
FROM `your_project_id.curated_dataset.dim_opportunity`
WHERE estimatedvalue < 0;

-- test: referential_integrity_leadid
-- Every non-null `leadid` must have a corresponding entry in `dim_lead`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_leadid' AS test_name,
  'Every non-null `leadid` must have a corresponding entry in `dim_lead`.' AS description
FROM `your_project_id.curated_dataset.dim_opportunity` AS opp
LEFT JOIN `your_project_id.curated_dataset.dim_lead` AS lead
  ON opp.leadid = lead.leadid
WHERE
  opp.leadid IS NOT NULL
  AND lead.leadid IS NULL;

-- test: referential_integrity_customerid
-- Every non-null `customerid` must have a corresponding entry in `dim_customer`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customerid' AS test_name,
  'Every non-null `customerid` must have a corresponding entry in `dim_customer`.' AS description
FROM `your_project_id.curated_dataset.dim_opportunity` AS opp
LEFT JOIN `your_project_id.curated_dataset.dim_customer` AS customer
  ON opp.customerid = customer.customerid
WHERE
  opp.customerid IS NOT NULL
  AND customer.customerid IS NULL;

-- test: referential_integrity_accountid
-- Every non-null `accountid` must have a corresponding entry in `dim_account`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_accountid' AS test_name,
  'Every non-null `accountid` must have a corresponding entry in `dim_account`.' AS description
FROM `your_project_id.curated_dataset.dim_opportunity` AS opp
LEFT JOIN `your_project_id.curated_dataset.dim_account` AS account
  ON opp.accountid = account.accountid
WHERE
  opp.accountid IS NOT NULL
  AND account.accountid IS NULL;

-- test: referential_integrity_salesrepid
-- Every non-null `salesrepid` must have a corresponding entry in `dim_sales_rep`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_salesrepid' AS test_name,
  'Every non-null `salesrepid` must have a corresponding entry in `dim_sales_rep`.' AS description
FROM `your_project_id.curated_dataset.dim_opportunity` AS opp
LEFT JOIN `your_project_id.curated_dataset.dim_sales_rep` AS sales_rep
  ON opp.salesrepid = sales_rep.salesrepid
WHERE
  opp.salesrepid IS NOT NULL
  AND sales_rep.salesrepid IS NULL;