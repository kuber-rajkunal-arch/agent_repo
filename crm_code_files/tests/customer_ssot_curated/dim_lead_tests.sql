/*
  Unit tests for the curated.dim_lead table.
  These tests verify the data integrity and quality of the transformed lead data.
*/

-- test: not_null_dim_lead_leadid
-- The primary key `leadid` must not contain any NULL values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_dim_lead_leadid' AS test_name
FROM
  `your-gcp-project-id.curated_dataset.dim_lead`
WHERE
  leadid IS NULL;

-- test: unique_dim_lead_leadid
-- The primary key `leadid` must be unique across all records.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_dim_lead_leadid' AS test_name
FROM (
  SELECT
    leadid
  FROM
    `your-gcp-project-id.curated_dataset.dim_lead`
  WHERE
    leadid IS NOT NULL
  GROUP BY
    leadid
  HAVING
    COUNT(*) > 1
);

-- test: referential_integrity_dim_lead_foreign_keys
-- All foreign keys in `dim_lead` must have a corresponding entry in their respective dimension tables.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_dim_lead_foreign_keys' AS test_name
FROM
(
  SELECT 'customerid' AS fk_column FROM `your-gcp-project-id.curated_dataset.dim_lead` t LEFT JOIN `your-gcp-project-id.curated_dataset.dim_customer` r ON t.customerid = r.customerid WHERE t.customerid IS NOT NULL AND r.customerid IS NULL
  UNION ALL
  SELECT 'accountid' AS fk_column FROM `your-gcp-project-id.curated_dataset.dim_lead` t LEFT JOIN `your-gcp-project-id.curated_dataset.dim_account` r ON t.accountid = r.accountid WHERE t.accountid IS NOT NULL AND r.accountid IS NULL
);

-- test: trimmed_check_dim_lead_statuscode
-- The `statuscode` field should have no leading/trailing whitespace, verifying the TRIM() transformation.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'trimmed_check_dim_lead_statuscode' AS test_name
FROM
  `your-gcp-project-id.curated_dataset.dim_lead`
WHERE
  statuscode <> TRIM(statuscode);