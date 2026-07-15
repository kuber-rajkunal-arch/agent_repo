/*
  This script contains the DDL and DML for creating and populating the curated (Gold)
  CRM tables based on the Customer_SSOT_TDD.

  The script is designed to be idempotent and suitable for production environments.
  It includes:
  1. CREATE OR REPLACE TABLE statements to define the schema, partitioning, and
     clustering for the target curated tables.
  2. Stored Procedures for each table to perform an incremental MERGE (SCD Type 1)
     from the staging (Raw) layer to the curated (Gold) layer.
*/

-- =============================================================================
-- DDL for Curated (Gold) Tables
-- =============================================================================

-- Create the 'customer' dimension table
CREATE OR REPLACE TABLE `{{ var('project_id') }}.{{ var('curated_dataset') }}.customer`
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
OPTIONS(
  description="Curated dimension table for customer information."
);

-- Create the 'lead' table
CREATE OR REPLACE TABLE `{{ var('project_id') }}.{{ var('curated_dataset') }}.lead`
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
OPTIONS(
  description="Curated table for lead information, representing the earliest stage of the sales funnel.",
  partition_expiration_days=4000 -- ~11 years, effectively keeping data long-term
);

-- Create the 'opportunity' table
CREATE OR REPLACE TABLE `{{ var('project_id') }}.{{ var('curated_dataset') }}.opportunity`
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
OPTIONS(
  description="Curated table for sales opportunities in the active sales pipeline.",
  partition_expiration_days=4000 -- ~11 years, effectively keeping data long-term
);

-- Create the 'quote' table
CREATE OR REPLACE TABLE `{{ var('project_id') }}.{{ var('curated_dataset') }}.quote`
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
OPTIONS(
  description="Curated table for header-level information for sales quotes.",
  partition_expiration_days=4000 -- ~11 years, effectively keeping data long-term
);

-- Create the 'quote_detail' table
CREATE OR REPLACE TABLE `{{ var('project_id') }}.{{ var('curated_dataset') }}.quote_detail`
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
OPTIONS(
  description="Curated table for individual line items for each sales quote."
);


-- =============================================================================
-- Stored Procedures for Incremental Loading (MERGE)
-- =============================================================================

CREATE OR REPLACE PROCEDURE `{{ var('project_id') }}.{{ var('curated_dataset') }}.sp_load_customer`(
  in_project_id STRING, in_raw_dataset STRING, in_curated_dataset STRING
)
BEGIN
  EXECUTE IMMEDIATE FORMAT("""
    MERGE `%s.%s.customer` AS Target
    USING `%s.%s.stg_customer` AS Source
    ON Target.customer_id = Source.customer_id
    WHEN MATCHED THEN
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
    WHEN NOT MATCHED BY TARGET THEN
      INSERT (
        customer_id, customer_type, name, company_name, industry, email, phone,
        website, address_line1, address_line2, city, state, country, postal_code,
        created_on, modified_on, is_active
      )
      VALUES (
        Source.customer_id, Source.customer_type, Source.name, Source.company_name,
        Source.industry, Source.email, Source.phone, Source.website, Source.address_line1,
        Source.address_line2, Source.city, Source.state, Source.country, Source.postal_code,
        Source.created_on, Source.modified_on, Source.is_active
      );
  """, in_project_id, in_curated_dataset, in_project_id, in_raw_dataset);
END;


CREATE OR REPLACE PROCEDURE `{{ var('project_id') }}.{{ var('curated_dataset') }}.sp_load_lead`(
  in_project_id STRING, in_raw_dataset STRING, in_curated_dataset STRING
)
BEGIN
  EXECUTE IMMEDIATE FORMAT("""
    MERGE `%s.%s.lead` AS Target
    USING `%s.%s.stg_lead` AS Source
    ON Target.lead_id = Source.lead_id
    WHEN MATCHED THEN
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
    WHEN NOT MATCHED BY TARGET THEN
      INSERT (
        lead_id, topic, first_name, last_name, company_name, email, phone,
        lead_source, status, customer_id, created_on, qualified_on, owner_id
      )
      VALUES (
        Source.lead_id, Source.topic, Source.first_name, Source.last_name,
        Source.company_name, Source.email, Source.phone, Source.lead_source,
        Source.status, Source.customer_id, Source.created_on, Source.qualified_on,
        Source.owner_id
      );
  """, in_project_id, in_curated_dataset, in_project_id, in_raw_dataset);
END;


CREATE OR REPLACE PROCEDURE `{{ var('project_id') }}.{{ var('curated_dataset') }}.sp_load_opportunity`(
  in_project_id STRING, in_raw_dataset STRING, in_curated_dataset STRING
)
BEGIN
  EXECUTE IMMEDIATE FORMAT("""
    MERGE `%s.%s.opportunity` AS Target
    USING `%s.%s.stg_opportunity` AS Source
    ON Target.opportunity_id = Source.opportunity_id
    WHEN MATCHED THEN
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
    WHEN NOT MATCHED BY TARGET THEN
      INSERT (
        opportunity_id, name, customer_id, originating_lead_id, stage, status,
        estimated_value, probability, close_date, created_on, owner_id
      )
      VALUES (
        Source.opportunity_id, Source.name, Source.customer_id, Source.originating_lead_id,
        Source.stage, Source.status, Source.estimated_value, Source.probability,
        Source.close_date, Source.created_on, Source.owner_id
      );
  """, in_project_id, in_curated_dataset, in_project_id, in_raw_dataset);
END;


CREATE OR REPLACE PROCEDURE `{{ var('project_id') }}.{{ var('curated_dataset') }}.sp_load_quote`(
  in_project_id STRING, in_raw_dataset STRING, in_curated_dataset STRING
)
BEGIN
  EXECUTE IMMEDIATE FORMAT("""
    MERGE `%s.%s.quote` AS Target
    USING `%s.%s.stg_quote` AS Source
    ON Target.quote_id = Source.quote_id
    WHEN MATCHED THEN
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
    WHEN NOT MATCHED BY TARGET THEN
      INSERT (
        quote_id, quote_number, opportunity_id, customer_id, status, total_amount,
        currency, valid_from, valid_to, created_on
      )
      VALUES (
        Source.quote_id, Source.quote_number, Source.opportunity_id, Source.customer_id,
        Source.status, Source.total_amount, Source.currency, Source.valid_from,
        Source.valid_to, Source.created_on
      );
  """, in_project_id, in_curated_dataset, in_project_id, in_raw_dataset);
END;


CREATE OR REPLACE PROCEDURE `{{ var('project_id') }}.{{ var('curated_dataset') }}.sp_load_quote_detail`(
  in_project_id STRING, in_raw_dataset STRING, in_curated_dataset STRING
)
BEGIN
  EXECUTE IMMEDIATE FORMAT("""
    MERGE `%s.%s.quote_detail` AS Target
    USING `%s.%s.stg_quote_detail` AS Source
    ON Target.quote_detail_id = Source.quote_detail_id
    WHEN MATCHED THEN
      UPDATE SET
        Target.quote_id = Source.quote_id,
        Target.product_name = Source.product_name,
        Target.product_category = Source.product_category,
        Target.quantity = Source.quantity,
        Target.unit_price = Source.unit_price,
        Target.discount = Source.discount,
        Target.total_amount = Source.total_amount
    WHEN NOT MATCHED BY TARGET THEN
      INSERT (
        quote_detail_id, quote_id, product_name, product_category, quantity,
        unit_price, discount, total_amount
      )
      VALUES (
        Source.quote_detail_id, Source.quote_id, Source.product_name,
        Source.product_category, Source.quantity, Source.unit_price,
        Source.discount, Source.total_amount
      );
  """, in_project_id, in_curated_dataset, in_project_id, in_raw_dataset);
END;