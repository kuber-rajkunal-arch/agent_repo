-- =============================================================================
-- Unit Tests for `curated_dataset.dim_opportunity`
-- =============================================================================

-- test: not_null_opportunityid
-- Ensures that the primary key `opportunityid` is never null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_opportunityid' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_opportunity`
WHERE
  opportunityid IS NULL;

-- test: unique_opportunityid
-- Ensures that the primary key `opportunityid` is unique across the table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_opportunityid' AS test_name
FROM (
  SELECT
    opportunityid,
    COUNT(*) AS id_count
  FROM
    `gcp-cloud-source-repo.curated_dataset.dim_opportunity`
  WHERE
    opportunityid IS NOT NULL
  GROUP BY
    opportunityid
  HAVING
    id_count > 1
);

-- test: not_null_statuscode
-- The opportunity status is a critical business field and should not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_statuscode' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_opportunity`
WHERE
  statuscode IS NULL;

-- test: not_null_createdon
-- The creation date is critical. A null value may indicate a failed SAFE_CAST from source.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_createdon' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_opportunity`
WHERE
  createdon IS NULL;

-- test: non_negative_estimatedvalue
-- The estimated value of an opportunity should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'non_negative_estimatedvalue' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_opportunity`
WHERE
  estimatedvalue < 0;

-- test: referential_integrity_leadid
-- Ensures that every `leadid` in `dim_opportunity` exists in `dim_lead`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_leadid' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_opportunity` AS t
LEFT JOIN
  `gcp-cloud-source-repo.curated_dataset.dim_lead` AS ref
ON
  t.leadid = ref.leadid
WHERE
  t.leadid IS NOT NULL AND ref.leadid IS NULL;

-- test: referential_integrity_customerid
-- Ensures that every `customerid` in `dim_opportunity` exists in `dim_customer`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customerid' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_opportunity` AS t
LEFT JOIN
  `gcp-cloud-source-repo.curated_dataset.dim_customer` AS ref
ON
  t.customerid = ref.customerid
WHERE
  t.customerid IS NOT NULL AND ref.customerid IS NULL;

-- test: referential_integrity_accountid
-- Ensures that every `accountid` in `dim_opportunity` exists in `dim_account`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_accountid' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_opportunity` AS t
LEFT JOIN
  `gcp-cloud-source-repo.curated_dataset.dim_account` AS ref
ON
  t.accountid = ref.accountid
WHERE
  t.accountid IS NOT NULL AND ref.accountid IS NULL;

-- test: referential_integrity_salesrepid
-- Ensures that every `salesrepid` in `dim_opportunity` exists in `dim_sales_rep`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_salesrepid' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_opportunity` AS t
LEFT JOIN
  `gcp-cloud-source-repo.curated_dataset.dim_sales_rep` AS ref
ON
  t.salesrepid = ref.salesrepid
WHERE
  t.salesrepid IS NOT NULL AND ref.salesrepid IS NULL;