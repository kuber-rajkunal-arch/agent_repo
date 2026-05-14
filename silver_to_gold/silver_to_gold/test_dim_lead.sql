-- =============================================================================
-- Unit Tests for `curated_dataset.dim_lead`
-- =============================================================================

-- test: not_null_leadid
-- Ensures that the primary key `leadid` is never null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_leadid' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_lead`
WHERE
  leadid IS NULL;

-- test: unique_leadid
-- Ensures that the primary key `leadid` is unique across the table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_leadid' AS test_name
FROM (
  SELECT
    leadid,
    COUNT(*) AS id_count
  FROM
    `gcp-cloud-source-repo.curated_dataset.dim_lead`
  WHERE
    leadid IS NOT NULL
  GROUP BY
    leadid
  HAVING
    id_count > 1
);

-- test: not_null_statuscode
-- The lead status is a critical business field and should not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_statuscode' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_lead`
WHERE
  statuscode IS NULL;

-- test: not_null_createdon
-- The creation date is critical. A null value may indicate a failed SAFE_CAST from source.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_createdon' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_lead`
WHERE
  createdon IS NULL;

-- test: referential_integrity_customerid
-- Ensures that every `customerid` in `dim_lead` exists in `dim_customer`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customerid' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_lead` AS t
LEFT JOIN
  `gcp-cloud-source-repo.curated_dataset.dim_customer` AS ref
ON
  t.customerid = ref.customerid
WHERE
  t.customerid IS NOT NULL AND ref.customerid IS NULL;

-- test: referential_integrity_accountid
-- Ensures that every `accountid` in `dim_lead` exists in `dim_account`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_accountid' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_lead` AS t
LEFT JOIN
  `gcp-cloud-source-repo.curated_dataset.dim_account` AS ref
ON
  t.accountid = ref.accountid
WHERE
  t.accountid IS NOT NULL AND ref.accountid IS NULL;