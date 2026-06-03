-- ============================================================================
-- Unit Tests for `dim_lead`
-- ============================================================================

-- test: not_null_leadid
-- The primary key `leadid` must be populated for every record.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_leadid' AS test_name,
  'The primary key `leadid` must be populated for every record.' AS description
FROM `your_project_id.curated_dataset.dim_lead`
WHERE leadid IS NULL;

-- test: unique_leadid
-- The primary key `leadid` must be unique across the table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_leadid' AS test_name,
  'The primary key `leadid` must be unique across the table.' AS description
FROM (
  SELECT
    leadid
  FROM `your_project_id.curated_dataset.dim_lead`
  WHERE leadid IS NOT NULL
  GROUP BY 1
  HAVING COUNT(*) > 1
);

-- test: not_null_statuscode
-- The `statuscode` is a critical attribute and should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_statuscode' AS test_name,
  'The `statuscode` should always be populated.' AS description
FROM `your_project_id.curated_dataset.dim_lead`
WHERE statuscode IS NULL;

-- test: not_null_createdon
-- The `createdon` date is critical for tracking and should not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_createdon' AS test_name,
  'The `createdon` date should not be null.' AS description
FROM `your_project_id.curated_dataset.dim_lead`
WHERE createdon IS NULL;

-- test: referential_integrity_customerid
-- Every non-null `customerid` in `dim_lead` must have a corresponding entry in `dim_customer`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customerid' AS test_name,
  'Every non-null `customerid` in `dim_lead` must have a corresponding entry in `dim_customer`.' AS description
FROM `your_project_id.curated_dataset.dim_lead` AS lead
LEFT JOIN `your_project_id.curated_dataset.dim_customer` AS customer
  ON lead.customerid = customer.customerid
WHERE
  lead.customerid IS NOT NULL
  AND customer.customerid IS NULL;

-- test: referential_integrity_accountid
-- Every non-null `accountid` in `dim_lead` must have a corresponding entry in `dim_account`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_accountid' AS test_name,
  'Every non-null `accountid` in `dim_lead` must have a corresponding entry in `dim_account`.' AS description
FROM `your_project_id.curated_dataset.dim_lead` AS lead
LEFT JOIN `your_project_id.curated_dataset.dim_account` AS account
  ON lead.accountid = account.accountid
WHERE
  lead.accountid IS NOT NULL
  AND account.accountid IS NULL;