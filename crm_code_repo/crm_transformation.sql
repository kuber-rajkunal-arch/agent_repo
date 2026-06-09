-- Copyright 2023 Google LLC
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- This script contains the transformation logic to populate the curated
-- CRM tables (customer, lead, opportunity, quote, quote_detail) from
-- the corresponding staging tables.
--
-- The pattern used is an incremental merge (SCD Type 1), which handles
-- both the initial creation of tables and the ongoing insertion of new
-- records and updates to existing ones.

--------------------------------------------------------------------------------
-- Curated.customer Transformation
--------------------------------------------------------------------------------

-- Create the table if it doesn't exist, defining schema, clustering, and description.
CREATE TABLE IF NOT EXISTS Curated.customer
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
CLUSTER BY customer_type, industry
OPTIONS(
  description="Curated dimension table for customer information. Contains a single source of truth for customer data, serving as the central point for linking leads, opportunities, and quotes."
);

-- Merge data from staging into the curated customer table.
MERGE Curated.customer AS T
USING Raw.stg_customer AS S
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
    customer_id, customer_type, name, company_name, industry, email, phone,
    website, address_line1, address_line2, city, state, country, postal_code,
    created_on, modified_on, is_active
  )
  VALUES (
    S.customer_id, S.customer_type, S.name, S.company_name, S.industry, S.email, S.phone,
    S.website, S.address_line1, S.address_line2, S.city, S.state, S.country, S.postal_code,
    S.created_on, S.modified_on, S.is_active
  );

--------------------------------------------------------------------------------
-- Curated.lead Transformation
--------------------------------------------------------------------------------

-- Create the table if it doesn't exist, defining schema, partitioning, clustering, and description.
CREATE TABLE IF NOT EXISTS Curated.lead
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
CLUSTER BY lead_source, status
OPTIONS(
  description="Curated table for leads, representing potential sales opportunities at the earliest stage of the sales funnel."
);

-- Merge data from staging into the curated lead table.
MERGE Curated.lead AS T
USING Raw.stg_lead AS S
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
    lead_id, topic, first_name, last_name, company_name, email, phone,
    lead_source, status, customer_id, created_on, qualified_on, owner_id
  )
  VALUES (
    S.lead_id, S.topic, S.first_name, S.last_name, S.company_name, S.email, S.phone,
    S.lead_source, S.status, S.customer_id, S.created_on, S.qualified_on, S.owner_id
  );

--------------------------------------------------------------------------------
-- Curated.opportunity Transformation
--------------------------------------------------------------------------------

-- Create the table if it doesn't exist, defining schema, partitioning, clustering, and description.
CREATE TABLE IF NOT EXISTS Curated.opportunity
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
CLUSTER BY stage, status
OPTIONS(
  description="Curated table for sales opportunities, representing qualified prospects in the active sales pipeline."
);

-- Merge data from staging into the curated opportunity table.
MERGE Curated.opportunity AS T
USING Raw.stg_opportunity AS S
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
    opportunity_id, name, customer_id, originating_lead_id, stage, status,
    estimated_value, probability, close_date, created_on, owner_id
  )
  VALUES (
    S.opportunity_id, S.name, S.customer_id, S.originating_lead_id, S.stage, S.status,
    S.estimated_value, S.probability, S.close_date, S.created_on, S.owner_id
  );

--------------------------------------------------------------------------------
-- Curated.quote Transformation
--------------------------------------------------------------------------------

-- Create the table if it doesn't exist, defining schema, partitioning, clustering, and description.
CREATE TABLE IF NOT EXISTS Curated.quote
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
CLUSTER BY status
OPTIONS(
  description="Curated table for header-level sales quote information."
);

-- Merge data from staging into the curated quote table.
MERGE Curated.quote AS T
USING Raw.stg_quote AS S
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
    quote_id, quote_number, opportunity_id, customer_id, status,
    total_amount, currency, valid_from, valid_to, created_on
  )
  VALUES (
    S.quote_id, S.quote_number, S.opportunity_id, S.customer_id, S.status,
    S.total_amount, S.currency, S.valid_from, S.valid_to, S.created_on
  );

--------------------------------------------------------------------------------
-- Curated.quote_detail Transformation
--------------------------------------------------------------------------------

-- Create the table if it doesn't exist, defining schema and description.
CREATE TABLE IF NOT EXISTS Curated.quote_detail
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
  description="Curated table for individual line items for each sales quote, providing detailed product and pricing information."
);

-- Merge data from staging into the curated quote_detail table.
MERGE Curated.quote_detail AS T
USING Raw.stg_quote_detail AS S
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
    quote_detail_id, quote_id, product_name, product_category,
    quantity, unit_price, discount, total_amount
  )
  VALUES (
    S.quote_detail_id, S.quote_id, S.product_name, S.product_category,
    S.quantity, S.unit_price, S.discount, S.total_amount
  );
