/*
--------------------------------------------------------------------------------
--
-- Name: customer_ssot.sql
--
-- Purpose: Creates and populates the curated (Gold) tables for the Customer
--          Single Source of Truth (SSOT) data platform. This script is
--          designed to be idempotent and handles incremental data loads using
--          an SCD Type 1 merge pattern.
--
-- Author: Senior Software Engineer
--
-- Created: 2023-10-27
--
-- Copyright: (c) 2023 Your Company
--
--------------------------------------------------------------------------------
--
-- Notes:
-- - This script assumes the existence of staging tables in the 'raw' dataset
--   (e.g., `your_project_id.your_raw_dataset.stg_customer`).
-- - Project and dataset names are parameterized (e.g., `your_project_id`,
--   `your_curated_dataset`) and should be replaced by your configuration
--   management system (e.g., dbt, Terraform).
--
--------------------------------------------------------------------------------
*/

-- =============================================================================
-- 1. Customer Table
-- =============================================================================

-- DDL for customer table
CREATE OR REPLACE TABLE `your_project_id.your_curated_dataset.customer`
(
  customer_id STRING NOT NULL OPTIONS(description="Unique identifier for the customer, serving as the primary key."),
  customer_type STRING OPTIONS(description="The type or category of the customer (e.g., Enterprise, SMB)."),
  name STRING OPTIONS(description="The full name of the customer or contact person."),
  company_name STRING OPTIONS(description="The name of the company associated with the customer."),
  industry STRING OPTIONS(description="The industry sector the customer belongs to."),
  email STRING OPTIONS(description="The primary email address of the customer."),
  phone STRING OPTIONS(description="The primary phone number of the customer."),
  website STRING OPTIONS(description="The customer's website URL."),
  address_line1 STRING OPTIONS(description="The first line of the customer's address."),
  address_line2 STRING OPTIONS(description="The second line of the customer's address."),
  city STRING OPTIONS(description="The city of the customer's address."),
  state STRING OPTIONS(description="The state or province of the customer's address."),
  country STRING OPTIONS(description="The country of the customer's address."),
  postal_code STRING OPTIONS(description="The postal or ZIP code of the customer's address."),
  created_on TIMESTAMP OPTIONS(description="The timestamp when the customer record was created in the source system."),
  modified_on TIMESTAMP OPTIONS(description="The timestamp when the customer record was last modified."),
  is_active BOOL OPTIONS(description="A boolean flag indicating if the customer is currently active.")
)
CLUSTER BY customer_type, industry
OPTIONS(
  description="This curated dimension table provides a single source of truth for customer information. It joins data from the customer source entity and serves as the central point for linking leads, opportunities, and quotes.",
  labels=[("domain", "sales"), ("entity", "customer")]
);

-- DML for customer table (SCD Type 1)
MERGE `your_project_id.your_curated_dataset.customer` AS T
USING `your_project_id.your_raw_dataset.stg_customer` AS S
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


-- =============================================================================
-- 2. Lead Table
-- =============================================================================

-- DDL for lead table
CREATE OR REPLACE TABLE `your_project_id.your_curated_dataset.lead`
(
  lead_id STRING NOT NULL OPTIONS(description="Unique identifier for the lead, serving as the primary key."),
  topic STRING OPTIONS(description="The primary subject or topic of the lead."),
  first_name STRING OPTIONS(description="The first name of the lead contact."),
  last_name STRING OPTIONS(description="The last name of the lead contact."),
  company_name STRING OPTIONS(description="The company name associated with the lead."),
  email STRING OPTIONS(description="The email address of the lead contact."),
  phone STRING OPTIONS(description="The phone number of the lead contact."),
  lead_source STRING OPTIONS(description="The source from which the lead was generated (e.g., Web, Referral)."),
  status STRING OPTIONS(description="The current status of the lead in the sales funnel (e.g., New, Qualified)."),
  customer_id STRING OPTIONS(description="Foreign key linking the lead to a customer record."),
  created_on TIMESTAMP OPTIONS(description="The timestamp when the lead was created in the source system."),
  qualified_on TIMESTAMP OPTIONS(description="The timestamp when the lead was qualified, marking its conversion."),
  owner_id STRING OPTIONS(description="The identifier of the employee who owns the lead.")
)
PARTITION BY DATE(created_on)
CLUSTER BY lead_source, status
OPTIONS(
  description="This curated table stores information about leads, which represent potential sales opportunities at the earliest stage of the sales funnel.",
  labels=[("domain", "sales"), ("entity", "lead")]
);

-- DML for lead table (SCD Type 1)
MERGE `your_project_id.your_curated_dataset.lead` AS T
USING `your_project_id.your_raw_dataset.stg_lead` AS S
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


-- =============================================================================
-- 3. Opportunity Table
-- =============================================================================

-- DDL for opportunity table
CREATE OR REPLACE TABLE `your_project_id.your_curated_dataset.opportunity`
(
  opportunity_id STRING NOT NULL OPTIONS(description="Unique identifier for the opportunity, serving as the primary key."),
  name STRING OPTIONS(description="The name or title of the opportunity."),
  customer_id STRING OPTIONS(description="Foreign key linking the opportunity to a customer record."),
  originating_lead_id STRING OPTIONS(description="Foreign key linking the opportunity to the lead it originated from."),
  stage STRING OPTIONS(description="The current stage of the opportunity in the sales pipeline."),
  status STRING OPTIONS(description="The current status of the opportunity (e.g., Open, Won, Lost)."),
  estimated_value FLOAT64 OPTIONS(description="The estimated monetary value of the opportunity."),
  probability FLOAT64 OPTIONS(description="The probability of winning the opportunity, as a float."),
  close_date DATE OPTIONS(description="The expected date on which the opportunity will be closed."),
  created_on TIMESTAMP OPTIONS(description="The timestamp when the opportunity was created."),
  owner_id STRING OPTIONS(description="The identifier of the employee who owns the opportunity.")
)
PARTITION BY DATE(created_on)
CLUSTER BY stage, status
OPTIONS(
  description="This curated table contains information on sales opportunities, representing qualified prospects that have moved into the active sales pipeline.",
  labels=[("domain", "sales"), ("entity", "opportunity")]
);

-- DML for opportunity table (SCD Type 1)
MERGE `your_project_id.your_curated_dataset.opportunity` AS T
USING `your_project_id.your_raw_dataset.stg_opportunity` AS S
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


-- =============================================================================
-- 4. Quote Table
-- =============================================================================

-- DDL for quote table
CREATE OR REPLACE TABLE `your_project_id.your_curated_dataset.quote`
(
  quote_id STRING NOT NULL OPTIONS(description="Unique identifier for the quote, serving as the primary key."),
  quote_number STRING OPTIONS(description="The human-readable identifier for the quote."),
  opportunity_id STRING OPTIONS(description="Foreign key linking the quote to a sales opportunity."),
  customer_id STRING OPTIONS(description="Foreign key linking the quote to a customer record."),
  status STRING OPTIONS(description="The current status of the quote (e.g., Draft, Active, Won)."),
  total_amount FLOAT64 OPTIONS(description="The total amount of the quote."),
  currency STRING OPTIONS(description="The currency code for the amounts in the quote."),
  valid_from DATE OPTIONS(description="The date from which the quote is valid."),
  valid_to DATE OPTIONS(description="The date until which the quote is valid."),
  created_on TIMESTAMP OPTIONS(description="The timestamp when the quote was created.")
)
PARTITION BY DATE(created_on)
CLUSTER BY status
OPTIONS(
  description="This curated table stores header-level information for sales quotes issued to customers.",
  labels=[("domain", "sales"), ("entity", "quote")]
);

-- DML for quote table (SCD Type 1)
MERGE `your_project_id.your_curated_dataset.quote` AS T
USING `your_project_id.your_raw_dataset.stg_quote` AS S
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


-- =============================================================================
-- 5. Quote Detail Table
-- =============================================================================

-- DDL for quote_detail table
CREATE OR REPLACE TABLE `your_project_id.your_curated_dataset.quote_detail`
(
  quote_detail_id STRING NOT NULL OPTIONS(description="Unique identifier for the quote line item, serving as the primary key."),
  quote_id STRING OPTIONS(description="Foreign key linking the line item to its parent quote header."),
  product_name STRING OPTIONS(description="The name of the product or service in this line item."),
  product_category STRING OPTIONS(description="The category of the product or service."),
  quantity INT64 OPTIONS(description="The number of units of the product or service."),
  unit_price FLOAT64 OPTIONS(description="The price per unit of the product or service."),
  discount FLOAT64 OPTIONS(description="The discount amount or percentage applied to this line item."),
  total_amount FLOAT64 OPTIONS(description="The total amount for this line item.")
)
OPTIONS(
  description="This curated table stores the individual line items for each sales quote, providing detailed product and pricing information.",
  labels=[("domain", "sales"), ("entity", "quote_detail")]
);

-- DML for quote_detail table (SCD Type 1)
MERGE `your_project_id.your_curated_dataset.quote_detail` AS T
USING `your_project_id.your_raw_dataset.stg_quote_detail` AS S
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
