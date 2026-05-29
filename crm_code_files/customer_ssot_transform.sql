-- File: customer_ssot_transform.sql
-- Description: This script performs SCD Type 1 transformations from staging tables
-- to the curated Customer SSOT data model using MERGE statements. It handles
-- inserts for new records and updates for existing records based on the primary key.
-- Intra-batch duplicates are handled by selecting the most recent record based on
-- _metadata_load_timestamp.

-- =============================================================================
-- Entity: dim_account
-- =============================================================================
MERGE `${project_id}.${curated_dataset}.dim_account` AS T
USING (
  -- Select and deduplicate the latest records from the staging table
  SELECT
    * EXCEPT(rn)
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER(PARTITION BY accountid ORDER BY _metadata_load_timestamp DESC) AS rn
    FROM
      `${project_id}.staging_dataset.stg_account`
  )
  WHERE rn = 1
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
MERGE `${project_id}.${curated_dataset}.dim_customer` AS T
USING (
  SELECT
    * EXCEPT(rn)
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER(PARTITION BY customerid ORDER BY _metadata_load_timestamp DESC) AS rn
    FROM
      `${project_id}.staging_dataset.stg_customer`
  )
  WHERE rn = 1
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
MERGE `${project_id}.${curated_dataset}.dim_lead` AS T
USING (
  SELECT
    * EXCEPT(rn)
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER(PARTITION BY leadid ORDER BY _metadata_load_timestamp DESC) AS rn
    FROM
      `${project_id}.staging_dataset.stg_lead`
  )
  WHERE rn = 1
) AS S
ON T.leadid = S.leadid
WHEN MATCHED THEN
  UPDATE SET
    T.customerid = S.customerid,
    T.accountid = S.accountid,
    T.statuscode = S.statuscode,
    T.createdon = SAFE_CAST(S.createdon AS DATE)
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
    SAFE_CAST(S.createdon AS DATE)
  );

-- =============================================================================
-- Entity: dim_opportunity
-- =============================================================================
MERGE `${project_id}.${curated_dataset}.dim_opportunity` AS T
USING (
  SELECT
    * EXCEPT(rn)
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER(PARTITION BY opportunityid ORDER BY _metadata_load_timestamp DESC) AS rn
    FROM
      `${project_id}.staging_dataset.stg_opportunity`
  )
  WHERE rn = 1
) AS S
ON T.opportunityid = S.opportunityid
WHEN MATCHED THEN
  UPDATE SET
    T.leadid = S.leadid,
    T.customerid = S.customerid,
    T.accountid = S.accountid,
    T.salesrepid = S.salesrepid,
    T.statuscode = S.statuscode,
    T.createdon = SAFE_CAST(S.createdon AS DATE),
    T.estimatedvalue = SAFE_CAST(S.estimatedvalue AS FLOAT64),
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
    SAFE_CAST(S.createdon AS DATE),
    SAFE_CAST(S.estimatedvalue AS FLOAT64),
    S.currencycode
  );

-- =============================================================================
-- Entity: dim_product
-- =============================================================================
MERGE `${project_id}.${curated_dataset}.dim_product` AS T
USING (
  SELECT
    * EXCEPT(rn)
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER(PARTITION BY productid ORDER BY _metadata_load_timestamp DESC) AS rn
    FROM
      `${project_id}.staging_dataset.stg_product`
  )
  WHERE rn = 1
) AS S
ON T.productid = S.productid
WHEN MATCHED THEN
  UPDATE SET
    T.name = S.name,
    T.category = S.category,
    T.price = SAFE_CAST(S.price AS FLOAT64),
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
    SAFE_CAST(S.price AS FLOAT64),
    S.currencycode
  );

-- =============================================================================
-- Entity: dim_sales_rep
-- =============================================================================
MERGE `${project_id}.${curated_dataset}.dim_sales_rep` AS T
USING (
  SELECT
    * EXCEPT(rn)
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER(PARTITION BY salesrepid ORDER BY _metadata_load_timestamp DESC) AS rn
    FROM
      `${project_id}.staging_dataset.stg_sales_rep`
  )
  WHERE rn = 1
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
MERGE `${project_id}.${curated_dataset}.fact_quotes` AS T
USING (
  SELECT
    * EXCEPT(rn)
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER(PARTITION BY quoteid ORDER BY _metadata_load_timestamp DESC) AS rn
    FROM
      `${project_id}.staging_dataset.stg_quote`
  )
  WHERE rn = 1
) AS S
ON T.quoteid = S.quoteid
WHEN MATCHED THEN
  UPDATE SET
    T.opportunityid = S.opportunityid,
    T.customerid = S.customerid,
    T.accountid = S.accountid,
    T.salesrepid = S.salesrepid,
    T.totalamount = SAFE_CAST(S.totalamount AS FLOAT64),
    T.statuscode = S.statuscode,
    T.createdon = SAFE_CAST(S.createdon AS TIMESTAMP),
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
    SAFE_CAST(S.totalamount AS FLOAT64),
    S.statuscode,
    SAFE_CAST(S.createdon AS TIMESTAMP),
    S.currencycode
  );

-- =============================================================================
-- Entity: fact_quote_details
-- =============================================================================
MERGE `${project_id}.${curated_dataset}.fact_quote_details` AS T
USING (
  SELECT
    * EXCEPT(rn)
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER(PARTITION BY quoteid, productid ORDER BY _metadata_load_timestamp DESC) AS rn
    FROM
      `${project_id}.staging_dataset.stg_quote_details`
  )
  WHERE rn = 1
) AS S
ON T.quoteid = S.quoteid AND T.productid = S.productid
WHEN MATCHED THEN
  UPDATE SET
    T.quantity = SAFE_CAST(S.quantity AS INT64),
    T.priceperunit = SAFE_CAST(S.priceperunit AS FLOAT64),
    T.extendedamount = SAFE_CAST(S.extendedamount AS FLOAT64)
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
    SAFE_CAST(S.quantity AS INT64),
    SAFE_CAST(S.priceperunit AS FLOAT64),
    SAFE_CAST(S.extendedamount AS FLOAT64)
  );

-- =============================================================================
-- Entity: fact_sales
-- =============================================================================
MERGE `${project_id}.${curated_dataset}.fact_sales` AS T
USING (
  SELECT
    * EXCEPT(rn)
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER(PARTITION BY salesorderid ORDER BY _metadata_load_timestamp DESC) AS rn
    FROM
      `${project_id}.staging_dataset.stg_sales`
  )
  WHERE rn = 1
) AS S
ON T.salesorderid = S.salesorderid
WHEN MATCHED THEN
  UPDATE SET
    T.opportunityid = S.opportunityid,
    T.customerid = S.customerid,
    T.accountid = S.accountid,
    T.salesrepid = S.salesrepid,
    T.totalamount = SAFE_CAST(S.totalamount AS FLOAT64),
    T.statuscode = S.statuscode,
    T.createdon = SAFE_CAST(S.createdon AS TIMESTAMP),
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
    SAFE_CAST(S.totalamount AS FLOAT64),
    S.statuscode,
    SAFE_CAST(S.createdon AS TIMESTAMP),
    S.currencycode
  );

-- =============================================================================
-- Entity: fact_sales_details
-- =============================================================================
MERGE `${project_id}.${curated_dataset}.fact_sales_details` AS T
USING (
  SELECT
    * EXCEPT(rn)
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER(PARTITION BY salesdetailid ORDER BY _metadata_load_timestamp DESC) AS rn
    FROM
      `${project_id}.staging_dataset.stg_sales_details`
  )
  WHERE rn = 1
) AS S
ON T.salesdetailid = S.salesdetailid
WHEN MATCHED THEN
  UPDATE SET
    T.salesorderid = S.salesorderid,
    T.productid = S.productid,
    T.quantity = SAFE_CAST(S.quantity AS INT64),
    T.priceperunit = SAFE_CAST(S.priceperunit AS FLOAT64),
    T.extendedamount = SAFE_CAST(S.extendedamount AS FLOAT64)
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
    SAFE_CAST(S.quantity AS INT64),
    SAFE_CAST(S.priceperunit AS FLOAT64),
    SAFE_CAST(S.extendedamount AS FLOAT64)
  );
