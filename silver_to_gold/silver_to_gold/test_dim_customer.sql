-- =============================================================================
-- Unit Tests for `curated_dataset.dim_customer`
-- =============================================================================

-- test: not_null_customerid
-- Ensures that the primary key `customerid` is never null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_customerid' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_customer`
WHERE
  customerid IS NULL;

-- test: unique_customerid
-- Ensures that the primary key `customerid` is unique across the table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_customerid' AS test_name
FROM (
  SELECT
    customerid,
    COUNT(*) AS id_count
  FROM
    `gcp-cloud-source-repo.curated_dataset.dim_customer`
  WHERE
    customerid IS NOT NULL
  GROUP BY
    customerid
  HAVING
    id_count > 1
);

-- test: not_null_name
-- The customer name is a critical business field and should not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_name' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_customer`
WHERE
  name IS NULL;

-- test: referential_integrity_accountid
-- Ensures that every `accountid` in `dim_customer` exists in `dim_account`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_accountid' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_customer` AS t
LEFT JOIN
  `gcp-cloud-source-repo.curated_dataset.dim_account` AS ref
ON
  t.accountid = ref.accountid
WHERE
  t.accountid IS NOT NULL AND ref.accountid IS NULL;