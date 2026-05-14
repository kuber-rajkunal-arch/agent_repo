/*
This script contains the transformation logic to populate the curated (Gold)
Customer SSOT tables from the staging (Silver) tables.
It follows an SCD Type 1 methodology, using MERGE statements to insert new
records and update existing ones.

Source Project: `your-gcp-project-id`
Source Dataset: `staging_dataset`
Target Project: `your-gcp-project-id`
Target Dataset: `curated_dataset`
*/

-- =============================================================================
-- Entity: dim_account
-- =============================================================================
MERGE `your-gcp-project-id.curated_dataset.dim_account` AS T
USING (
  SELECT
    accountid,
    name,
    address1_city,
    address1_state,
    region,
    _metadata_load_timestamp
  FROM
    `your-gcp-project-id.staging_dataset.stg_account`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY accountid ORDER BY _metadata_load_timestamp DESC) = 1
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
MERGE `your-gcp-project-id.curated_dataset.dim_customer` AS T
USING (
  SELECT
    customerid,
    accountid,
    name,
    telephone1,
    industry,
    region,
    _metadata_load_timestamp
  FROM
    `your-gcp-project-id.staging_dataset.stg_customer`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY customerid ORDER BY _metadata_load_timestamp DESC) = 1
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
MERGE `your-gcp-project-id.curated_dataset.dim_lead` AS T
USING (
  SELECT
    leadid,
    customerid,
    accountid,
    statuscode,
    SAFE_CAST(createdon AS DATE) AS createdon,
    _metadata_load_timestamp
  FROM
    `your-gcp-project-id.staging_dataset.stg_lead`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY leadid ORDER BY _metadata_load_timestamp DESC) = 1
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
MERGE `your-gcp-project-id.curated_dataset.dim_opportunity` AS T
USING (
  SELECT
    opportunityid,
    leadid,
    customerid,
    accountid,
    salesrepid,
    statuscode,
    SAFE_CAST(createdon AS DATE) AS createdon,
    SAFE_CAST(estimatedvalue AS FLOAT64) AS estimatedvalue,
    currencycode,
    _metadata_load_timestamp
  FROM
    `your-gcp-project-id.staging_dataset.stg_opportunity`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY opportunityid ORDER BY _metadata_load_timestamp DESC) = 1
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
MERGE `your-gcp-project-id.curated_dataset.dim_product` AS T
USING (
  SELECT
    productid,
    name,
    category,
    SAFE_CAST(price AS FLOAT64) AS price,
    currencycode,
    _metadata_load_timestamp
  FROM
    `your-gcp-project-id.staging_dataset.stg_product`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY productid ORDER BY _metadata_load_timestamp DESC) = 1
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
MERGE `your-gcp-project-id.curated_dataset.dim_sales_rep` AS T
USING (
  SELECT
    salesrepid,
    name,
    region,
    _metadata_load_timestamp
  FROM
    `your-gcp-project-id.staging_dataset.stg_sales_rep`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY salesrepid ORDER BY _metadata_load_timestamp DESC) = 1
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
-- =============================================================================
MERGE `your-gcp-project-id.curated_dataset.fact_quotes` AS T
USING (
  SELECT
    quoteid,
    opportunityid,
    customerid,
    accountid,
    salesrepid,
    SAFE_CAST(totalamount AS FLOAT64) AS totalamount,
    statuscode,
    SAFE_CAST(createdon AS TIMESTAMP) AS createdon,
    currencycode,
    _metadata_load_timestamp
  FROM
    `your-gcp-project-id.staging_dataset.stg_quote`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY quoteid ORDER BY _metadata_load_timestamp DESC) = 1
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
-- =============================================================================
MERGE `your-gcp-project-id.curated_dataset.fact_quote_details` AS T
USING (
  SELECT
    quoteid,
    productid,
    SAFE_CAST(quantity AS INT64) AS quantity,
    SAFE_CAST(priceperunit AS FLOAT64) AS priceperunit,
    SAFE_CAST(extendedamount AS FLOAT64) AS extendedamount,
    _metadata_load_timestamp
  FROM
    `your-gcp-project-id.staging_dataset.stg_quote_details`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY quoteid, productid ORDER BY _metadata_load_timestamp DESC) = 1
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
-- =============================================================================
MERGE `your-gcp-project-id.curated_dataset.fact_sales` AS T
USING (
  SELECT
    salesorderid,
    opportunityid,
    customerid,
    accountid,
    salesrepid,
    SAFE_CAST(totalamount AS FLOAT64) AS totalamount,
    statuscode,
    SAFE_CAST(createdon AS TIMESTAMP) AS createdon,
    currencycode,
    _metadata_load_timestamp
  FROM
    `your-gcp-project-id.staging_dataset.stg_sales`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY salesorderid ORDER BY _metadata_load_timestamp DESC) = 1
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
-- =============================================================================
MERGE `your-gcp-project-id.curated_dataset.fact_sales_details` AS T
USING (
  SELECT
    salesdetailid,
    salesorderid,
    productid,
    SAFE_CAST(quantity AS INT64) AS quantity,
    SAFE_CAST(priceperunit AS FLOAT64) AS priceperunit,
    SAFE_CAST(extendedamount AS FLOAT64) AS extendedamount,
    _metadata_load_timestamp
  FROM
    `your-gcp-project-id.staging_dataset.stg_sales_details`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY salesdetailid ORDER BY _metadata_load_timestamp DESC) = 1
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
