/*
  This script contains the stored procedures to create and populate the curated
  Customer Single Source of Truth (SSOT) tables in Google BigQuery.

  It implements an SCD Type 1 (overwrite) load pattern using MERGE statements.
  Each procedure is designed to be idempotent and can be run repeatedly.

  Instructions:
  1. Replace `your_project_id` with your Google Cloud project ID.
  2. Replace `curated_dataset` with the name of your target BigQuery dataset for curated data.
  3. Replace `staging_dataset` with the name of your BigQuery dataset containing the raw staging tables.
  4. Execute this script to create the stored procedures in your BigQuery project.
  5. Call each procedure (e.g., `CALL your_project_id.curated_dataset.sp_load_dim_account();`)
     to execute the data load for each table.
*/

-- ============================================================================
-- Procedure: sp_load_dim_account
-- Description: Loads data into the dim_account table.
-- ============================================================================
CREATE OR REPLACE PROCEDURE `your_project_id.curated_dataset.sp_load_dim_account`()
BEGIN
  CREATE TABLE IF NOT EXISTS `your_project_id.curated_dataset.dim_account`
  (
    accountid STRING OPTIONS(description="The unique identifier for the account, serving as the primary key."),
    name STRING OPTIONS(description="The legal name of the account or company, used for identification and reporting."),
    address1_city STRING OPTIONS(description="The city component of the account's primary address, used for geographic analysis."),
    address1_state STRING OPTIONS(description="The state or province component of the account's primary address, used for regional segmentation."),
    region STRING OPTIONS(description="The geographical region to which the account belongs, often used for sales territory analysis.")
  )
  OPTIONS(
    description="This dimension table stores information about accounts, which are typically organizations or companies."
  );

  MERGE `your_project_id.curated_dataset.dim_account` T
  USING (
    WITH latest_records AS (
      SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY accountid ORDER BY _metadata_load_timestamp DESC) as rn
      FROM `your_project_id.staging_dataset.stg_account`
      WHERE accountid IS NOT NULL
    )
    SELECT
      accountid,
      name,
      address1_city,
      address1_state,
      region
    FROM latest_records
    WHERE rn = 1
  ) S
  ON T.accountid = S.accountid
  WHEN MATCHED THEN
    UPDATE SET
      T.name = S.name,
      T.address1_city = S.address1_city,
      T.address1_state = S.address1_state,
      T.region = S.region
  WHEN NOT MATCHED THEN
    INSERT (accountid, name, address1_city, address1_state, region)
    VALUES (S.accountid, S.name, S.address1_city, S.address1_state, S.region);
END;


-- ============================================================================
-- Procedure: sp_load_dim_customer
-- Description: Loads data into the dim_customer table.
-- ============================================================================
CREATE OR REPLACE PROCEDURE `your_project_id.curated_dataset.sp_load_dim_customer`()
BEGIN
  CREATE TABLE IF NOT EXISTS `your_project_id.curated_dataset.dim_customer`
  (
    customerid STRING OPTIONS(description="The unique identifier for the customer, serving as the primary key."),
    accountid STRING OPTIONS(description="The foreign key linking the customer to their associated account in the dim_account table."),
    name STRING OPTIONS(description="The full name of the customer, used for personalization and reporting."),
    telephone1 STRING OPTIONS(description="The primary telephone number for the customer, used for contact purposes."),
    industry STRING OPTIONS(description="The industry in which the customer operates, useful for market segmentation."),
    region STRING OPTIONS(description="The geographical region to which the customer belongs, used for localized marketing and sales analysis.")
  )
  OPTIONS(
    description="This dimension table contains details about individual customers or contacts."
  );

  MERGE `your_project_id.curated_dataset.dim_customer` T
  USING (
    WITH latest_records AS (
      SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY customerid ORDER BY _metadata_load_timestamp DESC) as rn
      FROM `your_project_id.staging_dataset.stg_customer`
      WHERE customerid IS NOT NULL
    )
    SELECT
      customerid,
      accountid,
      name,
      telephone1,
      industry,
      region
    FROM latest_records
    WHERE rn = 1
  ) S
  ON T.customerid = S.customerid
  WHEN MATCHED THEN
    UPDATE SET
      T.accountid = S.accountid,
      T.name = S.name,
      T.telephone1 = S.telephone1,
      T.industry = S.industry,
      T.region = S.region
  WHEN NOT MATCHED THEN
    INSERT (customerid, accountid, name, telephone1, industry, region)
    VALUES (S.customerid, S.accountid, S.name, S.telephone1, S.industry, S.region);
END;


-- ============================================================================
-- Procedure: sp_load_dim_lead
-- Description: Loads data into the dim_lead table.
-- ============================================================================
CREATE OR REPLACE PROCEDURE `your_project_id.curated_dataset.sp_load_dim_lead`()
BEGIN
  CREATE TABLE IF NOT EXISTS `your_project_id.curated_dataset.dim_lead`
  (
    leadid STRING OPTIONS(description="The unique identifier for the lead, serving as the primary key."),
    customerid STRING OPTIONS(description="The foreign key linking the lead to a customer record if the lead has been converted."),
    accountid STRING OPTIONS(description="The foreign key linking the lead to an account record."),
    statuscode STRING OPTIONS(description="A code representing the current status of the lead in the sales process."),
    createdon DATE OPTIONS(description="The date when the lead was created in the source system.")
  )
  OPTIONS(
    description="This dimension table stores information about sales leads."
  );

  MERGE `your_project_id.curated_dataset.dim_lead` T
  USING (
    WITH latest_records AS (
      SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY leadid ORDER BY _metadata_load_timestamp DESC) as rn
      FROM `your_project_id.staging_dataset.stg_lead`
      WHERE leadid IS NOT NULL
    )
    SELECT
      leadid,
      customerid,
      accountid,
      statuscode,
      SAFE_CAST(createdon AS DATE) AS createdon
    FROM latest_records
    WHERE rn = 1
  ) S
  ON T.leadid = S.leadid
  WHEN MATCHED THEN
    UPDATE SET
      T.customerid = S.customerid,
      T.accountid = S.accountid,
      T.statuscode = S.statuscode,
      T.createdon = S.createdon
  WHEN NOT MATCHED THEN
    INSERT (leadid, customerid, accountid, statuscode, createdon)
    VALUES (S.leadid, S.customerid, S.accountid, S.statuscode, S.createdon);
END;


-- ============================================================================
-- Procedure: sp_load_dim_opportunity
-- Description: Loads data into the dim_opportunity table.
-- ============================================================================
CREATE OR REPLACE PROCEDURE `your_project_id.curated_dataset.sp_load_dim_opportunity`()
BEGIN
  CREATE TABLE IF NOT EXISTS `your_project_id.curated_dataset.dim_opportunity`
  (
    opportunityid STRING OPTIONS(description="The unique identifier for the opportunity, serving as the primary key."),
    leadid STRING OPTIONS(description="The foreign key linking the opportunity to the originating lead."),
    customerid STRING OPTIONS(description="The foreign key linking the opportunity to the primary customer."),
    accountid STRING OPTIONS(description="The foreign key linking the opportunity to the customer's account."),
    salesrepid STRING OPTIONS(description="The foreign key identifying the sales representative responsible for the opportunity."),
    statuscode STRING OPTIONS(description="A code representing the current status of the opportunity (e.g., 'In Progress', 'Won', 'Lost')."),
    createdon DATE OPTIONS(description="The date when the opportunity was created."),
    estimatedvalue FLOAT64 OPTIONS(description="The estimated monetary value of the opportunity."),
    currencycode STRING OPTIONS(description="The ISO currency code for the estimated value.")
  )
  OPTIONS(
    description="This dimension table holds data about sales opportunities."
  );

  MERGE `your_project_id.curated_dataset.dim_opportunity` T
  USING (
    WITH latest_records AS (
      SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY opportunityid ORDER BY _metadata_load_timestamp DESC) as rn
      FROM `your_project_id.staging_dataset.stg_opportunity`
      WHERE opportunityid IS NOT NULL
    )
    SELECT
      opportunityid,
      leadid,
      customerid,
      accountid,
      salesrepid,
      statuscode,
      SAFE_CAST(createdon AS DATE) AS createdon,
      SAFE_CAST(estimatedvalue AS FLOAT64) AS estimatedvalue,
      currencycode
    FROM latest_records
    WHERE rn = 1
  ) S
  ON T.opportunityid = S.opportunityid
  WHEN MATCHED THEN
    UPDATE SET
      T.leadid = S.leadid,
      T.customerid = S.customerid,
      T.accountid = S.accountid,
      T.salesrepid = S.salesrepid,
      T.statuscode = S.statuscode,
      T.createdon = S.createdon,
      T.estimatedvalue = S.estimatedvalue,
      T.currencycode = S.currencycode
  WHEN NOT MATCHED THEN
    INSERT (opportunityid, leadid, customerid, accountid, salesrepid, statuscode, createdon, estimatedvalue, currencycode)
    VALUES (S.opportunityid, S.leadid, S.customerid, S.accountid, S.salesrepid, S.statuscode, S.createdon, S.estimatedvalue, S.currencycode);
END;


-- ============================================================================
-- Procedure: sp_load_dim_product
-- Description: Loads data into the dim_product table.
-- ============================================================================
CREATE OR REPLACE PROCEDURE `your_project_id.curated_dataset.sp_load_dim_product`()
BEGIN
  CREATE TABLE IF NOT EXISTS `your_project_id.curated_dataset.dim_product`
  (
    productid STRING OPTIONS(description="The unique identifier for the product, serving as the primary key."),
    name STRING OPTIONS(description="The name of the product, used for display and reporting."),
    category STRING OPTIONS(description="The category to which the product belongs, enabling product portfolio analysis."),
    price FLOAT64 OPTIONS(description="The standard list price of the product."),
    currencycode STRING OPTIONS(description="The ISO currency code for the product price.")
  )
  OPTIONS(
    description="This dimension table stores information about the products or services that are being sold."
  );

  MERGE `your_project_id.curated_dataset.dim_product` T
  USING (
    WITH latest_records AS (
      SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY productid ORDER BY _metadata_load_timestamp DESC) as rn
      FROM `your_project_id.staging_dataset.stg_product`
      WHERE productid IS NOT NULL
    )
    SELECT
      productid,
      name,
      category,
      SAFE_CAST(price AS FLOAT64) AS price,
      currencycode
    FROM latest_records
    WHERE rn = 1
  ) S
  ON T.productid = S.productid
  WHEN MATCHED THEN
    UPDATE SET
      T.name = S.name,
      T.category = S.category,
      T.price = S.price,
      T.currencycode = S.currencycode
  WHEN NOT MATCHED THEN
    INSERT (productid, name, category, price, currencycode)
    VALUES (S.productid, S.name, S.category, S.price, S.currencycode);
END;


-- ============================================================================
-- Procedure: sp_load_dim_sales_rep
-- Description: Loads data into the dim_sales_rep table.
-- ============================================================================
CREATE OR REPLACE PROCEDURE `your_project_id.curated_dataset.sp_load_dim_sales_rep`()
BEGIN
  CREATE TABLE IF NOT EXISTS `your_project_id.curated_dataset.dim_sales_rep`
  (
    salesrepid STRING OPTIONS(description="The unique identifier for the sales representative, serving as the primary key."),
    name STRING OPTIONS(description="The full name of the sales representative."),
    region STRING OPTIONS(description="The sales region assigned to the representative.")
  )
  OPTIONS(
    description="This dimension table contains information about the sales representatives in the organization."
  );

  MERGE `your_project_id.curated_dataset.dim_sales_rep` T
  USING (
    WITH latest_records AS (
      SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY salesrepid ORDER BY _metadata_load_timestamp DESC) as rn
      FROM `your_project_id.staging_dataset.stg_sales_rep`
      WHERE salesrepid IS NOT NULL
    )
    SELECT
      salesrepid,
      name,
      region
    FROM latest_records
    WHERE rn = 1
  ) S
  ON T.salesrepid = S.salesrepid
  WHEN MATCHED THEN
    UPDATE SET
      T.name = S.name,
      T.region = S.region
  WHEN NOT MATCHED THEN
    INSERT (salesrepid, name, region)
    VALUES (S.salesrepid, S.name, S.region);
END;


-- ============================================================================
-- Procedure: sp_load_fact_quotes
-- Description: Loads data into the fact_quotes table.
-- ============================================================================
CREATE OR REPLACE PROCEDURE `your_project_id.curated_dataset.sp_load_fact_quotes`()
BEGIN
  CREATE TABLE IF NOT EXISTS `your_project_id.curated_dataset.fact_quotes`
  (
    quoteid STRING OPTIONS(description="The unique identifier for the sales quote, serving as the primary key for this fact."),
    opportunityid STRING OPTIONS(description="The foreign key linking the quote to a sales opportunity."),
    customerid STRING OPTIONS(description="The foreign key identifying the customer who received the quote."),
    accountid STRING OPTIONS(description="The foreign key identifying the account associated with the quote."),
    salesrepid STRING OPTIONS(description="The foreign key identifying the sales representative who created the quote."),
    totalamount FLOAT64 OPTIONS(description="The total monetary value of the quote."),
    statuscode STRING OPTIONS(description="A code representing the current status of the quote (e.g., 'Draft', 'Active', 'Won')."),
    createdon TIMESTAMP OPTIONS(description="The date and time when the quote was created."),
    currencycode STRING OPTIONS(description="The ISO currency code for the quote's total amount.")
  )
  PARTITION BY DATE(createdon)
  CLUSTER BY opportunityid, customerid, accountid, salesrepid
  OPTIONS(
    description="This fact table contains transactional data related to sales quotes."
  );

  MERGE `your_project_id.curated_dataset.fact_quotes` T
  USING (
    WITH latest_records AS (
      SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY quoteid ORDER BY _metadata_load_timestamp DESC) as rn
      FROM `your_project_id.staging_dataset.stg_quote`
      WHERE quoteid IS NOT NULL
    )
    SELECT
      quoteid,
      opportunityid,
      customerid,
      accountid,
      salesrepid,
      SAFE_CAST(totalamount AS FLOAT64) AS totalamount,
      statuscode,
      SAFE_CAST(createdon AS TIMESTAMP) AS createdon,
      currencycode
    FROM latest_records
    WHERE rn = 1
  ) S
  ON T.quoteid = S.quoteid
  WHEN MATCHED THEN
    UPDATE SET
      T.opportunityid = S.opportunityid,
      T.customerid = S.customerid,
      T.accountid = S.accountid,
      T.salesrepid = S.salesrepid,
      T.totalamount = S.totalamount,
      T.statuscode = S.statuscode,
      T.createdon = S.createdon,
      T.currencycode = S.currencycode
  WHEN NOT MATCHED THEN
    INSERT (quoteid, opportunityid, customerid, accountid, salesrepid, totalamount, statuscode, createdon, currencycode)
    VALUES (S.quoteid, S.opportunityid, S.customerid, S.accountid, S.salesrepid, S.totalamount, S.statuscode, S.createdon, S.currencycode);
END;


-- ============================================================================
-- Procedure: sp_load_fact_quote_details
-- Description: Loads data into the fact_quote_details table.
-- ============================================================================
CREATE OR REPLACE PROCEDURE `your_project_id.curated_dataset.sp_load_fact_quote_details`()
BEGIN
  CREATE TABLE IF NOT EXISTS `your_project_id.curated_dataset.fact_quote_details`
  (
    quoteid STRING OPTIONS(description="The foreign key linking this detail line to the parent quote in fact_quotes."),
    productid STRING OPTIONS(description="The foreign key linking this detail line to a specific product in dim_product."),
    quantity INT64 OPTIONS(description="The number of units of the product quoted."),
    priceperunit FLOAT64 OPTIONS(description="The price per unit of the product on this quote line."),
    extendedamount FLOAT64 OPTIONS(description="The total amount for this line item (quantity * priceperunit).")
  )
  CLUSTER BY quoteid, productid
  OPTIONS(
    description="This fact table provides line-item details for each sales quote."
  );

  -- Note: The source document does not specify a primary key for quote_details.
  -- A composite key of (quoteid, productid) is assumed for the MERGE operation,
  -- which is a standard pattern for line-item tables.
  MERGE `your_project_id.curated_dataset.fact_quote_details` T
  USING (
    WITH latest_records AS (
      SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY quoteid, productid ORDER BY _metadata_load_timestamp DESC) as rn
      FROM `your_project_id.staging_dataset.stg_quote_details`
      WHERE quoteid IS NOT NULL AND productid IS NOT NULL
    )
    SELECT
      quoteid,
      productid,
      SAFE_CAST(quantity AS INT64) AS quantity,
      SAFE_CAST(priceperunit AS FLOAT64) AS priceperunit,
      SAFE_CAST(extendedamount AS FLOAT64) AS extendedamount
    FROM latest_records
    WHERE rn = 1
  ) S
  ON T.quoteid = S.quoteid AND T.productid = S.productid
  WHEN MATCHED THEN
    UPDATE SET
      T.quantity = S.quantity,
      T.priceperunit = S.priceperunit,
      T.extendedamount = S.extendedamount
  WHEN NOT MATCHED THEN
    INSERT (quoteid, productid, quantity, priceperunit, extendedamount)
    VALUES (S.quoteid, S.productid, S.quantity, S.priceperunit, S.extendedamount);
END;


-- ============================================================================
-- Procedure: sp_load_fact_sales
-- Description: Loads data into the fact_sales table.
-- ============================================================================
CREATE OR REPLACE PROCEDURE `your_project_id.curated_dataset.sp_load_fact_sales`()
BEGIN
  CREATE TABLE IF NOT EXISTS `your_project_id.curated_dataset.fact_sales`
  (
    salesorderid STRING OPTIONS(description="The unique identifier for the sales order, serving as the primary key for this fact."),
    opportunityid STRING OPTIONS(description="The foreign key linking the sales order back to the originating opportunity."),
    customerid STRING OPTIONS(description="The foreign key identifying the customer who made the purchase."),
    accountid STRING OPTIONS(description="The foreign key identifying the account associated with the sale."),
    salesrepid STRING OPTIONS(description="The foreign key identifying the sales representative credited with the sale."),
    totalamount FLOAT64 OPTIONS(description="The total monetary value of the sales order, representing the actual revenue generated."),
    statuscode STRING OPTIONS(description="A code representing the status of the sales order (e.g., 'Fulfilled', 'Invoiced')."),
    createdon TIMESTAMP OPTIONS(description="The date and time when the sales order was created."),
    currencycode STRING OPTIONS(description="The ISO currency code for the sales order's total amount.")
  )
  PARTITION BY DATE(createdon)
  CLUSTER BY opportunityid, customerid, accountid, salesrepid
  OPTIONS(
    description="This fact table contains transactional data for closed-won sales orders."
  );

  MERGE `your_project_id.curated_dataset.fact_sales` T
  USING (
    WITH latest_records AS (
      SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY salesorderid ORDER BY _metadata_load_timestamp DESC) as rn
      FROM `your_project_id.staging_dataset.stg_sales`
      WHERE salesorderid IS NOT NULL
    )
    SELECT
      salesorderid,
      opportunityid,
      customerid,
      accountid,
      salesrepid,
      SAFE_CAST(totalamount AS FLOAT64) AS totalamount,
      statuscode,
      SAFE_CAST(createdon AS TIMESTAMP) AS createdon,
      currencycode
    FROM latest_records
    WHERE rn = 1
  ) S
  ON T.salesorderid = S.salesorderid
  WHEN MATCHED THEN
    UPDATE SET
      T.opportunityid = S.opportunityid,
      T.customerid = S.customerid,
      T.accountid = S.accountid,
      T.salesrepid = S.salesrepid,
      T.totalamount = S.totalamount,
      T.statuscode = S.statuscode,
      T.createdon = S.createdon,
      T.currencycode = S.currencycode
  WHEN NOT MATCHED THEN
    INSERT (salesorderid, opportunityid, customerid, accountid, salesrepid, totalamount, statuscode, createdon, currencycode)
    VALUES (S.salesorderid, S.opportunityid, S.customerid, S.accountid, S.salesrepid, S.totalamount, S.statuscode, S.createdon, S.currencycode);
END;


-- ============================================================================
-- Procedure: sp_load_fact_sales_details
-- Description: Loads data into the fact_sales_details table.
-- ============================================================================
CREATE OR REPLACE PROCEDURE `your_project_id.curated_dataset.sp_load_fact_sales_details`()
BEGIN
  CREATE TABLE IF NOT EXISTS `your_project_id.curated_dataset.fact_sales_details`
  (
    salesdetailid STRING OPTIONS(description="The unique identifier for the sales order line item, serving as the primary key."),
    salesorderid STRING OPTIONS(description="The foreign key linking this detail line to the parent sales order in fact_sales."),
    productid STRING OPTIONS(description="The foreign key linking this detail line to a specific product in dim_product."),
    quantity INT64 OPTIONS(description="The number of units of the product sold."),
    priceperunit FLOAT64 OPTIONS(description="The price per unit of the product on this sales order line."),
    extendedamount FLOAT64 OPTIONS(description="The total amount for this line item (quantity * priceperunit).")
  )
  CLUSTER BY salesorderid, productid
  OPTIONS(
    description="This fact table provides line-item details for each sales order."
  );

  MERGE `your_project_id.curated_dataset.fact_sales_details` T
  USING (
    WITH latest_records AS (
      SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY salesdetailid ORDER BY _metadata_load_timestamp DESC) as rn
      FROM `your_project_id.staging_dataset.stg_sales_details`
      WHERE salesdetailid IS NOT NULL
    )
    SELECT
      salesdetailid,
      salesorderid,
      productid,
      SAFE_CAST(quantity AS INT64) AS quantity,
      SAFE_CAST(priceperunit AS FLOAT64) AS priceperunit,
      SAFE_CAST(extendedamount AS FLOAT64) AS extendedamount
    FROM latest_records
    WHERE rn = 1
  ) S
  ON T.salesdetailid = S.salesdetailid
  WHEN MATCHED THEN
    UPDATE SET
      T.salesorderid = S.salesorderid,
      T.productid = S.productid,
      T.quantity = S.quantity,
      T.priceperunit = S.priceperunit,
      T.extendedamount = S.extendedamount
  WHEN NOT MATCHED THEN
    INSERT (salesdetailid, salesorderid, productid, quantity, priceperunit, extendedamount)
    VALUES (S.salesdetailid, S.salesorderid, S.productid, S.quantity, S.priceperunit, S.extendedamount);
END;