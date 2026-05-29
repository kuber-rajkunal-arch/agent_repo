-- File: tests/customer_ssot/test_fact_quotes.sql
-- Description: Unit tests for the curated fact_quotes table.

-- test: not_null_quoteid
-- Ensures the primary key column `quoteid` is never NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quoteid' AS test_name
FROM
  `${project_id}.${curated_dataset}.fact_quotes`
WHERE
  quoteid IS NULL;

-- test: unique_quoteid
-- Ensures that every `quoteid` is unique.
SELECT
  IF(COUNT(quoteid) = COUNT(DISTINCT quoteid), 'PASS', 'FAIL') AS result,
  'unique_quoteid' AS test_name
FROM
  `${project_id}.${curated_dataset}.fact_quotes`;

-- test: not_null_totalamount
-- Verifies that the SAFE_CAST on `totalamount` did not result in unexpected NULLs.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_totalamount' AS test_name
FROM
  `${project_id}.${curated_dataset}.fact_quotes`
WHERE
  totalamount IS NULL;

-- test: referential_integrity_opportunityid
-- Verifies that every `opportunityid` in fact_quotes exists in the dim_opportunity table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_opportunityid' AS test_name
FROM (
  SELECT
    fq.opportunityid
  FROM
    `${project_id}.${curated_dataset}.fact_quotes` AS fq
  LEFT JOIN
    `${project_id}.${curated_dataset}.dim_opportunity` AS opp
    ON fq.opportunityid = opp.opportunityid
  WHERE
    opp.opportunityid IS NULL
    AND fq.opportunityid IS NOT NULL
);