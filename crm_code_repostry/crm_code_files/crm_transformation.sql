/*
  This script performs the transformation of CRM data from the Raw (staging) layer
  to the Curated (analytics-ready) layer. It creates the target tables with
  appropriate partitioning and clustering and uses an incremental MERGE pattern
  (SCD Type 1) to load data, ensuring idempotency and data integrity.

  The script executes the following steps in order:
  1.  Create and load the `customer` dimension table.
  2.  Create and load the `lead` table, ensuring referential integrity to `customer`.
  3.  Create and load the `opportunity` table, ensuring referential integrity to `customer` and `lead`.
  4.  Create and load the `quote` table, ensuring referential integrity and calculating `total_amount` from line items.
  5.  Create and load the `quote_detail` table, ensuring referential integrity to `quote`.
*/

-- =================================================================================================
-- Customer Transformation
-- =================================================================================================

CREATE OR REPLACE TABLE `your_gcp_project_id.Curated.customer`
(
  customer_id STRING NOT NULL,
  customer_type STRING,
  name STRING,
  company_name STRING,
  industry STRING,
  email STRING,
  phone STRING,
  website STRING,
  address_line1 STRING,
  address_line2 STRING,
  city STRING,
  state STRING,
  country STRING,
  postal_code STRING,
  created_on TIMESTAMP,
  modified_on TIMESTAMP,
  is_active BOOL
)
CLUSTER BY (customer_type, industry)
OPTIONS (
  description="Curated dimension table for customer information."
);

MERGE `your_gcp_project_id.Curated.customer` AS T
USING `your_gcp_project_id.Raw.stg_customer` AS S
ON T.customer_id = S.customer_id
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
WHEN NOT MATCHED BY TARGET THEN
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

-- =================================================================================================
-- Lead Transformation
-- =================================================================================================

CREATE OR REPLACE TABLE `your_gcp_project_id.Curated.lead`
(
  lead_id STRING NOT NULL,
  topic STRING,
  first_name STRING,
  last_name STRING,
  company_name STRING,
  email STRING,
  phone STRING,
  lead_source STRING,
  status STRING,
  customer_id STRING,
  created_on TIMESTAMP,
  qualified_on TIMESTAMP,
  owner_id STRING
)
PARTITION BY DATE(created_on)
CLUSTER BY (lead_source, status)
OPTIONS (
  description="Curated table for lead information, representing the earliest stage of the sales funnel."
);

MERGE `your_gcp_project_id.Curated.lead` AS T
USING (
  SELECT *
  FROM `your_gcp_project_id.Raw.stg_lead`
  -- Referential Integrity: Ensure the associated customer exists or the customer_id is NULL.
  WHERE customer_id IS NULL OR EXISTS (
    SELECT 1
    FROM `your_gcp_project_id.Curated.customer` c
    WHERE c.customer_id = stg_lead.customer_id
  )
) AS S
ON T.lead_id = S.lead_id
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
WHEN NOT MATCHED BY TARGET THEN
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

-- =================================================================================================
-- Opportunity Transformation
-- =================================================================================================

CREATE OR REPLACE TABLE `your_gcp_project_id.Curated.opportunity`
(
  opportunity_id STRING NOT NULL,
  name STRING,
  customer_id STRING,
  originating_lead_id STRING,
  stage STRING,
  status STRING,
  estimated_value FLOAT64,
  probability FLOAT64,
  close_date DATE,
  created_on TIMESTAMP,
  owner_id STRING
)
PARTITION BY DATE(created_on)
CLUSTER BY (stage, status)
OPTIONS (
  description="Curated table for sales opportunities in the active sales pipeline."
);

MERGE `your_gcp_project_id.Curated.opportunity` AS T
USING (
  SELECT *
  FROM `your_gcp_project_id.Raw.stg_opportunity`
  -- Referential Integrity Checks
  WHERE
    -- Ensure the associated customer exists.
    EXISTS (
      SELECT 1
      FROM `your_gcp_project_id.Curated.customer` c
      WHERE c.customer_id = stg_opportunity.customer_id
    )
    -- Ensure the originating lead exists or is NULL.
    AND (
      stg_opportunity.originating_lead_id IS NULL OR EXISTS (
        SELECT 1
        FROM `your_gcp_project_id.Curated.lead` l
        WHERE l.lead_id = stg_opportunity.originating_lead_id
      )
    )
) AS S
ON T.opportunity_id = S.opportunity_id
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
WHEN NOT MATCHED BY TARGET THEN
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

-- =================================================================================================
-- Quote Transformation
-- =================================================================================================

CREATE OR REPLACE TABLE `your_gcp_project_id.Curated.quote`
(
  quote_id STRING NOT NULL,
  quote_number STRING,
  opportunity_id STRING,
  customer_id STRING,
  status STRING,
  total_amount FLOAT64,
  currency STRING,
  valid_from DATE,
  valid_to DATE,
  created_on TIMESTAMP
)
PARTITION BY DATE(created_on)
CLUSTER BY (status)
OPTIONS (
  description="Curated table for header-level information for sales quotes."
);

MERGE `your_gcp_project_id.Curated.quote` AS T
USING (
  WITH calculated_quote_totals AS (
    -- Financial Integrity: Calculate total amount from line items to ensure accuracy.
    SELECT
      quote_id,
      SUM(total_amount) AS calculated_total_amount
    FROM `your_gcp_project_id.Raw.stg_quote_detail`
    GROUP BY quote_id
  )
  SELECT
    q.quote_id,
    q.quote_number,
    q.opportunity_id,
    q.customer_id,
    q.status,
    -- Use the calculated total from line items, falling back to header amount if no line items exist.
    COALESCE(cqt.calculated_total_amount, q.total_amount) AS total_amount,
    q.currency,
    q.valid_from,
    q.valid_to,
    q.created_on
  FROM `your_gcp_project_id.Raw.stg_quote` AS q
  LEFT JOIN calculated_quote_totals AS cqt ON q.quote_id = cqt.quote_id
  -- Referential Integrity Checks
  WHERE
    -- Ensure the associated customer exists.
    EXISTS (
      SELECT 1
      FROM `your_gcp_project_id.Curated.customer` c
      WHERE c.customer_id = q.customer_id
    )
    -- Ensure the associated opportunity exists.
    AND EXISTS (
      SELECT 1
      FROM `your_gcp_project_id.Curated.opportunity` o
      WHERE o.opportunity_id = q.opportunity_id
    )
) AS S
ON T.quote_id = S.quote_id
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
WHEN NOT MATCHED BY TARGET THEN
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

-- =================================================================================================
-- Quote Detail Transformation
-- =================================================================================================

CREATE OR REPLACE TABLE `your_gcp_project_id.Curated.quote_detail`
(
  quote_detail_id STRING NOT NULL,
  quote_id STRING,
  product_name STRING,
  product_category STRING,
  quantity INT64,
  unit_price FLOAT64,
  discount FLOAT64,
  total_amount FLOAT64
)
OPTIONS (
  description="Curated table for individual line items for each sales quote."
);

MERGE `your_gcp_project_id.Curated.quote_detail` AS T
USING (
  SELECT *
  FROM `your_gcp_project_id.Raw.stg_quote_detail`
  -- Referential Integrity: Ensure the parent quote exists in the curated quote table.
  WHERE EXISTS (
    SELECT 1
    FROM `your_gcp_project_id.Curated.quote` q
    WHERE q.quote_id = stg_quote_detail.quote_id
  )
) AS S
ON T.quote_detail_id = S.quote_detail_id
WHEN MATCHED THEN
  UPDATE SET
    T.quote_id = S.quote_id,
    T.product_name = S.product_name,
    T.product_category = S.product_category,
    T.quantity = S.quantity,
    T.unit_price = S.unit_price,
    T.discount = S.discount,
    T.total_amount = S.total_amount
WHEN NOT MATCHED BY TARGET THEN
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
