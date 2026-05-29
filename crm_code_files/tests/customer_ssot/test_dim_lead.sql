-- File: tests/customer_ssot/test_dim_lead.sql
-- Description: Unit tests for the curated dim_lead table.

-- test: not_null_leadid
-- Ensures the primary key column `leadid` in dim_lead is never NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_leadid' AS test_name
FROM
  `${project_id}.${curated_dataset}.dim_lead`
WHERE
  leadid IS NULL;

-- test: unique_leadid
-- Ensures that every `leadid` in dim_lead is unique.
SELECT
  IF(COUNT(leadid) = COUNT(DISTINCT leadid), 'PASS', 'FAIL') AS result,
  'unique_leadid' AS test_name
FROM
  `${project_id}.${curated_dataset}.dim_lead`;

-- test: not_null_createdon
-- The `createdon` date is critical for tracking lead age. This test verifies that the SAFE_CAST did not result in unexpected NULLs.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_createdon' AS test_name
FROM
  `${project_id}.${curated_dataset}.dim_lead`
WHERE
  createdon IS NULL;