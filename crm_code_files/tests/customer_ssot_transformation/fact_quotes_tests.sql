-- Tests for crm_raw_data_gold.fact_quotes

-- test: not_null_fact_quotes_quoteid
-- The primary key `quoteid` must not contain any NULL values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_fact_quotes_quoteid' AS test_name
FROM
  `gcp-cloud-source-repo.crm_raw_data_gold.fact_quotes`
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
    `gcp-cloud-source-repo.crm_raw_data_gold.fact_quotes`
  WHERE
    quoteid IS NOT NULL
  GROUP BY
    quoteid
  HAVING
    COUNT(*) > 1
);

-- test: referential_integrity_fact_quotes_opportunityid
-- Each non-NULL `opportunityid` must exist in `dim_opportunity`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_fact_quotes_opportunityid' AS test_name
FROM
  `gcp-cloud-source-repo.crm_raw_data_gold.fact_quotes` AS t
LEFT JOIN
  `gcp-cloud-source-repo.crm_raw_data_gold.dim_opportunity` AS ref
  ON t.opportunityid = ref.opportunityid
WHERE
  t.opportunityid IS NOT NULL AND ref.opportunityid IS NULL;

-- test: range_check_fact_quotes_totalamount
-- The total amount of a quote should not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_fact_quotes_totalamount' AS test_name
FROM
  `gcp-cloud-source-repo.crm_raw_data_gold.fact_quotes`
WHERE
  totalamount < 0;