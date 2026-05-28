/*
  Unit tests for the crm_gold.fact_quotes table.
  These tests verify the data integrity and quality of the transformed quotes data.
*/

-- test: not_null_fact_quotes_quoteid
-- The primary key `quoteid` must not contain any NULL values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_fact_quotes_quoteid' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.fact_quotes`
WHERE
  quoteid IS NULL;

-- test: unique_fact_quotes_quoteid
-- The primary key `quoteid` must be unique across all records.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'unique_fact_quotes_quoteid' AS test_name
FROM (
  SELECT
    quoteid
  FROM
    `your-gcp-project-id.your_gold_dataset.fact_quotes`
  WHERE
    quoteid IS NOT NULL
  GROUP BY
    quoteid
  HAVING
    COUNT(*) > 1
);

-- test: referential_integrity_fact_quotes_foreign_keys
-- All foreign keys in `fact_quotes` must have a corresponding entry in their respective dimension tables.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_fact_quotes_foreign_keys' AS test_name
FROM
(
  SELECT 'opportunityid' AS fk_column FROM `your-gcp-project-id.your_gold_dataset.fact_quotes` t LEFT JOIN `your-gcp-project-id.your_gold_dataset.dim_opportunity` r ON t.opportunityid = r.opportunityid WHERE t.opportunityid IS NOT NULL AND r.opportunityid IS NULL
  UNION ALL
  SELECT 'customerid' AS fk_column FROM `your-gcp-project-id.your_gold_dataset.fact_quotes` t LEFT JOIN `your-gcp-project-id.your_gold_dataset.dim_customer` r ON t.customerid = r.customerid WHERE t.customerid IS NOT NULL AND r.customerid IS NULL
  UNION ALL
  SELECT 'accountid' AS fk_column FROM `your-gcp-project-id.your_gold_dataset.fact_quotes` t LEFT JOIN `your-gcp-project-id.your_gold_dataset.dim_account` r ON t.accountid = r.accountid WHERE t.accountid IS NOT NULL AND r.accountid IS NULL
  UNION ALL
  SELECT 'salesrepid' AS fk_column FROM `your-gcp-project-id.your_gold_dataset.fact_quotes` t LEFT JOIN `your-gcp-project-id.your_gold_dataset.dim_sales_rep` r ON t.salesrepid = r.salesrepid WHERE t.salesrepid IS NOT NULL AND r.salesrepid IS NULL
);

-- test: range_check_fact_quotes_totalamount
-- The total amount of a quote should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_fact_quotes_totalamount' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.fact_quotes`
WHERE
  totalamount < 0;

-- test: not_null_fact_quotes_createdon
-- The partitioning key `createdon` should not be NULL, as it's critical for table performance and management.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_fact_quotes_createdon' AS test_name
FROM
  `your-gcp-project-id.your_gold_dataset.fact_quotes`
WHERE
  createdon IS NULL;