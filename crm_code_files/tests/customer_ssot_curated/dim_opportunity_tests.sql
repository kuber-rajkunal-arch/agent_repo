/*
  Unit tests for the curated.dim_opportunity table.
  These tests verify the data integrity and quality of the transformed opportunity data.
*/

-- test: not_null_dim_opportunity_opportunityid
-- The primary key `opportunityid` must not contain any NULL values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_dim_opportunity_opportunityid' AS test_name
FROM
  `your-gcp-project-id.curated_dataset.dim_opportunity`
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
    `your-gcp-project-id.curated_dataset.dim_opportunity`
  WHERE
    opportunityid IS NOT NULL
  GROUP BY
    opportunityid
  HAVING
    COUNT(*) > 1
);

-- test: referential_integrity_dim_opportunity_foreign_keys
-- All foreign keys in `dim_opportunity` must have a corresponding entry in their respective dimension tables.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_dim_opportunity_foreign_keys' AS test_name
FROM
(
  SELECT 'leadid' AS fk_column FROM `your-gcp-project-id.curated_dataset.dim_opportunity` t LEFT JOIN `your-gcp-project-id.curated_dataset.dim_lead` r ON t.leadid = r.leadid WHERE t.leadid IS NOT NULL AND r.leadid IS NULL
  UNION ALL
  SELECT 'customerid' AS fk_column FROM `your-gcp-project-id.curated_dataset.dim_opportunity` t LEFT JOIN `your-gcp-project-id.curated_dataset.dim_customer` r ON t.customerid = r.customerid WHERE t.customerid IS NOT NULL AND r.customerid IS NULL
  UNION ALL
  SELECT 'accountid' AS fk_column FROM `your-gcp-project-id.curated_dataset.dim_opportunity` t LEFT JOIN `your-gcp-project-id.curated_dataset.dim_account` r ON t.accountid = r.accountid WHERE t.accountid IS NOT NULL AND r.accountid IS NULL
  UNION ALL
  SELECT 'salesrepid' AS fk_column FROM `your-gcp-project-id.curated_dataset.dim_opportunity` t LEFT JOIN `your-gcp-project-id.curated_dataset.dim_sales_rep` r ON t.salesrepid = r.salesrepid WHERE t.salesrepid IS NOT NULL AND r.salesrepid IS NULL
);

-- test: range_check_dim_opportunity_estimatedvalue
-- The estimated value of an opportunity should not be negative. This verifies the SAFE_CAST and source data quality.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_dim_opportunity_estimatedvalue' AS test_name
FROM
  `your-gcp-project-id.curated_dataset.dim_opportunity`
WHERE
  estimatedvalue < 0;

-- test: trimmed_check_dim_opportunity_fields
-- All string fields should have no leading/trailing whitespace, verifying the TRIM() transformation.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'trimmed_check_dim_opportunity_fields' AS test_name
FROM
  `your-gcp-project-id.curated_dataset.dim_opportunity`
WHERE
  statuscode <> TRIM(statuscode)
  OR currencycode <> TRIM(currencycode);