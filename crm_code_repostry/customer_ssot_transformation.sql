/*
    Google Standard SQL (BigQuery) Transformation Script
    ======================================================

    This script implements the end-to-end transformation logic for the Customer Single Source of Truth (SSOT)
    data platform. It processes raw data from staging tables (stg_*) and loads it into curated,
    analytics-ready tables (customer, lead, opportunity, quote, quote_detail) using an incremental
    SCD Type 1 merge pattern.

    The script is designed to be idempotent and production-ready, incorporating:
    - Modular procedures for each target entity.
    - Data quality checks (uniqueness, not null, referential integrity, financial integrity).
    - Isolation of invalid records into corresponding error tables.
    - Dynamic SQL to allow for configuration of project and dataset names.
    - Creation of all necessary target and error tables if they do not exist.
    - Partitioning and clustering on curated tables as per the design document.

    Execution Order:
    1.  sp_load_customer
    2.  sp_load_lead
    3.  sp_load_opportunity
    4.  sp_load_quote_detail
    5.  sp_load_quote
*/

-- =================================================================================================
-- Configuration
-- =================================================================================================
-- Define project and dataset variables. Replace default values as needed.
DECLARE bq_project_id STRING DEFAULT 'your-gcp-project-id';
DECLARE bq_raw_dataset STRING DEFAULT 'Raw';
DECLARE bq_curated_dataset STRING DEFAULT 'Curated';

-- =================================================================================================
-- Data Definition Language (DDL)
-- =================================================================================================
-- Create curated and error tables if they do not already exist.

EXECUTE IMMEDIATE FORMAT("""
--
-- Curated Table: customer
--
CREATE TABLE IF NOT EXISTS `%s.%s.customer` (
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
OPTIONS(
    description="Curated dimension table for customer information.",
    labels=[("domain", "sales"), ("layer", "gold")]
)
CLUSTER BY customer_type, industry;

--
-- Error Table: err_customer
--
CREATE TABLE IF NOT EXISTS `%s.%s.err_customer` (
    customer_id STRING, customer_type STRING, name STRING, company_name STRING, industry STRING, email STRING, phone STRING, website STRING,
    address_line1 STRING, address_line2 STRING, city STRING, state STRING, country STRING, postal_code STRING, created_on TIMESTAMP,
    modified_on TIMESTAMP, is_active BOOL,
    error_reason STRING, error_timestamp TIMESTAMP
)
OPTIONS(description="Stores records from stg_customer that failed validation.", labels=[("layer", "gold_error")]);

--
-- Curated Table: lead
--
CREATE TABLE IF NOT EXISTS `%s.%s.lead` (
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
    description="Curated table for leads, representing potential sales opportunities.",
    labels=[("domain", "sales"), ("layer", "gold")],
    partition_expiration_days=4000
);

--
-- Error Table: err_lead
--
CREATE TABLE IF NOT EXISTS `%s.%s.err_lead` (
    lead_id STRING, topic STRING, first_name STRING, last_name STRING, company_name STRING, email STRING, phone STRING, lead_source STRING,
    status STRING, customer_id STRING, created_on TIMESTAMP, qualified_on TIMESTAMP, owner_id STRING,
    error_reason STRING, error_timestamp TIMESTAMP
)
OPTIONS(description="Stores records from stg_lead that failed validation.", labels=[("layer", "gold_error")]);

--
-- Curated Table: opportunity
--
CREATE TABLE IF NOT EXISTS `%s.%s.opportunity` (
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
    description="Curated table for sales opportunities in the active sales pipeline.",
    labels=[("domain", "sales"), ("layer", "gold")],
    partition_expiration_days=4000
);

--
-- Error Table: err_opportunity
--
CREATE TABLE IF NOT EXISTS `%s.%s.err_opportunity` (
    opportunity_id STRING, name STRING, customer_id STRING, originating_lead_id STRING, stage STRING, status STRING, estimated_value FLOAT64,
    probability FLOAT64, close_date DATE, created_on TIMESTAMP, owner_id STRING,
    error_reason STRING, error_timestamp TIMESTAMP
)
OPTIONS(description="Stores records from stg_opportunity that failed validation.", labels=[("layer", "gold_error")]);

--
-- Curated Table: quote_detail
--
CREATE TABLE IF NOT EXISTS `%s.%s.quote_detail` (
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
    description="Curated table for individual line items of sales quotes.",
    labels=[("domain", "sales"), ("layer", "gold")]
);

--
-- Error Table: err_quote_detail
--
CREATE TABLE IF NOT EXISTS `%s.%s.err_quote_detail` (
    quote_detail_id STRING, quote_id STRING, product_name STRING, product_category STRING, quantity INT64, unit_price FLOAT64, discount FLOAT64, total_amount FLOAT64,
    error_reason STRING, error_timestamp TIMESTAMP
)
OPTIONS(description="Stores records from stg_quote_detail that failed validation.", labels=[("layer", "gold_error")]);

--
-- Curated Table: quote
--
CREATE TABLE IF NOT EXISTS `%s.%s.quote` (
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
    description="Curated table for header-level information of sales quotes.",
    labels=[("domain", "sales"), ("layer", "gold")],
    partition_expiration_days=4000
);

--
-- Error Table: err_quote
--
CREATE TABLE IF NOT EXISTS `%s.%s.err_quote` (
    quote_id STRING, quote_number STRING, opportunity_id STRING, customer_id STRING, status STRING, total_amount FLOAT64, currency STRING,
    valid_from DATE, valid_to DATE, created_on TIMESTAMP,
    error_reason STRING, error_timestamp TIMESTAMP
)
OPTIONS(description="Stores records from stg_quote that failed validation.", labels=[("layer", "gold_error")]);

""", bq_project_id, bq_curated_dataset, bq_project_id, bq_curated_dataset, bq_project_id, bq_curated_dataset, bq_project_id, bq_curated_dataset, bq_project_id, bq_curated_dataset, bq_project_id, bq_curated_dataset, bq_project_id, bq_curated_dataset, bq_project_id, bq_curated_dataset, bq_project_id, bq_curated_dataset, bq_project_id, bq_curated_dataset);


-- =================================================================================================
-- Stored Procedures for Transformation Logic
-- =================================================================================================

CREATE OR REPLACE PROCEDURE `${bq_project_id}.${bq_curated_dataset}.sp_load_customer`(
    p_project_id STRING, p_raw_dataset STRING, p_curated_dataset STRING
)
BEGIN
    -- This procedure loads data from stg_customer into the curated customer table.
    -- It deduplicates records, validates them, and performs an SCD Type 1 merge.
    EXECUTE IMMEDIATE FORMAT("""
    BEGIN
        -- Step 1: Validate source data and insert failures into the error table.
        INSERT INTO `%s.%s.err_customer` (
            customer_id, customer_type, name, company_name, industry, email, phone, website, address_line1, address_line2, city, state, country, postal_code, created_on, modified_on, is_active,
            error_reason, error_timestamp
        )
        WITH
          source_data AS (
            SELECT *, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY modified_on DESC) as row_num
            FROM `%s.%s.stg_customer`
          ),
          deduped_source AS (
            SELECT * EXCEPT(row_num) FROM source_data WHERE row_num = 1
          ),
          validated_source AS (
            SELECT
              s.*,
              CASE
                WHEN s.customer_id IS NULL THEN 'Primary key customer_id is NULL'
                ELSE NULL
              END AS error_reason
            FROM deduped_source s
          )
        SELECT
            s.customer_id, s.customer_type, s.name, s.company_name, s.industry, s.email, s.phone, s.website, s.address_line1, s.address_line2, s.city, s.state, s.country, s.postal_code, s.created_on, s.modified_on, s.is_active,
            s.error_reason,
            CURRENT_TIMESTAMP() AS error_timestamp
        FROM validated_source s
        WHERE s.error_reason IS NOT NULL;

        -- Step 2: Merge valid, deduplicated data into the curated table.
        MERGE INTO `%s.%s.customer` T
        USING (
            WITH
              source_data AS (
                SELECT *, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY modified_on DESC) as row_num
                FROM `%s.%s.stg_customer`
              ),
              deduped_source AS (
                SELECT * EXCEPT(row_num) FROM source_data WHERE row_num = 1
              ),
              validated_source AS (
                SELECT
                  s.*,
                  CASE
                    WHEN s.customer_id IS NULL THEN 'Primary key customer_id is NULL'
                    ELSE NULL
                  END AS error_reason
                FROM deduped_source s
              )
            SELECT * FROM validated_source WHERE error_reason IS NULL
        ) S
        ON T.customer_id = S.customer_id
        WHEN MATCHED AND
             FARM_FINGERPRINT(TO_JSON_STRING((SELECT AS STRUCT T.* EXCEPT(customer_id)))) <> FARM_FINGERPRINT(TO_JSON_STRING((SELECT AS STRUCT S.customer_type, S.name, S.company_name, S.industry, S.email, S.phone, S.website, S.address_line1, S.address_line2, S.city, S.state, S.country, S.postal_code, S.created_on, S.modified_on, S.is_active))))
        THEN
            UPDATE SET
                T.customer_type = S.customer_type, T.name = S.name, T.company_name = S.company_name, T.industry = S.industry, T.email = S.email, T.phone = S.phone, T.website = S.website,
                T.address_line1 = S.address_line1, T.address_line2 = S.address_line2, T.city = S.city, T.state = S.state, T.country = S.country, T.postal_code = S.postal_code,
                T.created_on = S.created_on, T.modified_on = S.modified_on, T.is_active = S.is_active
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                customer_id, customer_type, name, company_name, industry, email, phone, website, address_line1, address_line2, city, state, country, postal_code, created_on, modified_on, is_active
            ) VALUES (
                S.customer_id, S.customer_type, S.name, S.company_name, S.industry, S.email, S.phone, S.website, S.address_line1, S.address_line2, S.city, S.state, S.country, S.postal_code, S.created_on, S.modified_on, S.is_active
            );
    END;
    """, p_project_id, p_curated_dataset, p_project_id, p_raw_dataset, p_project_id, p_curated_dataset, p_project_id, p_raw_dataset);
END;


CREATE OR REPLACE PROCEDURE `${bq_project_id}.${bq_curated_dataset}.sp_load_lead`(
    p_project_id STRING, p_raw_dataset STRING, p_curated_dataset STRING
)
BEGIN
    -- This procedure loads data from stg_lead into the curated lead table.
    -- It performs deduplication, validation (including referential integrity), and an SCD Type 1 merge.
    EXECUTE IMMEDIATE FORMAT("""
    BEGIN
        -- Step 1: Validate source data and insert failures into the error table.
        INSERT INTO `%s.%s.err_lead` (
            lead_id, topic, first_name, last_name, company_name, email, phone, lead_source, status, customer_id, created_on, qualified_on, owner_id,
            error_reason, error_timestamp
        )
        WITH
          source_data AS (
            SELECT *, ROW_NUMBER() OVER(PARTITION BY lead_id ORDER BY created_on DESC) as row_num
            FROM `%s.%s.stg_lead`
          ),
          deduped_source AS (
            SELECT * EXCEPT(row_num) FROM source_data WHERE row_num = 1
          ),
          validated_source AS (
            SELECT
              s.*,
              CASE
                WHEN s.lead_id IS NULL THEN 'Primary key lead_id is NULL'
                WHEN s.customer_id IS NOT NULL AND c.customer_id IS NULL THEN 'Referential integrity failed: customer_id not found in curated.customer'
                ELSE NULL
              END AS error_reason
            FROM deduped_source s
            LEFT JOIN `%s.%s.customer` c ON s.customer_id = c.customer_id
          )
        SELECT
            s.lead_id, s.topic, s.first_name, s.last_name, s.company_name, s.email, s.phone, s.lead_source, s.status, s.customer_id, s.created_on, s.qualified_on, s.owner_id,
            s.error_reason,
            CURRENT_TIMESTAMP() AS error_timestamp
        FROM validated_source s
        WHERE s.error_reason IS NOT NULL;

        -- Step 2: Merge valid, deduplicated data into the curated table.
        MERGE INTO `%s.%s.lead` T
        USING (
            WITH
              source_data AS (
                SELECT *, ROW_NUMBER() OVER(PARTITION BY lead_id ORDER BY created_on DESC) as row_num
                FROM `%s.%s.stg_lead`
              ),
              deduped_source AS (
                SELECT * EXCEPT(row_num) FROM source_data WHERE row_num = 1
              ),
              validated_source AS (
                SELECT
                  s.*,
                  CASE
                    WHEN s.lead_id IS NULL THEN 'Primary key lead_id is NULL'
                    WHEN s.customer_id IS NOT NULL AND c.customer_id IS NULL THEN 'Referential integrity failed: customer_id not found in curated.customer'
                    ELSE NULL
                  END AS error_reason
                FROM deduped_source s
                LEFT JOIN `%s.%s.customer` c ON s.customer_id = c.customer_id
              )
            SELECT * FROM validated_source WHERE error_reason IS NULL
        ) S
        ON T.lead_id = S.lead_id
        WHEN MATCHED AND
             FARM_FINGERPRINT(TO_JSON_STRING((SELECT AS STRUCT T.* EXCEPT(lead_id)))) <> FARM_FINGERPRINT(TO_JSON_STRING((SELECT AS STRUCT S.topic, S.first_name, S.last_name, S.company_name, S.email, S.phone, S.lead_source, S.status, S.customer_id, S.created_on, S.qualified_on, S.owner_id)))
        THEN
            UPDATE SET
                T.topic = S.topic, T.first_name = S.first_name, T.last_name = S.last_name, T.company_name = S.company_name, T.email = S.email, T.phone = S.phone,
                T.lead_source = S.lead_source, T.status = S.status, T.customer_id = S.customer_id, T.created_on = S.created_on, T.qualified_on = S.qualified_on, T.owner_id = S.owner_id
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                lead_id, topic, first_name, last_name, company_name, email, phone, lead_source, status, customer_id, created_on, qualified_on, owner_id
            ) VALUES (
                S.lead_id, S.topic, S.first_name, S.last_name, S.company_name, S.email, S.phone, S.lead_source, S.status, S.customer_id, S.created_on, S.qualified_on, S.owner_id
            );
    END;
    """, p_project_id, p_curated_dataset, p_project_id, p_raw_dataset, p_project_id, p_curated_dataset, p_project_id, p_curated_dataset, p_project_id, p_raw_dataset, p_project_id, p_curated_dataset);
END;


CREATE OR REPLACE PROCEDURE `${bq_project_id}.${bq_curated_dataset}.sp_load_opportunity`(
    p_project_id STRING, p_raw_dataset STRING, p_curated_dataset STRING
)
BEGIN
    -- This procedure loads data from stg_opportunity into the curated opportunity table.
    -- It performs deduplication, validation (including referential integrity), and an SCD Type 1 merge.
    EXECUTE IMMEDIATE FORMAT("""
    BEGIN
        -- Step 1: Validate source data and insert failures into the error table.
        INSERT INTO `%s.%s.err_opportunity` (
            opportunity_id, name, customer_id, originating_lead_id, stage, status, estimated_value, probability, close_date, created_on, owner_id,
            error_reason, error_timestamp
        )
        WITH
          source_data AS (
            SELECT *, ROW_NUMBER() OVER(PARTITION BY opportunity_id ORDER BY created_on DESC) as row_num
            FROM `%s.%s.stg_opportunity`
          ),
          deduped_source AS (
            SELECT * EXCEPT(row_num) FROM source_data WHERE row_num = 1
          ),
          validated_source AS (
            SELECT
              s.*,
              CASE
                WHEN s.opportunity_id IS NULL THEN 'Primary key opportunity_id is NULL'
                WHEN s.customer_id IS NOT NULL AND c.customer_id IS NULL THEN 'Referential integrity failed: customer_id not found in curated.customer'
                WHEN s.originating_lead_id IS NOT NULL AND l.lead_id IS NULL THEN 'Referential integrity failed: originating_lead_id not found in curated.lead'
                ELSE NULL
              END AS error_reason
            FROM deduped_source s
            LEFT JOIN `%s.%s.customer` c ON s.customer_id = c.customer_id
            LEFT JOIN `%s.%s.lead` l ON s.originating_lead_id = l.lead_id
          )
        SELECT
            s.opportunity_id, s.name, s.customer_id, s.originating_lead_id, s.stage, s.status, s.estimated_value, s.probability, s.close_date, s.created_on, s.owner_id,
            s.error_reason,
            CURRENT_TIMESTAMP() AS error_timestamp
        FROM validated_source s
        WHERE s.error_reason IS NOT NULL;

        -- Step 2: Merge valid, deduplicated data into the curated table.
        MERGE INTO `%s.%s.opportunity` T
        USING (
            WITH
              source_data AS (
                SELECT *, ROW_NUMBER() OVER(PARTITION BY opportunity_id ORDER BY created_on DESC) as row_num
                FROM `%s.%s.stg_opportunity`
              ),
              deduped_source AS (
                SELECT * EXCEPT(row_num) FROM source_data WHERE row_num = 1
              ),
              validated_source AS (
                SELECT
                  s.*,
                  CASE
                    WHEN s.opportunity_id IS NULL THEN 'Primary key opportunity_id is NULL'
                    WHEN s.customer_id IS NOT NULL AND c.customer_id IS NULL THEN 'Referential integrity failed: customer_id not found in curated.customer'
                    WHEN s.originating_lead_id IS NOT NULL AND l.lead_id IS NULL THEN 'Referential integrity failed: originating_lead_id not found in curated.lead'
                    ELSE NULL
                  END AS error_reason
                FROM deduped_source s
                LEFT JOIN `%s.%s.customer` c ON s.customer_id = c.customer_id
                LEFT JOIN `%s.%s.lead` l ON s.originating_lead_id = l.lead_id
              )
            SELECT * FROM validated_source WHERE error_reason IS NULL
        ) S
        ON T.opportunity_id = S.opportunity_id
        WHEN MATCHED AND
             FARM_FINGERPRINT(TO_JSON_STRING((SELECT AS STRUCT T.* EXCEPT(opportunity_id)))) <> FARM_FINGERPRINT(TO_JSON_STRING((SELECT AS STRUCT S.name, S.customer_id, S.originating_lead_id, S.stage, S.status, S.estimated_value, S.probability, S.close_date, S.created_on, S.owner_id)))
        THEN
            UPDATE SET
                T.name = S.name, T.customer_id = S.customer_id, T.originating_lead_id = S.originating_lead_id, T.stage = S.stage, T.status = S.status,
                T.estimated_value = S.estimated_value, T.probability = S.probability, T.close_date = S.close_date, T.created_on = S.created_on, T.owner_id = S.owner_id
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                opportunity_id, name, customer_id, originating_lead_id, stage, status, estimated_value, probability, close_date, created_on, owner_id
            ) VALUES (
                S.opportunity_id, S.name, S.customer_id, S.originating_lead_id, S.stage, S.status, S.estimated_value, S.probability, S.close_date, S.created_on, S.owner_id
            );
    END;
    """, p_project_id, p_curated_dataset, p_project_id, p_raw_dataset, p_project_id, p_curated_dataset, p_project_id, p_curated_dataset, p_project_id, p_curated_dataset, p_project_id, p_raw_dataset, p_project_id, p_curated_dataset, p_project_id, p_curated_dataset);
END;


CREATE OR REPLACE PROCEDURE `${bq_project_id}.${bq_curated_dataset}.sp_load_quote_detail`(
    p_project_id STRING, p_raw_dataset STRING, p_curated_dataset STRING
)
BEGIN
    -- This procedure loads data from stg_quote_detail into the curated quote_detail table.
    -- It performs deduplication, validation, and an SCD Type 1 merge.
    EXECUTE IMMEDIATE FORMAT("""
    BEGIN
        -- Step 1: Validate source data and insert failures into the error table.
        INSERT INTO `%s.%s.err_quote_detail` (
            quote_detail_id, quote_id, product_name, product_category, quantity, unit_price, discount, total_amount,
            error_reason, error_timestamp
        )
        WITH
          source_data AS (
            -- No timestamp for ordering, using stable keys for deterministic deduplication.
            SELECT *, ROW_NUMBER() OVER(PARTITION BY quote_detail_id ORDER BY quote_id, product_name) as row_num
            FROM `%s.%s.stg_quote_detail`
          ),
          deduped_source AS (
            SELECT * EXCEPT(row_num) FROM source_data WHERE row_num = 1
          ),
          validated_source AS (
            SELECT
              s.*,
              CASE
                WHEN s.quote_detail_id IS NULL THEN 'Primary key quote_detail_id is NULL'
                WHEN s.quote_id IS NULL THEN 'Foreign key quote_id is NULL'
                ELSE NULL
              END AS error_reason
            FROM deduped_source s
          )
        SELECT
            s.quote_detail_id, s.quote_id, s.product_name, s.product_category, s.quantity, s.unit_price, s.discount, s.total_amount,
            s.error_reason,
            CURRENT_TIMESTAMP() AS error_timestamp
        FROM validated_source s
        WHERE s.error_reason IS NOT NULL;

        -- Step 2: Merge valid, deduplicated data into the curated table.
        MERGE INTO `%s.%s.quote_detail` T
        USING (
            WITH
              source_data AS (
                SELECT *, ROW_NUMBER() OVER(PARTITION BY quote_detail_id ORDER BY quote_id, product_name) as row_num
                FROM `%s.%s.stg_quote_detail`
              ),
              deduped_source AS (
                SELECT * EXCEPT(row_num) FROM source_data WHERE row_num = 1
              ),
              validated_source AS (
                SELECT
                  s.*,
                  CASE
                    WHEN s.quote_detail_id IS NULL THEN 'Primary key quote_detail_id is NULL'
                    WHEN s.quote_id IS NULL THEN 'Foreign key quote_id is NULL'
                    ELSE NULL
                  END AS error_reason
                FROM deduped_source s
              )
            SELECT * FROM validated_source WHERE error_reason IS NULL
        ) S
        ON T.quote_detail_id = S.quote_detail_id
        WHEN MATCHED AND
             FARM_FINGERPRINT(TO_JSON_STRING((SELECT AS STRUCT T.* EXCEPT(quote_detail_id)))) <> FARM_FINGERPRINT(TO_JSON_STRING((SELECT AS STRUCT S.quote_id, S.product_name, S.product_category, S.quantity, S.unit_price, S.discount, S.total_amount)))
        THEN
            UPDATE SET
                T.quote_id = S.quote_id, T.product_name = S.product_name, T.product_category = S.product_category, T.quantity = S.quantity,
                T.unit_price = S.unit_price, T.discount = S.discount, T.total_amount = S.total_amount
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                quote_detail_id, quote_id, product_name, product_category, quantity, unit_price, discount, total_amount
            ) VALUES (
                S.quote_detail_id, S.quote_id, S.product_name, S.product_category, S.quantity, S.unit_price, S.discount, S.total_amount
            );
    END;
    """, p_project_id, p_curated_dataset, p_project_id, p_raw_dataset, p_project_id, p_curated_dataset, p_project_id, p_raw_dataset);
END;


CREATE OR REPLACE PROCEDURE `${bq_project_id}.${bq_curated_dataset}.sp_load_quote`(
    p_project_id STRING, p_raw_dataset STRING, p_curated_dataset STRING
)
BEGIN
    -- This procedure loads data from stg_quote into the curated quote table.
    -- It performs deduplication, validation (RI and financial integrity), and an SCD Type 1 merge.
    EXECUTE IMMEDIATE FORMAT("""
    BEGIN
        -- Step 1: Validate source data and insert failures into the error table.
        INSERT INTO `%s.%s.err_quote` (
            quote_id, quote_number, opportunity_id, customer_id, status, total_amount, currency, valid_from, valid_to, created_on,
            error_reason, error_timestamp
        )
        WITH
          quote_detail_agg AS (
            SELECT
              quote_id,
              SUM(total_amount) AS calculated_total_amount
            FROM `%s.%s.stg_quote_detail`
            WHERE quote_id IS NOT NULL
            GROUP BY quote_id
          ),
          source_data AS (
            SELECT *, ROW_NUMBER() OVER(PARTITION BY quote_id ORDER BY created_on DESC) as row_num
            FROM `%s.%s.stg_quote`
          ),
          deduped_source AS (
            SELECT * EXCEPT(row_num) FROM source_data WHERE row_num = 1
          ),
          validated_source AS (
            SELECT
              s.*,
              CASE
                WHEN s.quote_id IS NULL THEN 'Primary key quote_id is NULL'
                WHEN s.customer_id IS NOT NULL AND c.customer_id IS NULL THEN 'Referential integrity failed: customer_id not found in curated.customer'
                WHEN s.opportunity_id IS NOT NULL AND o.opportunity_id IS NULL THEN 'Referential integrity failed: opportunity_id not found in curated.opportunity'
                WHEN ABS(s.total_amount - COALESCE(qda.calculated_total_amount, 0)) > 0.01 THEN 'Financial integrity failed: Header total_amount does not match sum of line item totals'
                ELSE NULL
              END AS error_reason
            FROM deduped_source s
            LEFT JOIN `%s.%s.customer` c ON s.customer_id = c.customer_id
            LEFT JOIN `%s.%s.opportunity` o ON s.opportunity_id = o.opportunity_id
            LEFT JOIN quote_detail_agg qda ON s.quote_id = qda.quote_id
          )
        SELECT
            s.quote_id, s.quote_number, s.opportunity_id, s.customer_id, s.status, s.total_amount, s.currency, s.valid_from, s.valid_to, s.created_on,
            s.error_reason,
            CURRENT_TIMESTAMP() AS error_timestamp
        FROM validated_source s
        WHERE s.error_reason IS NOT NULL;

        -- Step 2: Merge valid, deduplicated data into the curated table.
        MERGE INTO `%s.%s.quote` T
        USING (
            WITH
              quote_detail_agg AS (
                SELECT
                  quote_id,
                  SUM(total_amount) AS calculated_total_amount
                FROM `%s.%s.stg_quote_detail`
                WHERE quote_id IS NOT NULL
                GROUP BY quote_id
              ),
              source_data AS (
                SELECT *, ROW_NUMBER() OVER(PARTITION BY quote_id ORDER BY created_on DESC) as row_num
                FROM `%s.%s.stg_quote`
              ),
              deduped_source AS (
                SELECT * EXCEPT(row_num) FROM source_data WHERE row_num = 1
              ),
              validated_source AS (
                SELECT
                  s.*,
                  CASE
                    WHEN s.quote_id IS NULL THEN 'Primary key quote_id is NULL'
                    WHEN s.customer_id IS NOT NULL AND c.customer_id IS NULL THEN 'Referential integrity failed: customer_id not found in curated.customer'
                    WHEN s.opportunity_id IS NOT NULL AND o.opportunity_id IS NULL THEN 'Referential integrity failed: opportunity_id not found in curated.opportunity'
                    WHEN ABS(s.total_amount - COALESCE(qda.calculated_total_amount, 0)) > 0.01 THEN 'Financial integrity failed: Header total_amount does not match sum of line item totals'
                    ELSE NULL
                  END AS error_reason
                FROM deduped_source s
                LEFT JOIN `%s.%s.customer` c ON s.customer_id = c.customer_id
                LEFT JOIN `%s.%s.opportunity` o ON s.opportunity_id = o.opportunity_id
                LEFT JOIN quote_detail_agg qda ON s.quote_id = qda.quote_id
              )
            SELECT * FROM validated_source WHERE error_reason IS NULL
        ) S
        ON T.quote_id = S.quote_id
        WHEN MATCHED AND
             FARM_FINGERPRINT(TO_JSON_STRING((SELECT AS STRUCT T.* EXCEPT(quote_id)))) <> FARM_FINGERPRINT(TO_JSON_STRING((SELECT AS STRUCT S.quote_number, S.opportunity_id, S.customer_id, S.status, S.total_amount, S.currency, S.valid_from, S.valid_to, S.created_on)))
        THEN
            UPDATE SET
                T.quote_number = S.quote_number, T.opportunity_id = S.opportunity_id, T.customer_id = S.customer_id, T.status = S.status, T.total_amount = S.total_amount,
                T.currency = S.currency, T.valid_from = S.valid_from, T.valid_to = S.valid_to, T.created_on = S.created_on
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                quote_id, quote_number, opportunity_id, customer_id, status, total_amount, currency, valid_from, valid_to, created_on
            ) VALUES (
                S.quote_id, S.quote_number, S.opportunity_id, S.customer_id, S.status, S.total_amount, S.currency, S.valid_from, S.valid_to, S.created_on
            );
    END;
    """, p_project_id, p_curated_dataset, p_project_id, p_raw_dataset, p_project_id, p_raw_dataset, p_project_id, p_curated_dataset, p_project_id, p_curated_dataset, p_project_id, p_curated_dataset, p_project_id, p_raw_dataset, p_project_id, p_raw_dataset, p_project_id, p_curated_dataset, p_project_id, p_curated_dataset);
END;


-- =================================================================================================
-- Main Execution Block
-- =================================================================================================
-- Call the stored procedures in the correct order of dependency to populate the curated tables.
BEGIN
    CALL `${bq_project_id}.${bq_curated_dataset}.sp_load_customer`(bq_project_id, bq_raw_dataset, bq_curated_dataset);
    CALL `${bq_project_id}.${bq_curated_dataset}.sp_load_lead`(bq_project_id, bq_raw_dataset, bq_curated_dataset);
    CALL `${bq_project_id}.${bq_curated_dataset}.sp_load_opportunity`(bq_project_id, bq_raw_dataset, bq_curated_dataset);
    CALL `${bq_project_id}.${bq_curated_dataset}.sp_load_quote_detail`(bq_project_id, bq_raw_dataset, bq_curated_dataset);
    CALL `${bq_project_id}.${bq_curated_dataset}.sp_load_quote`(bq_project_id, bq_raw_dataset, bq_curated_dataset);
END;