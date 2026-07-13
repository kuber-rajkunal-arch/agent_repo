/*
  This script contains the incremental MERGE statements to populate the Curated (Gold)
  layer tables for the Customer Single Source of Truth (SSOT) data platform.

  Instructions:
  - Replace the placeholder `<project_id>`, `<raw_dataset>`, and `<curated_dataset>`
    with your actual Google Cloud project ID and dataset names.
  - These statements are designed to be run in sequence, as there are dependencies
    for referential integrity checks (e.g., `customer` must be loaded before `lead`).
    A recommended execution order is:
      1. customer
      2. lead
      3. opportunity
      4. quote
      5. quote_detail
*/

--------------------------------------------------------------------------------
-- 1. Curated Customer Dimension
--------------------------------------------------------------------------------
MERGE `<project_id>.<curated_dataset>.customer` AS T
USING (
  SELECT
    customer_id,
    customer_type,
    name,
    company_name,
    industry,
    email,
    phone,
    website,
    address_line1,
    address_line2,
    city,
    state,
    country,
    postal_code,
    created_on,
    modified_on,
    is_active
  FROM
    `<project_id>.<raw_dataset>.stg_customer`
  WHERE
    customer_id IS NOT NULL
    -- Per TDD, this is an SCD Type 1 merge. `modified_on` is used as the watermark
    -- to capture both new records and updates to existing records, which aligns
    -- with the SCD1 requirement. The TDD note listing `created_on` as the watermark
    -- for this table would fail to capture updates and is considered a documentation error.
    AND modified_on > (
      SELECT IFNULL(MAX(modified_on), TIMESTAMP('1900-01-01 00:00:00+00'))
      FROM `<project_id>.<curated_dataset>.customer`
    )
) AS S
ON
  T.customer_id = S.customer_id
WHEN MATCHED THEN
  UPDATE SET
    T.customer_type = S.customer_type,
    T.name = S.name,
    T.company_name = S.company_name,
    T.industry = S.industry,
    T.email = S.email,
    T.phone = S.phone,
    T.website = S.website,
    T.address_line1 = S.address_line1,
    T.address_line2 = S.address_line2,
    T.city = S.city,
    T.state = S.state,
    T.country = S.country,
    T.postal_code = S.postal_code,
    T.created_on = S.created_on,
    T.modified_on = S.modified_on,
    T.is_active = S.is_active
WHEN NOT MATCHED THEN
  INSERT (
    customer_id,
    customer_type,
    name,
    company_name,
    industry,
    email,
    phone,
    website,
    address_line1,
    address_line2,
    city,
    state,
    country,
    postal_code,
    created_on,
    modified_on,
    is_active
  )
  VALUES (
    S.customer_id,
    S.customer_type,
    S.name,
    S.company_name,
    S.industry,
    S.email,
    S.phone,
    S.website,
    S.address_line1,
    S.address_line2,
    S.city,
    S.state,
    S.country,
    S.postal_code,
    S.created_on,
    S.modified_on,
    S.is_active
  );

--------------------------------------------------------------------------------
-- 2. Curated Lead Table
--------------------------------------------------------------------------------
MERGE `<project_id>.<curated_dataset>.lead` AS T
USING (
  SELECT
    lead_id,
    topic,
    first_name,
    last_name,
    company_name,
    email,
    phone,
    lead_source,
    status,
    customer_id,
    created_on,
    qualified_on,
    owner_id
  FROM
    `<project_id>.<raw_dataset>.stg_lead` AS stg
  WHERE
    stg.lead_id IS NOT NULL
    -- Incremental load based on the watermark column specified in the TDD.
    AND stg.created_on > (
      SELECT IFNULL(MAX(created_on), TIMESTAMP('1900-01-01 00:00:00+00'))
      FROM `<project_id>.<curated_dataset>.lead`
    )
    -- Referential integrity check: associated customer must exist or be NULL.
    AND (stg.customer_id IS NULL OR EXISTS (
      SELECT 1
      FROM `<project_id>.<curated_dataset>.customer` AS c
      WHERE c.customer_id = stg.customer_id
    ))
) AS S
ON
  T.lead_id = S.lead_id
WHEN MATCHED THEN
  UPDATE SET
    T.topic = S.topic,
    T.first_name = S.first_name,
    T.last_name = S.last_name,
    T.company_name = S.company_name,
    T.email = S.email,
    T.phone = S.phone,
    T.lead_source = S.lead_source,
    T.status = S.status,
    T.customer_id = S.customer_id,
    T.created_on = S.created_on,
    T.qualified_on = S.qualified_on,
    T.owner_id = S.owner_id
WHEN NOT MATCHED THEN
  INSERT (
    lead_id,
    topic,
    first_name,
    last_name,
    company_name,
    email,
    phone,
    lead_source,
    status,
    customer_id,
    created_on,
    qualified_on,
    owner_id
  )
  VALUES (
    S.lead_id,
    S.topic,
    S.first_name,
    S.last_name,
    S.company_name,
    S.email,
    S.phone,
    S.lead_source,
    S.status,
    S.customer_id,
    S.created_on,
    S.qualified_on,
    S.owner_id
  );

--------------------------------------------------------------------------------
-- 3. Curated Opportunity Table
--------------------------------------------------------------------------------
MERGE `<project_id>.<curated_dataset>.opportunity` AS T
USING (
  SELECT
    opportunity_id,
    name,
    customer_id,
    originating_lead_id,
    stage,
    status,
    estimated_value,
    probability,
    close_date,
    created_on,
    owner_id
  FROM
    `<project_id>.<raw_dataset>.stg_opportunity` AS stg
  WHERE
    stg.opportunity_id IS NOT NULL
    -- Incremental load based on the watermark column specified in the TDD.
    AND stg.created_on > (
      SELECT IFNULL(MAX(created_on), TIMESTAMP('1900-01-01 00:00:00+00'))
      FROM `<project_id>.<curated_dataset>.opportunity`
    )
    -- Referential integrity check: associated customer must exist.
    AND EXISTS (
      SELECT 1
      FROM `<project_id>.<curated_dataset>.customer` AS c
      WHERE c.customer_id = stg.customer_id
    )
    -- Referential integrity check: associated lead must exist or be NULL.
    AND (stg.originating_lead_id IS NULL OR EXISTS (
      SELECT 1
      FROM `<project_id>.<curated_dataset>.lead` AS l
      WHERE l.lead_id = stg.originating_lead_id
    ))
) AS S
ON
  T.opportunity_id = S.opportunity_id
WHEN MATCHED THEN
  UPDATE SET
    T.name = S.name,
    T.customer_id = S.customer_id,
    T.originating_lead_id = S.originating_lead_id,
    T.stage = S.stage,
    T.status = S.status,
    T.estimated_value = S.estimated_value,
    T.probability = S.probability,
    T.close_date = S.close_date,
    T.created_on = S.created_on,
    T.owner_id = S.owner_id
WHEN NOT MATCHED THEN
  INSERT (
    opportunity_id,
    name,
    customer_id,
    originating_lead_id,
    stage,
    status,
    estimated_value,
    probability,
    close_date,
    created_on,
    owner_id
  )
  VALUES (
    S.opportunity_id,
    S.name,
    S.customer_id,
    S.originating_lead_id,
    S.stage,
    S.status,
    S.estimated_value,
    S.probability,
    S.close_date,
    S.created_on,
    S.owner_id
  );

--------------------------------------------------------------------------------
-- 4. Curated Quote Table
--------------------------------------------------------------------------------
MERGE `<project_id>.<curated_dataset>.quote` AS T
USING (
  WITH
    quote_detail_agg AS (
      -- Pre-aggregate line item totals to validate against the quote header total.
      SELECT
        quote_id,
        SUM(total_amount) AS calculated_total_amount
      FROM
        `<project_id>.<raw_dataset>.stg_quote_detail`
      GROUP BY
        quote_id
    )
  SELECT
    hdr.quote_id,
    hdr.quote_number,
    hdr.opportunity_id,
    hdr.customer_id,
    hdr.status,
    hdr.total_amount,
    hdr.currency,
    hdr.valid_from,
    hdr.valid_to,
    hdr.created_on
  FROM
    `<project_id>.<raw_dataset>.stg_quote` AS hdr
    LEFT JOIN quote_detail_agg AS dtl ON hdr.quote_id = dtl.quote_id
  WHERE
    hdr.quote_id IS NOT NULL
    -- Incremental load based on the watermark column specified in the TDD.
    AND hdr.created_on > (
      SELECT IFNULL(MAX(created_on), TIMESTAMP('1900-01-01 00:00:00+00'))
      FROM `<project_id>.<curated_dataset>.quote`
    )
    -- Financial integrity check per TDD.
    AND hdr.total_amount = COALESCE(dtl.calculated_total_amount, 0)
    -- Referential integrity checks.
    AND EXISTS (
      SELECT 1
      FROM `<project_id>.<curated_dataset>.customer` AS c
      WHERE c.customer_id = hdr.customer_id
    )
    AND EXISTS (
      SELECT 1
      FROM `<project_id>.<curated_dataset>.opportunity` AS o
      WHERE o.opportunity_id = hdr.opportunity_id
    )
) AS S
ON
  T.quote_id = S.quote_id
WHEN MATCHED THEN
  UPDATE SET
    T.quote_number = S.quote_number,
    T.opportunity_id = S.opportunity_id,
    T.customer_id = S.customer_id,
    T.status = S.status,
    T.total_amount = S.total_amount,
    T.currency = S.currency,
    T.valid_from = S.valid_from,
    T.valid_to = S.valid_to,
    T.created_on = S.created_on
WHEN NOT MATCHED THEN
  INSERT (
    quote_id,
    quote_number,
    opportunity_id,
    customer_id,
    status,
    total_amount,
    currency,
    valid_from,
    valid_to,
    created_on
  )
  VALUES (
    S.quote_id,
    S.quote_number,
    S.opportunity_id,
    S.customer_id,
    S.status,
    S.total_amount,
    S.currency,
    S.valid_from,
    S.valid_to,
    S.created_on
  );

--------------------------------------------------------------------------------
-- 5. Curated Quote Detail Table
--------------------------------------------------------------------------------
MERGE `<project_id>.<curated_dataset>.quote_detail` AS T
USING (
  WITH
    valid_incremental_quotes AS (
      -- This CTE identifies the set of quotes that are part of the current
      -- incremental batch and have passed all quality checks. This ensures
      -- that we only process details for valid, loadable parent quotes.
      -- The logic is identical to the source query for the `quote` merge.
      WITH
        quote_detail_agg AS (
          SELECT
            quote_id,
            SUM(total_amount) AS calculated_total_amount
          FROM
            `<project_id>.<raw_dataset>.stg_quote_detail`
          GROUP BY
            quote_id
        )
      SELECT
        hdr.quote_id
      FROM
        `<project_id>.<raw_dataset>.stg_quote` AS hdr
        LEFT JOIN quote_detail_agg AS dtl ON hdr.quote_id = dtl.quote_id
      WHERE
        hdr.quote_id IS NOT NULL
        AND hdr.created_on > (
          SELECT IFNULL(MAX(created_on), TIMESTAMP('1900-01-01 00:00:00+00'))
          FROM `<project_id>.<curated_dataset>.quote`
        )
        AND hdr.total_amount = COALESCE(dtl.calculated_total_amount, 0)
        AND EXISTS (
          SELECT 1
          FROM `<project_id>.<curated_dataset>.customer` AS c
          WHERE c.customer_id = hdr.customer_id
        )
        AND EXISTS (
          SELECT 1
          FROM `<project_id>.<curated_dataset>.opportunity` AS o
          WHERE o.opportunity_id = hdr.opportunity_id
        )
    )
  SELECT
    dtl.quote_detail_id,
    dtl.quote_id,
    dtl.product_name,
    dtl.product_category,
    dtl.quantity,
    dtl.unit_price,
    dtl.discount,
    dtl.total_amount
  FROM
    `<project_id>.<raw_dataset>.stg_quote_detail` AS dtl
  INNER JOIN
    valid_incremental_quotes AS vq
    ON dtl.quote_id = vq.quote_id
  WHERE
    dtl.quote_detail_id IS NOT NULL
) AS S
ON
  T.quote_detail_id = S.quote_detail_id
WHEN MATCHED THEN
  UPDATE SET
    T.quote_id = S.quote_id,
    T.product_name = S.product_name,
    T.product_category = S.product_category,
    T.quantity = S.quantity,
    T.unit_price = S.unit_price,
    T.discount = S.discount,
    T.total_amount = S.total_amount
WHEN NOT MATCHED THEN
  INSERT (
    quote_detail_id,
    quote_id,
    product_name,
    product_category,
    quantity,
    unit_price,
    discount,
    total_amount
  )
  VALUES (
    S.quote_detail_id,
    S.quote_id,
    S.product_name,
    S.product_category,
    S.quantity,
    S.unit_price,
    S.discount,
    S.total_amount
  );
