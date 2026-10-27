/*
    This script contains the transformation logic to populate the curated
    Customer SSOT tables from the corresponding staging tables. It implements
    an incremental SCD Type 1 load pattern using BigQuery's MERGE statement.
*/
BEGIN

  -- Configuration: In a production deployment (e.g., via dbt or Airflow),
  -- these variables would be substituted with environment-specific values.
  DECLARE gcp_project_id STRING DEFAULT 'your-gcp-project-id';
  DECLARE raw_dataset STRING DEFAULT 'raw';
  DECLARE curated_dataset STRING DEFAULT 'curated';

  ------------------------------------------------------------------------------
  -- Entity: customer
  -- Target Table: curated.customer
  -- Source Table: raw.stg_customer
  ------------------------------------------------------------------------------
  MERGE `${gcp_project_id}.${curated_dataset}.customer` AS T
  USING `${gcp_project_id}.${raw_dataset}.stg_customer` AS S
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

  ------------------------------------------------------------------------------
  -- Entity: lead
  -- Target Table: curated.lead
  -- Source Table: raw.stg_lead
  ------------------------------------------------------------------------------
  MERGE `${gcp_project_id}.${curated_dataset}.lead` AS T
  USING `${gcp_project_id}.${raw_dataset}.stg_lead` AS S
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

  ------------------------------------------------------------------------------
  -- Entity: opportunity
  -- Target Table: curated.opportunity
  -- Source Table: raw.stg_opportunity
  ------------------------------------------------------------------------------
  MERGE `${gcp_project_id}.${curated_dataset}.opportunity` AS T
  USING `${gcp_project_id}.${raw_dataset}.stg_opportunity` AS S
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

  ------------------------------------------------------------------------------
  -- Entity: quote
  -- Target Table: curated.quote
  -- Source Table: raw.stg_quote
  ------------------------------------------------------------------------------
  MERGE `${gcp_project_id}.${curated_dataset}.quote` AS T
  USING `${gcp_project_id}.${raw_dataset}.stg_quote` AS S
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
      quote_id, quote_number, opportunity_id, customer_id, status, total_amount,
      currency, valid_from, valid_to, created_on
    )
    VALUES (
      S.quote_id, S.quote_number, S.opportunity_id, S.customer_id, S.status, S.total_amount,
      S.currency, S.valid_from, S.valid_to, S.created_on
    );

  ------------------------------------------------------------------------------
  -- Entity: quote_detail
  -- Target Table: curated.quote_detail
  -- Source Table: raw.stg_quote_detail
  ------------------------------------------------------------------------------
  MERGE `${gcp_project_id}.${curated_dataset}.quote_detail` AS T
  USING `${gcp_project_id}.${raw_dataset}.stg_quote_detail` AS S
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
      quote_detail_id, quote_id, product_name, product_category, quantity,
      unit_price, discount, total_amount
    )
    VALUES (
      S.quote_detail_id, S.quote_id, S.product_name, S.product_category, S.quantity,
      S.unit_price, S.discount, S.total_amount
    );

END;
