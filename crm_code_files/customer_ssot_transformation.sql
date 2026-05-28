/*
  This script contains the transformation logic to populate the curated Customer SSOT
  data models from the staging tables. It implements an SCD Type 1 merge pattern,
  inserting new records and updating existing ones based on the primary key.

  This script is designed to be idempotent and can be re-run.

  Assumed variables (to be replaced by a templating engine like Jinja or dbt):
  - gcp-cloud-source-repo: Your Google Cloud project ID.
  - crm_raw_data_gold: The BigQuery dataset for the final curated tables (e.g., 'customer_ssot_curated').
  - crm_raw_data_silver: The BigQuery dataset for the staging tables (e.g., 'customer_ssot_staging').
*/

-- =============================================================================
-- Entity: dim_account
-- =============================================================================
MERGE `gcp-cloud-source-repo.crm_raw_data_gold.dim_account` AS T
USING (
  SELECT
    accountid,
    name,
    address1_city,
    address1_state,
    region
  FROM
    `gcp-cloud-source-repo.crm_raw_data_silver.stg_account`
) AS S
ON T.accountid = S.accountid
WHEN MATCHED THEN
  UPDATE SET
    T.name = S.name,
    T.address1_city = S.address1_city,
    T.address1_state = S.address1_state,
    T.region = S.region
WHEN NOT MATCHED THEN
  INSERT (
    accountid,
    name,
    address1_city,
    address1_state,
    region
  )
  VALUES (
    S.accountid,
    S.name,
    S.address1_city,
    S.address1_state,
    S.region
  );

-- =============================================================================
-- Entity: dim_customer
-- =============================================================================
MERGE `gcp-cloud-source-repo.crm_raw_data_gold.dim_customer` AS T
USING (
  SELECT
    customerid,
    accountid,
    name,
    telephone1,
    industry,
    region
  FROM
    `gcp-cloud-source-repo.crm_raw_data_silver.stg_customer`
) AS S
ON T.customerid = S.customerid
WHEN MATCHED THEN
  UPDATE SET
    T.accountid = S.accountid,
    T.name = S.name,
    T.telephone1 = S.telephone1,
    T.industry = S.industry,
    T.region = S.region
WHEN NOT MATCHED THEN
  INSERT (
    customerid,
    accountid,
    name,
    telephone1,
    industry,
    region
  )
  VALUES (
    S.customerid,
    S.accountid,
    S.name,
    S.telephone1,
    S.industry,
    S.region
  );

-- =============================================================================
-- Entity: dim_lead
-- =============================================================================
MERGE `gcp-cloud-source-repo.crm_raw_data_gold.dim_lead` AS T
USING (
  SELECT
    leadid,
    customerid,
    accountid,
    statuscode,
    CAST(createdon AS DATE) AS createdon
  FROM
    `gcp-cloud-source-repo.crm_raw_data_silver.stg_lead`
) AS S
ON T.leadid = S.leadid
WHEN MATCHED THEN
  UPDATE SET
    T.customerid = S.customerid,
    T.accountid = S.accountid,
    T.statuscode = S.statuscode,
    T.createdon = S.createdon
WHEN NOT MATCHED THEN
  INSERT (
    leadid,
    customerid,
    accountid,
    statuscode,
    createdon
  )
  VALUES (
    S.leadid,
    S.customerid,
    S.accountid,
    S.statuscode,
    S.createdon
  );

-- =============================================================================
-- Entity: dim_opportunity
-- =============================================================================
MERGE `gcp-cloud-source-repo.crm_raw_data_gold.dim_opportunity` AS T
USING (
  SELECT
    opportunityid,
    leadid,
    customerid,
    accountid,
    salesrepid,
    statuscode,
    CAST(createdon AS DATE) AS createdon,
    CAST(estimatedvalue AS FLOAT64) AS estimatedvalue,
    currencycode
  FROM
    `gcp-cloud-source-repo.crm_raw_data_silver.stg_opportunity`
) AS S
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
  INSERT (
    opportunityid,
    leadid,
    customerid,
    accountid,
    salesrepid,
    statuscode,
    createdon,
    estimatedvalue,
    currencycode
  )
  VALUES (
    S.opportunityid,
    S.leadid,
    S.customerid,
    S.accountid,
    S.salesrepid,
    S.statuscode,
    S.createdon,
    S.estimatedvalue,
    S.currencycode
  );

-- =============================================================================
-- Entity: dim_product
-- =============================================================================
MERGE `gcp-cloud-source-repo.crm_raw_data_gold.dim_product` AS T
USING (
  SELECT
    productid,
    name,
    category,
    CAST(price AS FLOAT64) AS price,
    currencycode
  FROM
    `gcp-cloud-source-repo.crm_raw_data_silver.stg_product`
) AS S
ON T.productid = S.productid
WHEN MATCHED THEN
  UPDATE SET
    T.name = S.name,
    T.category = S.category,
    T.price = S.price,
    T.currencycode = S.currencycode
WHEN NOT MATCHED THEN
  INSERT (
    productid,
    name,
    category,
    price,
    currencycode
  )
  VALUES (
    S.productid,
    S.name,
    S.category,
    S.price,
    S.currencycode
  );

-- =============================================================================
-- Entity: dim_sales_rep
-- =============================================================================
MERGE `gcp-cloud-source-repo.crm_raw_data_gold.dim_sales_rep` AS T
USING (
  SELECT
    salesrepid,
    name,
    region
  FROM
    `gcp-cloud-source-repo.crm_raw_data_silver.stg_sales_rep`
) AS S
ON T.salesrepid = S.salesrepid
WHEN MATCHED THEN
  UPDATE SET
    T.name = S.name,
    T.region = S.region
WHEN NOT MATCHED THEN
  INSERT (
    salesrepid,
    name,
    region
  )
  VALUES (
    S.salesrepid,
    S.name,
    S.region
  );

-- =============================================================================
-- Entity: fact_quotes
-- DDL Note:
-- PARTITION BY DATE(createdon)
-- CLUSTER BY opportunityid, customerid, accountid, salesrepid
-- =============================================================================
MERGE `gcp-cloud-source-repo.crm_raw_data_gold.fact_quotes` AS T
USING (
  SELECT
    quoteid,
    opportunityid,
    customerid,
    accountid,
    salesrepid,
    CAST(totalamount AS FLOAT64) AS totalamount,
    statuscode,
    CAST(createdon AS TIMESTAMP) AS createdon,
    currencycode
  FROM
    `gcp-cloud-source-repo.crm_raw_data_silver.stg_quote`
) AS S
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
  INSERT (
    quoteid,
    opportunityid,
    customerid,
    accountid,
    salesrepid,
    totalamount,
    statuscode,
    createdon,
    currencycode
  )
  VALUES (
    S.quoteid,
    S.opportunityid,
    S.customerid,
    S.accountid,
    S.salesrepid,
    S.totalamount,
    S.statuscode,
    S.createdon,
    S.currencycode
  );

-- =============================================================================
-- Entity: fact_quote_details
-- DDL Note:
-- CLUSTER BY quoteid, productid
-- =============================================================================
MERGE `gcp-cloud-source-repo.crm_raw_data_gold.fact_quote_details` AS T
USING (
  SELECT
    quoteid,
    productid,
    CAST(quantity AS INT64) AS quantity,
    CAST(priceperunit AS FLOAT64) AS priceperunit,
    CAST(extendedamount AS FLOAT64) AS extendedamount
  FROM
    `gcp-cloud-source-repo.crm_raw_data_silver.stg_quote_details`
) AS S
ON T.quoteid = S.quoteid AND T.productid = S.productid
WHEN MATCHED THEN
  UPDATE SET
    T.quantity = S.quantity,
    T.priceperunit = S.priceperunit,
    T.extendedamount = S.extendedamount
WHEN NOT MATCHED THEN
  INSERT (
    quoteid,
    productid,
    quantity,
    priceperunit,
    extendedamount
  )
  VALUES (
    S.quoteid,
    S.productid,
    S.quantity,
    S.priceperunit,
    S.extendedamount
  );

-- =============================================================================
-- Entity: fact_sales
-- DDL Note:
-- PARTITION BY DATE(createdon)
-- CLUSTER BY opportunityid, customerid, accountid, salesrepid
-- =============================================================================
MERGE `gcp-cloud-source-repo.crm_raw_data_gold.fact_sales` AS T
USING (
  SELECT
    salesorderid,
    opportunityid,
    customerid,
    accountid,
    salesrepid,
    CAST(totalamount AS FLOAT64) AS totalamount,
    statuscode,
    CAST(createdon AS TIMESTAMP) AS createdon,
    currencycode
  FROM
    `gcp-cloud-source-repo.crm_raw_data_silver.stg_sales`
) AS S
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
  INSERT (
    salesorderid,
    opportunityid,
    customerid,
    accountid,
    salesrepid,
    totalamount,
    statuscode,
    createdon,
    currencycode
  )
  VALUES (
    S.salesorderid,
    S.opportunityid,
    S.customerid,
    S.accountid,
    S.salesrepid,
    S.totalamount,
    S.statuscode,
    S.createdon,
    S.currencycode
  );

-- =============================================================================
-- Entity: fact_sales_details
-- DDL Note:
-- CLUSTER BY salesorderid, productid
-- =============================================================================
MERGE `gcp-cloud-source-repo.crm_raw_data_gold.fact_sales_details` AS T
USING (
  SELECT
    salesdetailid,
    salesorderid,
    productid,
    CAST(quantity AS INT64) AS quantity,
    CAST(priceperunit AS FLOAT64) AS priceperunit,
    CAST(extendedamount AS FLOAT64) AS extendedamount
  FROM
    `gcp-cloud-source-repo.crm_raw_data_silver.stg_sales_details`
) AS S
ON T.salesdetailid = S.salesdetailid
WHEN MATCHED THEN
  UPDATE SET
    T.salesorderid = S.salesorderid,
    T.productid = S.productid,
    T.quantity = S.quantity,
    T.priceperunit = S.priceperunit,
    T.extendedamount = S.extendedamount
WHEN NOT MATCHED THEN
  INSERT (
    salesdetailid,
    salesorderid,
    productid,
    quantity,
    priceperunit,
    extendedamount
  )
  VALUES (
    S.salesdetailid,
    S.salesorderid,
    S.productid,
    S.quantity,
    S.priceperunit,
    S.extendedamount
  );
