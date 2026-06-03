-- ============================================================================
-- Unit Tests for `dim_sales_rep`
-- ============================================================================

-- test: not_null_salesrepid
-- The primary key `salesrepid` must be populated for every record.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_salesrepid' AS test_name,
  'The primary key `salesrepid` must be populated for every record.' AS description
FROM `your_project_id.curated_dataset.dim_sales_rep`
WHERE salesrepid IS NULL;

-- test: unique_salesrepid
-- The primary key `salesrepid` must be unique across the table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_salesrepid' AS test_name,
  'The primary key `salesrepid` must be unique across the table.' AS description
FROM (
  SELECT
    salesrepid
  FROM `your_project_id.curated_dataset.dim_sales_rep`
  WHERE salesrepid IS NOT NULL
  GROUP BY 1
  HAVING COUNT(*) > 1
);

-- test: not_null_name
-- The sales rep `name` is a critical business identifier and should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_name' AS test_name,
  'The sales rep `name` should always be populated.' AS description
FROM `your_project_id.curated_dataset.dim_sales_rep`
WHERE name IS NULL;