-- =============================================================================
-- Unit Tests for `curated_dataset.dim_sales_rep`
-- =============================================================================

-- test: not_null_salesrepid
-- Ensures that the primary key `salesrepid` is never null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_salesrepid' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_sales_rep`
WHERE
  salesrepid IS NULL;

-- test: unique_salesrepid
-- Ensures that the primary key `salesrepid` is unique across the table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_salesrepid' AS test_name
FROM (
  SELECT
    salesrepid,
    COUNT(*) AS id_count
  FROM
    `gcp-cloud-source-repo.curated_dataset.dim_sales_rep`
  WHERE
    salesrepid IS NOT NULL
  GROUP BY
    salesrepid
  HAVING
    id_count > 1
);

-- test: not_null_name
-- The sales rep name is a critical business field and should not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_name' AS test_name
FROM
  `gcp-cloud-source-repo.curated_dataset.dim_sales_rep`
WHERE
  name IS NULL;