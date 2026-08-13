-- ===================================================================================
--
-- Description: This script performs incremental loads (SCD Type 1) from the Raw
--              (staging) layer to the Curated layer for the Customer SSOT data platform.
--              It uses MERGE statements to insert new records and update existing ones
--              based on the source system's natural keys.
-- Source(s):   Raw.stg_customer, Raw.stg_lead, Raw.stg_opportunity,
--              Raw.stg_quote, Raw.stg_quote_detail
-- Target(s):   Curated.customer, Curated.lead, Curated.opportunity,
--              Curated.quote, Curated.quote_detail
--
-- ===================================================================================


-- Load data into Curated.customer
MERGE `Curated.customer` AS T
USING `Raw.stg_customer` AS S
ON T.customer_id = S.customer_id
WHEN MATCHED THEN
  UPDATE SET
    `customer_type` = S.customer_type,
    `name` = S.name,
    `company_name` = S.company_name,
    `industry` = S.industry,
    `email` = S.email,
    `phone` = S.phone,
    `website` = S.website,
    `address_line1` = S.address_line1,
    `address_line2` = S.address_line2,
    `city` = S.city,
    `state` = S.state,
    `country` = S.country,
    `postal_code` = S.postal_code,
    `created_on` = S.created_on,
    `modified_on` = S.modified_on,
    `is_active` = S.is_active
WHEN NOT MATCHED THEN
  INSERT (
    `customer_id`,
    `customer_type`,
    `name`,
    `company_name`,
    `industry`,
    `email`,
    `phone`,
    `website`,
    `address_line1`,
    `address_line2`,
    `city`,
    `state`,
    `country`,
    `postal_code`,
    `created_on`,
    `modified_on`,
    `is_active`
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


-- Load data into Curated.lead
MERGE `Curated.lead` AS T
USING `Raw.stg_lead` AS S
ON T.lead_id = S.lead_id
WHEN MATCHED THEN
  UPDATE SET
    `topic` = S.topic,
    `first_name` = S.first_name,
    `last_name` = S.last_name,
    `company_name` = S.company_name,
    `email` = S.email,
    `phone` = S.phone,
    `lead_source` = S.lead_source,
    `status` = S.status,
    `customer_id` = S.customer_id,
    `created_on` = S.created_on,
    `qualified_on` = S.qualified_on,
    `owner_id` = S.owner_id
WHEN NOT MATCHED THEN
  INSERT (
    `lead_id`,
    `topic`,
    `first_name`,
    `last_name`,
    `company_name`,
    `email`,
    `phone`,
    `lead_source`,
    `status`,
    `customer_id`,
    `created_on`,
    `qualified_on`,
    `owner_id`
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


-- Load data into Curated.opportunity
MERGE `Curated.opportunity` AS T
USING `Raw.stg_opportunity` AS S
ON T.opportunity_id = S.opportunity_id
WHEN MATCHED THEN
  UPDATE SET
    `name` = S.name,
    `customer_id` = S.customer_id,
    `originating_lead_id` = S.originating_lead_id,
    `stage` = S.stage,
    `status` = S.status,
    `estimated_value` = S.estimated_value,
    `probability` = S.probability,
    `close_date` = S.close_date,
    `created_on` = S.created_on,
    `owner_id` = S.owner_id
WHEN NOT MATCHED THEN
  INSERT (
    `opportunity_id`,
    `name`,
    `customer_id`,
    `originating_lead_id`,
    `stage`,
    `status`,
    `estimated_value`,
    `probability`,
    `close_date`,
    `created_on`,
    `owner_id`
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


-- Load data into Curated.quote
MERGE `Curated.quote` AS T
USING `Raw.stg_quote` AS S
ON T.quote_id = S.quote_id
WHEN MATCHED THEN
  UPDATE SET
    `quote_number` = S.quote_number,
    `opportunity_id` = S.opportunity_id,
    `customer_id` = S.customer_id,
    `status` = S.status,
    `total_amount` = S.total_amount,
    `currency` = S.currency,
    `valid_from` = S.valid_from,
    `valid_to` = S.valid_to,
    `created_on` = S.created_on
WHEN NOT MATCHED THEN
  INSERT (
    `quote_id`,
    `quote_number`,
    `opportunity_id`,
    `customer_id`,
    `status`,
    `total_amount`,
    `currency`,
    `valid_from`,
    `valid_to`,
    `created_on`
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


-- Load data into Curated.quote_detail
MERGE `Curated.quote_detail` AS T
USING `Raw.stg_quote_detail` AS S
ON T.quote_detail_id = S.quote_detail_id
WHEN MATCHED THEN
  UPDATE SET
    `quote_id` = S.quote_id,
    `product_name` = S.product_name,
    `product_category` = S.product_category,
    `quantity` = S.quantity,
    `unit_price` = S.unit_price,
    `discount` = S.discount,
    `total_amount` = S.total_amount
WHEN NOT MATCHED THEN
  INSERT (
    `quote_detail_id`,
    `quote_id`,
    `product_name`,
    `product_category`,
    `quantity`,
    `unit_price`,
    `discount`,
    `total_amount`
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