/*
  This script creates and populates the curated Gold layer tables for the Customer SSOT.
  It follows an SCD Type 1 pattern using MERGE statements to upsert data from the
  staging layer into the final dimension and fact tables.

  This script is designed to be idempotent and can be re-run safely.

  Variables:
  - project_id: The GCP project ID where the datasets reside.
  - gold_dataset: The BigQuery dataset for the curated (gold) tables.
*/

DECLARE project_id STRING DEFAULT 'your-gcp-project-id';
DECLARE gold_dataset STRING DEFAULT 'your_gold_dataset';

--------------------------------------------------------------------------------
-- Entity: dim_account
--------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `your-gcp-project-id.your_gold_dataset.dim_account`
(
  accountid STRING OPTIONS(description='The unique identifier for the account, serving as the primary key.'),
  name STRING OPTIONS(description='The legal name of the account or company, used for identification and reporting.'),
  address1_city STRING OPTIONS(description='The city component of the account_s primary address, used for geographic analysis.'),
  address1_state STRING OPTIONS(description='The state or province component of the account_s primary address, used for regional segmentation.'),
  region STRING OPTIONS(description='The geographical region to which the account belongs, often used for sales territory analysis.')
)
OPTIONS(
  description='This dimension table stores information about accounts, which are typically organizations or companies.'
);

MERGE `your-gcp-project-id.your_gold_dataset.dim_account` T
USING (
  WITH
    source_data AS (
      SELECT
        TRIM(accountid) AS accountid,
        TRIM(name) AS name,
        TRIM(address1_city) AS address1_city,
        TRIM(address1_state) AS address1_state,
        TRIM(region) AS region,
        _metadata_load_timestamp
      FROM
        `your-gcp-project-id.staging_dataset.stg_account`
      WHERE
        TRIM(accountid) IS NOT NULL
    ),
    deduplicated_source AS (
      SELECT
        *
      FROM
        source_data
      QUALIFY ROW_NUMBER() OVER (PARTITION BY accountid ORDER BY _metadata_load_timestamp DESC) = 1
    )
  SELECT
    accountid,
    name,
    address1_city,
    address1_state,
    region
  FROM
    deduplicated_source
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

--------------------------------------------------------------------------------
-- Entity: dim_customer
--------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `your-gcp-project-id.your_gold_dataset.dim_customer`
(
  customerid STRING OPTIONS(description='The unique identifier for the customer, serving as the primary key.'),
  accountid STRING OPTIONS(description='The foreign key linking the customer to their associated account in the `dim_account` table.'),
  name STRING OPTIONS(description='The full name of the customer, used for personalization and reporting.'),
  telephone1 STRING OPTIONS(description='The primary telephone number for the customer, used for contact purposes.'),
  industry STRING OPTIONS(description='The industry in which the customer operates, useful for market segmentation.'),
  region STRING OPTIONS(description='The geographical region to which the customer belongs, used for localized marketing and sales analysis.')
)
OPTIONS(
  description='This dimension table contains details about individual customers or contacts.'
);

MERGE `your-gcp-project-id.your_gold_dataset.dim_customer` T
USING (
  WITH
    source_data AS (
      SELECT
        TRIM(customerid) AS customerid,
        TRIM(accountid) AS accountid,
        TRIM(name) AS name,
        TRIM(telephone1) AS telephone1,
        TRIM(industry) AS industry,
        TRIM(region) AS region,
        _metadata_load_timestamp
      FROM
        `your-gcp-project-id.staging_dataset.stg_customer`
      WHERE
        TRIM(customerid) IS NOT NULL
    ),
    deduplicated_source AS (
      SELECT
        *
      FROM
        source_data
      QUALIFY ROW_NUMBER() OVER (PARTITION BY customerid ORDER BY _metadata_load_timestamp DESC) = 1
    )
  SELECT
    customerid,
    accountid,
    name,
    telephone1,
    industry,
    region
  FROM
    deduplicated_source
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

--------------------------------------------------------------------------------
-- Entity: dim_lead
--------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `your-gcp-project-id.your_gold_dataset.dim_lead`
(
  leadid STRING OPTIONS(description='The unique identifier for the lead, serving as the primary key.'),
  customerid STRING OPTIONS(description='The foreign key linking the lead to a customer record if the lead has been converted.'),
  accountid STRING OPTIONS(description='The foreign key linking the lead to an account record.'),
  statuscode STRING OPTIONS(description='A code representing the current status of the lead in the sales process.'),
  createdon DATE OPTIONS(description='The date when the lead was created in the source system.')
)
OPTIONS(
  description='This dimension table stores information about sales leads.'
);

MERGE `your-gcp-project-id.your_gold_dataset.dim_lead` T
USING (
  WITH
    source_data AS (
      SELECT
        TRIM(leadid) AS leadid,
        TRIM(customerid) AS customerid,
        TRIM(accountid) AS accountid,
        TRIM(statuscode) AS statuscode,
        SAFE_CAST(createdon AS DATE) AS createdon,
        _metadata_load_timestamp
      FROM
        `your-gcp-project-id.staging_dataset.stg_lead`
      WHERE
        TRIM(leadid) IS NOT NULL
    ),
    deduplicated_source AS (
      SELECT
        *
      FROM
        source_data
      QUALIFY ROW_NUMBER() OVER (PARTITION BY leadid ORDER BY _metadata_load_timestamp DESC) = 1
    )
  SELECT
    leadid,
    customerid,
    accountid,
    statuscode,
    createdon
  FROM
    deduplicated_source
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

--------------------------------------------------------------------------------
-- Entity: dim_opportunity
--------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `your-gcp-project-id.your_gold_dataset.dim_opportunity`
(
  opportunityid STRING OPTIONS(description='The unique identifier for the opportunity, serving as the primary key.'),
  leadid STRING OPTIONS(description='The foreign key linking the opportunity to the originating lead.'),
  customerid STRING OPTIONS(description='The foreign key linking the opportunity to the primary customer.'),
  accountid STRING OPTIONS(description='The foreign key linking the opportunity to the customer_s account.'),
  salesrepid STRING OPTIONS(description='The foreign key identifying the sales representative responsible for the opportunity.'),
  statuscode STRING OPTIONS(description='A code representing the current status of the opportunity.'),
  createdon DATE OPTIONS(description='The date when the opportunity was created.'),
  estimatedvalue FLOAT64 OPTIONS(description='The estimated monetary value of the opportunity.'),
  currencycode STRING OPTIONS(description='The ISO currency code for the estimated value.')
)
OPTIONS(
  description='This dimension table holds data about sales opportunities.'
);

MERGE `your-gcp-project-id.your_gold_dataset.dim_opportunity` T
USING (
  WITH
    source_data AS (
      SELECT
        TRIM(opportunityid) AS opportunityid,
        TRIM(leadid) AS leadid,
        TRIM(customerid) AS customerid,
        TRIM(accountid) AS accountid,
        TRIM(salesrepid) AS salesrepid,
        TRIM(statuscode) AS statuscode,
        SAFE_CAST(createdon AS DATE) AS createdon,
        SAFE_CAST(estimatedvalue AS FLOAT64) AS estimatedvalue,
        TRIM(currencycode) AS currencycode,
        _metadata_load_timestamp
      FROM
        `your-gcp-project-id.staging_dataset.stg_opportunity`
      WHERE
        TRIM(opportunityid) IS NOT NULL
    ),
    deduplicated_source AS (
      SELECT
        *
      FROM
        source_data
      QUALIFY ROW_NUMBER() OVER (PARTITION BY opportunityid ORDER BY _metadata_load_timestamp DESC) = 1
    )
  SELECT
    opportunityid,
    leadid,
    customerid,
    accountid,
    salesrepid,
    statuscode,
    createdon,
    estimatedvalue,
    currencycode
  FROM
    deduplicated_source
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

--------------------------------------------------------------------------------
-- Entity: dim_product
--------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `your-gcp-project-id.your_gold_dataset.dim_product`
(
  productid STRING OPTIONS(description='The unique identifier for the product, serving as the primary key.'),
  name STRING OPTIONS(description='The name of the product, used for display and reporting.'),
  category STRING OPTIONS(description='The category to which the product belongs.'),
  price FLOAT64 OPTIONS(description='The standard list price of the product.'),
  currencycode STRING OPTIONS(description='The ISO currency code for the product price.')
)
OPTIONS(
  description='This dimension table stores information about the products or services that are being sold.'
);

MERGE `your-gcp-project-id.your_gold_dataset.dim_product` T
USING (
  WITH
    source_data AS (
      SELECT
        TRIM(productid) AS productid,
        TRIM(name) AS name,
        TRIM(category) AS category,
        SAFE_CAST(price AS FLOAT64) AS price,
        TRIM(currencycode) AS currencycode,
        _metadata_load_timestamp
      FROM
        `your-gcp-project-id.staging_dataset.stg_product`
      WHERE
        TRIM(productid) IS NOT NULL
    ),
    deduplicated_source AS (
      SELECT
        *
      FROM
        source_data
      QUALIFY ROW_NUMBER() OVER (PARTITION BY productid ORDER BY _metadata_load_timestamp DESC) = 1
    )
  SELECT
    productid,
    name,
    category,
    price,
    currencycode
  FROM
    deduplicated_source
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

--------------------------------------------------------------------------------
-- Entity: dim_sales_rep
--------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `your-gcp-project-id.your_gold_dataset.dim_sales_rep`
(
  salesrepid STRING OPTIONS(description='The unique identifier for the sales representative, serving as the primary key.'),
  name STRING OPTIONS(description='The full name of the sales representative.'),
  region STRING OPTIONS(description='The sales region assigned to the representative.')
)
OPTIONS(
  description='This dimension table contains information about the sales representatives in the organization.'
);

MERGE `your-gcp-project-id.your_gold_dataset.dim_sales_rep` T
USING (
  WITH
    source_data AS (
      SELECT
        TRIM(salesrepid) AS salesrepid,
        TRIM(name) AS name,
        TRIM(region) AS region,
        _metadata_load_timestamp
      FROM
        `your-gcp-project-id.staging_dataset.stg_sales_rep`
      WHERE
        TRIM(salesrepid) IS NOT NULL
    ),
    deduplicated_source AS (
      SELECT
        *
      FROM
        source_data
      QUALIFY ROW_NUMBER() OVER (PARTITION BY salesrepid ORDER BY _metadata_load_timestamp DESC) = 1
    )
  SELECT
    salesrepid,
    name,
    region
  FROM
    deduplicated_source
) S
ON T.salesrepid = S.salesrepid
WHEN MATCHED THEN
  UPDATE SET
    T.name = S.name,
    T.region = S.region
WHEN NOT MATCHED THEN
  INSERT (salesrepid, name, region)
  VALUES (S.salesrepid, S.name, S.region);

--------------------------------------------------------------------------------
-- Entity: fact_quotes
--------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `your-gcp-project-id.your_gold_dataset.fact_quotes`
(
  quoteid STRING OPTIONS(description='The unique identifier for the sales quote, serving as the primary key for this fact.'),
  opportunityid STRING OPTIONS(description='The foreign key linking the quote to a sales opportunity.'),
  customerid STRING OPTIONS(description='The foreign key identifying the customer who received the quote.'),
  accountid STRING OPTIONS(description='The foreign key identifying the account associated with the quote.'),
  salesrepid STRING OPTIONS(description='The foreign key identifying the sales representative who created the quote.'),
  totalamount FLOAT64 OPTIONS(description='The total monetary value of the quote.'),
  statuscode STRING OPTIONS(description='A code representing the current status of the quote.'),
  createdon TIMESTAMP OPTIONS(description='The date and time when the quote was created.'),
  currencycode STRING OPTIONS(description='The ISO currency code for the quote_s total amount.')
)
PARTITION BY
  DATE(createdon)
CLUSTER BY
  opportunityid, customerid, accountid, salesrepid
OPTIONS(
  description='This fact table contains transactional data related to sales quotes.'
);

MERGE `your-gcp-project-id.your_gold_dataset.fact_quotes` T
USING (
  WITH
    source_data AS (
      SELECT
        TRIM(quoteid) AS quoteid,
        TRIM(opportunityid) AS opportunityid,
        TRIM(customerid) AS customerid,
        TRIM(accountid) AS accountid,
        TRIM(salesrepid) AS salesrepid,
        SAFE_CAST(totalamount AS FLOAT64) AS totalamount,
        TRIM(statuscode) AS statuscode,
        SAFE_CAST(createdon AS TIMESTAMP) AS createdon,
        TRIM(currencycode) AS currencycode,
        _metadata_load_timestamp
      FROM
        `your-gcp-project-id.staging_dataset.stg_quote`
      WHERE
        TRIM(quoteid) IS NOT NULL
    ),
    deduplicated_source AS (
      SELECT
        *
      FROM
        source_data
      QUALIFY ROW_NUMBER() OVER (PARTITION BY quoteid ORDER BY _metadata_load_timestamp DESC) = 1
    )
  SELECT
    quoteid,
    opportunityid,
    customerid,
    accountid,
    salesrepid,
    totalamount,
    statuscode,
    createdon,
    currencycode
  FROM
    deduplicated_source
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

--------------------------------------------------------------------------------
-- Entity: fact_quote_details
--------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `your-gcp-project-id.your_gold_dataset.fact_quote_details`
(
  quoteid STRING OPTIONS(description='The foreign key linking this detail line to the parent quote in `fact_quotes`.'),
  productid STRING OPTIONS(description='The foreign key linking this detail line to a specific product in `dim_product`.'),
  quantity INT64 OPTIONS(description='The number of units of the product quoted.'),
  priceperunit FLOAT64 OPTIONS(description='The price per unit of the product on this quote line.'),
  extendedamount FLOAT64 OPTIONS(description='The total amount for this line item (quantity * priceperunit)._)
)
CLUSTER BY
  quoteid, productid
OPTIONS(
  description='This fact table provides line-item details for each sales quote.'
);

MERGE `your-gcp-project-id.your_gold_dataset.fact_quote_details` T
USING (
  WITH
    source_data AS (
      SELECT
        TRIM(quoteid) AS quoteid,
        TRIM(productid) AS productid,
        SAFE_CAST(quantity AS INT64) AS quantity,
        SAFE_CAST(priceperunit AS FLOAT64) AS priceperunit,
        SAFE_CAST(extendedamount AS FLOAT64) AS extendedamount,
        _metadata_load_timestamp
      FROM
        `your-gcp-project-id.staging_dataset.stg_quote_details`
      WHERE
        TRIM(quoteid) IS NOT NULL AND TRIM(productid) IS NOT NULL
    ),
    deduplicated_source AS (
      SELECT
        *
      FROM
        source_data
      QUALIFY ROW_NUMBER() OVER (PARTITION BY quoteid, productid ORDER BY _metadata_load_timestamp DESC) = 1
    )
  SELECT
    quoteid,
    productid,
    quantity,
    priceperunit,
    extendedamount
  FROM
    deduplicated_source
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

--------------------------------------------------------------------------------
-- Entity: fact_sales
--------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `your-gcp-project-id.your_gold_dataset.fact_sales`
(
  salesorderid STRING OPTIONS(description='The unique identifier for the sales order, serving as the primary key for this fact.'),
  opportunityid STRING OPTIONS(description='The foreign key linking the sales order back to the originating opportunity.'),
  customerid STRING OPTIONS(description='The foreign key identifying the customer who made the purchase.'),
  accountid STRING OPTIONS(description='The foreign key identifying the account associated with the sale.'),
  salesrepid STRING OPTIONS(description='The foreign key identifying the sales representative credited with the sale.'),
  totalamount FLOAT64 OPTIONS(description='The total monetary value of the sales order, representing the actual revenue generated.'),
  statuscode STRING OPTIONS(description='A code representing the status of the sales order.'),
  createdon TIMESTAMP OPTIONS(description='The date and time when the sales order was created.'),
  currencycode STRING OPTIONS(description='The ISO currency code for the sales order_s total amount.')
)
PARTITION BY
  DATE(createdon)
CLUSTER BY
  opportunityid, customerid, accountid, salesrepid
OPTIONS(
  description='This fact table contains transactional data for closed-won sales orders.'
);

MERGE `your-gcp-project-id.your_gold_dataset.fact_sales` T
USING (
  WITH
    source_data AS (
      SELECT
        TRIM(salesorderid) AS salesorderid,
        TRIM(opportunityid) AS opportunityid,
        TRIM(customerid) AS customerid,
        TRIM(accountid) AS accountid,
        TRIM(salesrepid) AS salesrepid,
        SAFE_CAST(totalamount AS FLOAT64) AS totalamount,
        TRIM(statuscode) AS statuscode,
        SAFE_CAST(createdon AS TIMESTAMP) AS createdon,
        TRIM(currencycode) AS currencycode,
        _metadata_load_timestamp
      FROM
        `your-gcp-project-id.staging_dataset.stg_sales`
      WHERE
        TRIM(salesorderid) IS NOT NULL
    ),
    deduplicated_source AS (
      SELECT
        *
      FROM
        source_data
      QUALIFY ROW_NUMBER() OVER (PARTITION BY salesorderid ORDER BY _metadata_load_timestamp DESC) = 1
    )
  SELECT
    salesorderid,
    opportunityid,
    customerid,
    accountid,
    salesrepid,
    totalamount,
    statuscode,
    createdon,
    currencycode
  FROM
    deduplicated_source
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

--------------------------------------------------------------------------------
-- Entity: fact_sales_details
--------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `your-gcp-project-id.your_gold_dataset.fact_sales_details`
(
  salesdetailid STRING OPTIONS(description='The unique identifier for the sales order line item, serving as the primary key.'),
  salesorderid STRING OPTIONS(description='The foreign key linking this detail line to the parent sales order in `fact_sales`.'),
  productid STRING OPTIONS(description='The foreign key linking this detail line to a specific product in `dim_product`.'),
  quantity INT64 OPTIONS(description='The number of units of the product sold.'),
  priceperunit FLOAT64 OPTIONS(description='The price per unit of the product on this sales order line.'),
  extendedamount FLOAT64 OPTIONS(description='The total amount for this line item (quantity * priceperunit)._)
)
CLUSTER BY
  salesorderid, productid
OPTIONS(
  description='This fact table provides line-item details for each sales order.'
);

MERGE `your-gcp-project-id.your_gold_dataset.fact_sales_details` T
USING (
  WITH
    source_data AS (
      SELECT
        TRIM(salesdetailid) AS salesdetailid,
        TRIM(salesorderid) AS salesorderid,
        TRIM(productid) AS productid,
        SAFE_CAST(quantity AS INT64) AS quantity,
        SAFE_CAST(priceperunit AS FLOAT64) AS priceperunit,
        SAFE_CAST(extendedamount AS FLOAT64) AS extendedamount,
        _metadata_load_timestamp
      FROM
        `your-gcp-project-id.staging_dataset.stg_sales_details`
      WHERE
        TRIM(salesdetailid) IS NOT NULL
    ),
    deduplicated_source AS (
      SELECT
        *
      FROM
        source_data
      QUALIFY ROW_NUMBER() OVER (PARTITION BY salesdetailid ORDER BY _metadata_load_timestamp DESC) = 1
    )
  SELECT
    salesdetailid,
    salesorderid,
    productid,
    quantity,
    priceperunit,
    extendedamount
  FROM
    deduplicated_source
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
