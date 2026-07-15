/*
================================================================================
Description:
    This script creates or updates the curated customer dimension table (`customer`).
    It implements an incremental, SCD Type 1 loading pattern using a MERGE statement.
    New customer records from staging are inserted, and existing customer records are
    updated with the latest data based on the `customer_id`.

Source(s):
    - `{{ project_id }}.{{ dataset_raw }}.stg_customer`

Target:
    - `{{ project_id }}.{{ dataset_curated }}.customer`

Key(s):
    - `customer_id`

Logic:
    - MERGE statement joins the target table with the source staging table on `customer_id`.
    - WHEN MATCHED: Updates all columns except the primary key (`customer_id`) and the
      original creation timestamp (`created_on`) to reflect the latest source data (SCD Type 1).
    - WHEN NOT MATCHED: Inserts the new customer record from the staging table.
================================================================================
*/

MERGE `{{ project_id }}.{{ dataset_curated }}.customer` AS T
USING `{{ project_id }}.{{ dataset_raw }}.stg_customer` AS S
  ON T.customer_id = S.customer_id

-- Clause for updating existing records (SCD Type 1)
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
    T.modified_on = S.modified_on,
    T.is_active = S.is_active

-- Clause for inserting new records
WHEN NOT MATCHED BY TARGET THEN
  INSERT (
    customer_id,
    customer_type,
    name,
    company_name,
    industry,
    email,
    phone,
    website,
    address_line1,
    address_line2,
    city,
    state,
    country,
    postal_code,
    created_on,
    modified_on,
    is_active
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