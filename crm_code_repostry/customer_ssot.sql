-- Copyright 2024 Google LLC
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

/*
This script performs incremental loads from staging tables (Raw dataset) into
the curated, analytics-ready tables (Curated dataset) for the Customer SSOT
data platform.

It uses a MERGE statement with an SCD Type 1 pattern to insert new records
and update existing ones based on their natural keys. This script is designed
to be idempotent and can be run repeatedly against the staging tables, assuming
the staging tables contain the records to be processed for a given run.

The following entities are processed:
- customer
- lead
- opportunity
- quote
- quote_detail
*/

-- ===================================================================================
-- Configuration
-- ===================================================================================
-- Define project and dataset names. In a production environment, these should be
-- configured via your orchestration tool (e.g., dbt profiles, Airflow variables).
DECLARE project_id STRING DEFAULT 'your-gcp-project-id';
DECLARE raw_dataset STRING DEFAULT 'Raw';
DECLARE curated_dataset STRING DEFAULT 'Curated';

-- ===================================================================================
-- Customer Transformation
-- ===================================================================================
BEGIN
  MERGE `${project_id}.${curated_dataset}.customer` AS T
  USING `${project_id}.${raw_dataset}.stg_customer` AS S
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
  WHEN NOT MATCHED THEN
    INSERT (
      customer_id, customer_type, name, company_name, industry, email, phone, website,
      address_line1, address_line2, city, state, country, postal_code, created_on,
      modified_on, is_active
    )
    VALUES (
      S.customer_id, S.customer_type, S.name, S.company_name, S.industry, S.email, S.phone, S.website,
      S.address_line1, S.address_line2, S.city, S.state, S.country, S.postal_code, S.created_on,
      S.modified_on, S.is_active
    );
END;

-- ===================================================================================
-- Lead Transformation
-- ===================================================================================
BEGIN
  MERGE `${project_id}.${curated_dataset}.lead` AS T
  USING `${project_id}.${raw_dataset}.stg_lead` AS S
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
  WHEN NOT MATCHED THEN
    INSERT (
      lead_id, topic, first_name, last_name, company_name, email, phone,
      lead_source, status, customer_id, created_on, qualified_on, owner_id
    )
    VALUES (
      S.lead_id, S.topic, S.first_name, S.last_name, S.company_name, S.email, S.phone,
      S.lead_source, S.status, S.customer_id, S.created_on, S.qualified_on, S.owner_id
    );
END;

-- ===================================================================================
-- Opportunity Transformation
-- ===================================================================================
BEGIN
  MERGE `${project_id}.${curated_dataset}.opportunity` AS T
  USING `${project_id}.${raw_dataset}.stg_opportunity` AS S
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
  WHEN NOT MATCHED THEN
    INSERT (
      opportunity_id, name, customer_id, originating_lead_id, stage, status,
      estimated_value, probability, close_date, created_on, owner_id
    )
    VALUES (
      S.opportunity_id, S.name, S.customer_id, S.originating_lead_id, S.stage, S.status,
      S.estimated_value, S.probability, S.close_date, S.created_on, S.owner_id
    );
END;

-- ===================================================================================
-- Quote Transformation
-- ===================================================================================
BEGIN
  MERGE `${project_id}.${curated_dataset}.quote` AS T
  USING `${project_id}.${raw_dataset}.stg_quote` AS S
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
  WHEN NOT MATCHED THEN
    INSERT (
      quote_id, quote_number, opportunity_id, customer_id, status, total_amount,
      currency, valid_from, valid_to, created_on
    )
    VALUES (
      S.quote_id, S.quote_number, S.opportunity_id, S.customer_id, S.status, S.total_amount,
      S.currency, S.valid_from, S.valid_to, S.created_on
    );
END;

-- ===================================================================================
-- Quote Detail Transformation
-- ===================================================================================
BEGIN
  MERGE `${project_id}.${curated_dataset}.quote_detail` AS T
  USING `${project_id}.${raw_dataset}.stg_quote_detail` AS S
  ON T.quote_detail_id = S.quote_detail_id
  WHEN MATCHED THEN
    UPDATE SET
      T.quote_id = S.quote_id,
      T.product_name = S.product_name,
      T.product_category = S.product_category,
      T.quantity = S.quantity,
      T.unit_.price = S.unit_price,
      T.discount = S.discount,
      T.total_amount = S.total_amount
  WHEN NOT MATCHED THEN
    INSERT (
      quote_detail_id, quote_id, product_name, product_category, quantity,
      unit_price, discount, total_amount
    )
    VALUES (
      S.quote_detail_id, S.quote_id, S.product_name, S.product_category, S.quantity,
      S.unit_price, S.discount, S.total_amount
    );
END;