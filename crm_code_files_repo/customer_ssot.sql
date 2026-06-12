-- ===================================================================================
--
-- Description: This script populates the curated Customer SSOT tables (customer,
--              lead, opportunity, quote, quote_detail) from the corresponding
--              staging tables. It implements an SCD Type 1 incremental load
--              pattern using MERGE statements.
--
--              Data quality and integrity checks are performed before loading,
--              including:
--              - Not-null checks on primary keys.
--              - Uniqueness checks within the source batch.
--              - Referential integrity checks against other entities in the batch.
--              - Financial integrity checks (e.g., quote header vs. detail totals).
--
-- Source Tables:
--              - `{{ project_id }}.{{ raw_dataset }}.stg_customer`
--              - `{{ project_id }}.{{ raw_dataset }}.stg_lead`
--              - `{{ project_id }}.{{ raw_dataset }}.stg_opportunity`
--              - `{{ project_id }}.{{ raw_dataset }}.stg_quote`
--              - `{{ project_id }}.{{ raw_dataset }}.stg_quote_detail`
--
-- Target Tables:
--              - `{{ project_id }}.{{ curated_dataset }}.customer`
--              - `{{ project_id }}.{{ curated_dataset }}.lead`
--              - `{{ project_id }}.{{ curated_dataset }}.opportunity`
--              - `{{ project_id }}.{{ curated_dataset }}.quote`
--              - `{{ project_id }}.{{ curated_dataset }}.quote_detail`
--
-- ===================================================================================

-- -----------------------------------------------------------------------------------
-- MERGE into customer
-- -----------------------------------------------------------------------------------
MERGE `{{ project_id }}.{{ curated_dataset }}.customer` AS Target
USING (
  -- Select and de-duplicate source data, keeping the most recently modified record.
  SELECT
    * EXCEPT(rn)
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY modified_on DESC) AS rn
    FROM
      `{{ project_id }}.{{ raw_dataset }}.stg_customer`
    WHERE
      -- Primary key must not be null.
      customer_id IS NOT NULL
  )
  WHERE
    rn = 1
) AS Source
ON
  Target.customer_id = Source.customer_id
WHEN MATCHED THEN
  -- SCD Type 1: Update existing records with the latest data.
  UPDATE SET
    Target.customer_type = Source.customer_type,
    Target.name = Source.name,
    Target.company_name = Source.company_name,
    Target.industry = Source.industry,
    Target.email = Source.email,
    Target.phone = Source.phone,
    Target.website = Source.website,
    Target.address_line1 = Source.address_line1,
    Target.address_line2 = Source.address_line2,
    Target.city = Source.city,
    Target.state = Source.state,
    Target.country = Source.country,
    Target.postal_code = Source.postal_code,
    Target.created_on = Source.created_on,
    Target.modified_on = Source.modified_on,
    Target.is_active = Source.is_active
WHEN NOT MATCHED THEN
  -- Insert new records.
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
    Source.customer_id,
    Source.customer_type,
    Source.name,
    Source.company_name,
    Source.industry,
    Source.email,
    Source.phone,
    Source.website,
    Source.address_line1,
    Source.address_line2,
    Source.city,
    Source.state,
    Source.country,
    Source.postal_code,
    Source.created_on,
    Source.modified_on,
    Source.is_active
  );

-- -----------------------------------------------------------------------------------
-- MERGE into lead
-- -----------------------------------------------------------------------------------
MERGE `{{ project_id }}.{{ curated_dataset }}.lead` AS Target
USING (
  -- Select, de-duplicate, and validate source data.
  SELECT
    s.* EXCEPT(rn)
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER(PARTITION BY lead_id ORDER BY created_on DESC) AS rn
    FROM
      `{{ project_id }}.{{ raw_dataset }}.stg_lead`
    WHERE
      -- Primary key must not be null.
      lead_id IS NOT NULL
  ) AS s
  -- Referential integrity check: if customer_id exists, it must be a valid customer in the source batch.
  LEFT JOIN `{{ project_id }}.{{ raw_dataset }}.stg_customer` AS c
    ON s.customer_id = c.customer_id
  WHERE
    s.rn = 1
    AND (s.customer_id IS NULL OR c.customer_id IS NOT NULL)
) AS Source
ON
  Target.lead_id = Source.lead_id
WHEN MATCHED THEN
  -- SCD Type 1: Update existing records.
  UPDATE SET
    Target.topic = Source.topic,
    Target.first_name = Source.first_name,
    Target.last_name = Source.last_name,
    Target.company_name = Source.company_name,
    Target.email = Source.email,
    Target.phone = Source.phone,
    Target.lead_source = Source.lead_source,
    Target.status = Source.status,
    Target.customer_id = Source.customer_id,
    Target.created_on = Source.created_on,
    Target.qualified_on = Source.qualified_on,
    Target.owner_id = Source.owner_id
WHEN NOT MATCHED THEN
  -- Insert new records.
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
    Source.lead_id,
    Source.topic,
    Source.first_name,
    Source.last_name,
    Source.company_name,
    Source.email,
    Source.phone,
    Source.lead_source,
    Source.status,
    Source.customer_id,
    Source.created_on,
    Source.qualified_on,
    Source.owner_id
  );

-- -----------------------------------------------------------------------------------
-- MERGE into opportunity
-- -----------------------------------------------------------------------------------
MERGE `{{ project_id }}.{{ curated_dataset }}.opportunity` AS Target
USING (
  -- Select, de-duplicate, and validate source data.
  SELECT
    s.* EXCEPT(rn)
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER(PARTITION BY opportunity_id ORDER BY created_on DESC) AS rn
    FROM
      `{{ project_id }}.{{ raw_dataset }}.stg_opportunity`
    WHERE
      -- Primary key and required foreign keys must not be null.
      opportunity_id IS NOT NULL
      AND customer_id IS NOT NULL
  ) AS s
  -- Referential integrity check for customer.
  INNER JOIN `{{ project_id }}.{{ raw_dataset }}.stg_customer` AS c
    ON s.customer_id = c.customer_id
  -- Referential integrity check for lead (if it exists).
  LEFT JOIN `{{ project_id }}.{{ raw_dataset }}.stg_lead` AS l
    ON s.originating_lead_id = l.lead_id
  WHERE
    s.rn = 1
    AND (s.originating_lead_id IS NULL OR l.lead_id IS NOT NULL)
) AS Source
ON
  Target.opportunity_id = Source.opportunity_id
WHEN MATCHED THEN
  -- SCD Type 1: Update existing records.
  UPDATE SET
    Target.name = Source.name,
    Target.customer_id = Source.customer_id,
    Target.originating_lead_id = Source.originating_lead_id,
    Target.stage = Source.stage,
    Target.status = Source.status,
    Target.estimated_value = Source.estimated_value,
    Target.probability = Source.probability,
    Target.close_date = Source.close_date,
    Target.created_on = Source.created_on,
    Target.owner_id = Source.owner_id
WHEN NOT MATCHED THEN
  -- Insert new records.
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
    Source.opportunity_id,
    Source.name,
    Source.customer_id,
    Source.originating_lead_id,
    Source.stage,
    Source.status,
    Source.estimated_value,
    Source.probability,
    Source.close_date,
    Source.created_on,
    Source.owner_id
  );

-- -----------------------------------------------------------------------------------
-- MERGE into quote_detail
-- -----------------------------------------------------------------------------------
MERGE `{{ project_id }}.{{ curated_dataset }}.quote_detail` AS Target
USING (
  -- Select and de-duplicate source data.
  SELECT
    * EXCEPT(rn)
  FROM (
    SELECT
      *,
      -- No timestamp available; de-duplicating on primary key to ensure uniqueness.
      ROW_NUMBER() OVER(PARTITION BY quote_detail_id ORDER BY quote_id) AS rn
    FROM
      `{{ project_id }}.{{ raw_dataset }}.stg_quote_detail`
    WHERE
      -- Primary key and foreign key must not be null.
      quote_detail_id IS NOT NULL
      AND quote_id IS NOT NULL
  )
  WHERE
    rn = 1
) AS Source
ON
  Target.quote_detail_id = Source.quote_detail_id
WHEN MATCHED THEN
  -- SCD Type 1: Update existing records.
  UPDATE SET
    Target.quote_id = Source.quote_id,
    Target.product_name = Source.product_name,
    Target.product_category = Source.product_category,
    Target.quantity = Source.quantity,
    Target.unit_price = Source.unit_price,
    Target.discount = Source.discount,
    Target.total_amount = Source.total_amount
WHEN NOT MATCHED THEN
  -- Insert new records.
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
    Source.quote_detail_id,
    Source.quote_id,
    Source.product_name,
    Source.product_category,
    Source.quantity,
    Source.unit_price,
    Source.discount,
    Source.total_amount
  );

-- -----------------------------------------------------------------------------------
-- MERGE into quote
-- -----------------------------------------------------------------------------------
MERGE `{{ project_id }}.{{ curated_dataset }}.quote` AS Target
USING (
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
    ),
    validated_source AS (
      -- Select, de-duplicate, and validate source data.
      SELECT
        s.* EXCEPT(rn)
      FROM (
        SELECT
          *,
          ROW_NUMBER() OVER(PARTITION BY quote_id ORDER BY created_on DESC) AS rn
        FROM
          `{{ project_id }}.{{ raw_dataset }}.stg_quote`
        WHERE
          -- Primary key and required foreign keys must not be null.
          quote_id IS NOT NULL
          AND opportunity_id IS NOT NULL
          AND customer_id IS NOT NULL
      ) AS s
      -- Financial integrity check: header total must match sum of line item totals.
      -- Using an INNER JOIN filters out quotes that fail validation.
      INNER JOIN quote_details_agg AS qd
        ON s.quote_id = qd.quote_id
        AND SAFE.ROUND(s.total_amount, 2) = SAFE.ROUND(qd.calculated_total_amount, 2)
      -- Referential integrity check for customer.
      INNER JOIN `{{ project_id }}.{{ raw_dataset }}.stg_customer` AS c
        ON s.customer_id = c.customer_id
      -- Referential integrity check for opportunity.
      INNER JOIN `{{ project_id }}.{{ raw_dataset }}.stg_opportunity` AS o
        ON s.opportunity_id = o.opportunity_id
      WHERE
        s.rn = 1
    )
  SELECT * FROM validated_source
) AS Source
ON
  Target.quote_id = Source.quote_id
WHEN MATCHED THEN
  -- SCD Type 1: Update existing records.
  UPDATE SET
    Target.quote_number = Source.quote_number,
    Target.opportunity_id = Source.opportunity_id,
    Target.customer_id = Source.customer_id,
    Target.status = Source.status,
    Target.total_amount = Source.total_amount,
    Target.currency = Source.currency,
    Target.valid_from = Source.valid_from,
    Target.valid_to = Source.valid_to,
    Target.created_on = Source.created_on
WHEN NOT MATCHED THEN
  -- Insert new records.
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
    Source.quote_id,
    Source.quote_number,
    Source.opportunity_id,
    Source.customer_id,
    Source.status,
    Source.total_amount,
    Source.currency,
    Source.valid_from,
    Source.valid_to,
    Source.created_on
  );
