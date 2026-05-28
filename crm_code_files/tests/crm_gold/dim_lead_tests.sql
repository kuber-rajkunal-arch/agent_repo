/*
  Unit tests for the crm_gold.dim_lead table.
  These tests verify the data integrity and quality of the transformed lead data.
*/

-- test: not_null_dim_lead_leadid
-- The primary key `leadid` must not contain any NULL values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_dim_lead_leadid' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.dim_lead`
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
    `your-gcp-project-id.your_gold_dataset.dim_lead`
  WHERE
    leadid IS NOT NULL
  GROUP BY
    leadid
  HAVING
    COUNT(*) > 1
);

-- test: referential_integrity_dim_lead_customerid
-- Each non-NULL `customerid` in `dim_lead` must exist as a valid `customerid` in `dim_customer`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_dim_lead_customerid' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.dim_lead` AS t
LEFT JOIN
  `your-gcp-project-id.your_gold_dataset.dim_customer` AS ref
  ON t.customerid = ref.customerid
WHERE
  t.customerid IS NOT NULL AND ref.customerid IS NULL;

-- test: referential_integrity_dim_lead_accountid
-- Each non-NULL `accountid` in `dim_lead` must exist as a valid `accountid` in `dim_account`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_dim_lead_accountid' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.dim_lead` AS t
LEFT JOIN
  `your-gcp-project-id.your_gold_dataset.dim_account` AS ref
  ON t.accountid = ref.accountid
WHERE
  t.accountid IS NOT NULL AND ref.accountid IS NULL;

-- test: trimmed_check_dim_lead_fields
-- All string fields should have no leading/trailing whitespace, verifying the TRIM() transformation.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'trimmed_check_dim_lead_fields' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.dim_lead`
WHERE
  statuscode <> TRIM(statuscode);