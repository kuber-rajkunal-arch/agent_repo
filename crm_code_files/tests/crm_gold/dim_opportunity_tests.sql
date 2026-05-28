/*
  Unit tests for the crm_gold.dim_opportunity table.
  These tests verify the data integrity and quality of the transformed opportunity data.
*/

-- test: not_null_dim_opportunity_opportunityid
-- The primary key `opportunityid` must not contain any NULL values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_dim_opportunity_opportunityid' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.dim_opportunity`
WHERE
  opportunityid IS NULL;

-- test: unique_dim_opportunity_opportunityid
-- The primary key `opportunityid` must be unique across all records.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_dim_opportunity_opportunityid' AS test_name
FROM (
  SELECT
    opportunityid
  FROM
    `your-gcp-project-id.your_gold_dataset.dim_opportunity`
  WHERE
    opportunityid IS NOT NULL
  GROUP BY
    opportunityid
  HAVING
    COUNT(*) > 1
);

-- test: referential_integrity_dim_opportunity_leadid
-- Each non-NULL `leadid` must exist in `dim_lead`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_dim_opportunity_leadid' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.dim_opportunity` AS t
LEFT JOIN
  `your-gcp-project-id.your_gold_dataset.dim_lead` AS ref
  ON t.leadid = ref.leadid
WHERE
  t.leadid IS NOT NULL AND ref.leadid IS NULL;

-- test: referential_integrity_dim_opportunity_customerid
-- Each non-NULL `customerid` must exist in `dim_customer`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_dim_opportunity_customerid' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.dim_opportunity` AS t
LEFT JOIN
  `your-gcp-project-id.your_gold_dataset.dim_customer` AS ref
  ON t.customerid = ref.customerid
WHERE
  t.customerid IS NOT NULL AND ref.customerid IS NULL;

-- test: referential_integrity_dim_opportunity_accountid
-- Each non-NULL `accountid` must exist in `dim_account`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_dim_opportunity_accountid' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.dim_opportunity` AS t
LEFT JOIN
  `your-gcp-project-id.your_gold_dataset.dim_account` AS ref
  ON t.accountid = ref.accountid
WHERE
  t.accountid IS NOT NULL AND ref.accountid IS NULL;

-- test: referential_integrity_dim_opportunity_salesrepid
-- Each non-NULL `salesrepid` must exist in `dim_sales_rep`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_dim_opportunity_salesrepid' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.dim_opportunity` AS t
LEFT JOIN
  `your-gcp-project-id.your_gold_dataset.dim_sales_rep` AS ref
  ON t.salesrepid = ref.salesrepid
WHERE
  t.salesrepid IS NOT NULL AND ref.salesrepid IS NULL;

-- test: range_check_dim_opportunity_estimatedvalue
-- The estimated value of an opportunity should not be negative. This verifies the SAFE_CAST and source data quality.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_dim_opportunity_estimatedvalue' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.dim_opportunity`
WHERE
  estimatedvalue < 0;

-- test: trimmed_check_dim_opportunity_fields
-- All string fields should have no leading/trailing whitespace, verifying the TRIM() transformation.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'trimmed_check_dim_opportunity_fields' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.dim_opportunity`
WHERE
  statuscode <> TRIM(statuscode)
  OR currencycode <> TRIM(currencycode);