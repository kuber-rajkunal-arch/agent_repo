-- ===================================================================================
--
-- Description: This file contains unit tests for the customer_ssot.sql script.
--              The tests validate the data quality and integrity checks
--              performed on the staging tables before the MERGE operations.
--
-- Test Target: crm_code_files_repo/generated_code/customer_ssot.sql
--
-- ===================================================================================

-- -----------------------------------------------------------------------------------
-- Tests for `customer` table logic
-- -----------------------------------------------------------------------------------

-- test: customer_pk_not_null
-- Description: Ensures that all records in the staging customer table that are
--              candidates for loading have a non-null primary key.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'customer_pk_not_null' AS test_name
FROM
  `{{ project_id }}.{{ raw_dataset }}.stg_customer`
WHERE
  customer_id IS NULL;

-- -----------------------------------------------------------------------------------
-- Tests for `lead` table logic
-- -----------------------------------------------------------------------------------

-- test: lead_pk_not_null
-- Description: Ensures all candidate lead records have a non-null primary key.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'lead_pk_not_null' AS test_name
FROM
  `{{ project_id }}.{{ raw_dataset }}.stg_lead`
WHERE
  lead_id IS NULL;

-- test: lead_fk_customer_referential_integrity
-- Description: Validates that any non-null `customer_id` in `stg_lead` corresponds
--              to an existing `customer_id` in the `stg_customer` batch.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'lead_fk_customer_referential_integrity' AS test_name
FROM
  `{{ project_id }}.{{ raw_dataset }}.stg_lead` AS s
LEFT JOIN
  `{{ project_id }}.{{ raw_dataset }}.stg_customer` AS c ON s.customer_id = c.customer_id
WHERE
  s.customer_id IS NOT NULL AND c.customer_id IS NULL;

-- -----------------------------------------------------------------------------------
-- Tests for `opportunity` table logic
-- -----------------------------------------------------------------------------------

-- test: opportunity_pk_not_null
-- Description: Ensures all candidate opportunity records have a non-null primary key.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_pk_not_null' AS test_name
FROM
  `{{ project_id }}.{{ raw_dataset }}.stg_opportunity`
WHERE
  opportunity_id IS NULL;

-- test: opportunity_fk_customer_not_null
-- Description: Ensures all candidate opportunity records have a non-null `customer_id`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_fk_customer_not_null' AS test_name
FROM
  `{{ project_id }}.{{ raw_dataset }}.stg_opportunity`
WHERE
  customer_id IS NULL;

-- test: opportunity_fk_customer_referential_integrity
-- Description: Validates that the `customer_id` in `stg_opportunity` corresponds
--              to an existing `customer_id` in the `stg_customer` batch.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_fk_customer_referential_integrity' AS test_name
FROM
  `{{ project_id }}.{{ raw_dataset }}.stg_opportunity` AS s
LEFT JOIN
  `{{ project_id }}.{{ raw_dataset }}.stg_customer` AS c ON s.customer_id = c.customer_id
WHERE
  s.customer_id IS NOT NULL AND c.customer_id IS NULL;

-- test: opportunity_fk_lead_referential_integrity
-- Description: Validates that any non-null `originating_lead_id` in `stg_opportunity`
--              corresponds to an existing `lead_id` in the `stg_lead` batch.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'opportunity_fk_lead_referential_integrity' AS test_name
FROM
  `{{ project_id }}.{{ raw_dataset }}.stg_opportunity` AS s
LEFT JOIN
  `{{ project_id }}.{{ raw_dataset }}.stg_lead` AS l ON s.originating_lead_id = l.lead_id
WHERE
  s.originating_lead_id IS NOT NULL AND l.lead_id IS NULL;

-- -----------------------------------------------------------------------------------
-- Tests for `quote_detail` table logic
-- -----------------------------------------------------------------------------------

-- test: quote_detail_pk_not_null
-- Description: Ensures all candidate quote detail records have a non-null primary key.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_pk_not_null' AS test_name
FROM
  `{{ project_id }}.{{ raw_dataset }}.stg_quote_detail`
WHERE
  quote_detail_id IS NULL;

-- test: quote_detail_fk_quote_not_null
-- Description: Ensures all candidate quote detail records have a non-null `quote_id`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_detail_fk_quote_not_null' AS test_name
FROM
  `{{ project_id }}.{{ raw_dataset }}.stg_quote_detail`
WHERE
  quote_id IS NULL;

-- -----------------------------------------------------------------------------------
-- Tests for `quote` table logic
-- -----------------------------------------------------------------------------------

-- test: quote_pk_not_null
-- Description: Ensures all candidate quote records have a non-null primary key.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_pk_not_null' AS test_name
FROM
  `{{ project_id }}.{{ raw_dataset }}.stg_quote`
WHERE
  quote_id IS NULL;

-- test: quote_fk_opportunity_not_null
-- Description: Ensures all candidate quote records have a non-null `opportunity_id`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_fk_opportunity_not_null' AS test_name
FROM
  `{{ project_id }}.{{ raw_dataset }}.stg_quote`
WHERE
  opportunity_id IS NULL;

-- test: quote_fk_customer_not_null
-- Description: Ensures all candidate quote records have a non-null `customer_id`.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_fk_customer_not_null' AS test_name
FROM
  `{{ project_id }}.{{ raw_dataset }}.stg_quote`
WHERE
  customer_id IS NULL;

-- test: quote_fk_customer_referential_integrity
-- Description: Validates that the `customer_id` in `stg_quote` corresponds to an
--              existing `customer_id` in the `stg_customer` batch.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_fk_customer_referential_integrity' AS test_name
FROM
  `{{ project_id }}.{{ raw_dataset }}.stg_quote` AS s
LEFT JOIN
  `{{ project_id }}.{{ raw_dataset }}.stg_customer` AS c ON s.customer_id = c.customer_id
WHERE
  s.customer_id IS NOT NULL AND c.customer_id IS NULL;

-- test: quote_fk_opportunity_referential_integrity
-- Description: Validates that the `opportunity_id` in `stg_quote` corresponds to an
--              existing `opportunity_id` in the `stg_opportunity` batch.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_fk_opportunity_referential_integrity' AS test_name
FROM
  `{{ project_id }}.{{ raw_dataset }}.stg_quote` AS s
LEFT JOIN
  `{{ project_id }}.{{ raw_dataset }}.stg_opportunity` AS o ON s.opportunity_id = o.opportunity_id
WHERE
  s.opportunity_id IS NOT NULL AND o.opportunity_id IS NULL;

-- test: quote_financial_integrity_header_vs_details
-- Description: Checks for financial integrity between the quote header and its details.
--              A quote is invalid if its `total_amount` does not match the sum of
--              its `stg_quote_detail` line item totals, or if it has no details.
WITH
  quote_details_agg AS (
    -- Aggregate line item totals for financial validation.
    SELECT
      quote_id,
      SUM(total_amount) AS calculated_total_amount
    FROM
      `{{ project_id }}.{{ raw_dataset }}.stg_quote_detail`
    WHERE
      quote_id IS NOT NULL
    GROUP BY
      quote_id
  )
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'quote_financial_integrity_header_vs_details' AS test_name
FROM
  `{{ project_id }}.{{ raw_dataset }}.stg_quote` AS s
-- LEFT JOIN finds headers that either have no details or have mismatched totals.
-- The main query's INNER JOIN would filter these out, so this test finds records
-- that would be rejected.
LEFT JOIN
  quote_details_agg AS qd
  ON s.quote_id = qd.quote_id
WHERE
  -- A quote fails validation if:
  -- 1. It has no corresponding details in the staging batch (qd.quote_id IS NULL).
  -- 2. The header total does not match the sum of its detail lines.
  qd.quote_id IS NULL
  OR SAFE.ROUND(s.total_amount, 2) != SAFE.ROUND(qd.calculated_total_amount, 2);
