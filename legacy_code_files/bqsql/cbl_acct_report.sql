-- Copyright (c) 2023. Google LLC.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- This BQSQL script creates and populates a table based on the COBOL
-- copybook for ACCT-REC and creates a view that reproduces the logic
-- from the CBL0005 program.

--
-- 1. DDL for the source table `acct_rec`
-- This table structure is derived from the `FD ACCT-REC` section in the
-- source COBOL programs.
--
CREATE OR REPLACE TABLE mydataset.acct_rec
(
  acct_no      STRING(8)    OPTIONS(description="Corresponds to ACCT-NO PIC X(8)"),
  acct_limit   NUMERIC(9, 2) OPTIONS(description="Corresponds to ACCT-LIMIT PIC S9(7)V99 COMP-3"),
  acct_balance NUMERIC(9, 2) OPTIONS(description="Corresponds to ACCT-BALANCE PIC S9(7)V99 COMP-3"),
  last_name    STRING(20)   OPTIONS(description="Corresponds to LAST-NAME PIC X(20)"),
  first_name   STRING(15)   OPTIONS(description="Corresponds to FIRST-NAME PIC X(15)"),
  street_addr  STRING(25)   OPTIONS(description="Corresponds to STREET-ADDR PIC X(25)"),
  city_county  STRING(20)   OPTIONS(description="Corresponds to CITY-COUNTY PIC X(20)"),
  usa_state    STRING(15)   OPTIONS(description="Corresponds to USA-STATE PIC X(15)"),
  reserved     STRING(7)    OPTIONS(description="Corresponds to RESERVED PIC X(7)"),
  comments     STRING(50)   OPTIONS(description="Corresponds to COMMENTS PIC X(50)")
)
OPTIONS(
  description="BigQuery representation of the ACCT-REC file layout from the COBOL source."
);

--
-- 2. Data Population for `acct_rec`
-- This MERGE statement provides idempotent sample data for the table.
--
MERGE mydataset.acct_rec AS T
USING (
  SELECT '10000001' AS acct_no, CAST('10000.00' AS NUMERIC(9,2)) AS acct_limit, CAST('543.21' AS NUMERIC(9,2)) AS acct_balance, 'Smith' AS last_name, 'John' AS first_name, '123 Main St' AS street_addr, 'Anytown' AS city_county, 'CA' AS usa_state, NULL AS reserved, 'Valued customer' AS comments UNION ALL
  SELECT '10000002', CAST('5000.00' AS NUMERIC(9,2)), CAST('-125.50' AS NUMERIC(9,2)), 'Doe', 'Jane', '456 Oak Ave', 'Someplace', 'NY', NULL, 'New account' UNION ALL
  SELECT '10000003', CAST('120000.00' AS NUMERIC(9,2)), CAST('115000.75' AS NUMERIC(9,2)), 'Jones', 'Peter', '789 Pine Ln', 'Elsewhere', 'TX', NULL, '' UNION ALL
  SELECT '10000004', CAST('0.00' AS NUMERIC(9,2)), CAST('0.00' AS NUMERIC(9,2)), 'Rubio', 'Maria', '101 First Ave', 'Metropolis', 'IL', NULL, 'Account pending activation'
) AS S
ON T.acct_no = S.acct_no
WHEN NOT MATCHED THEN
  INSERT (acct_no, acct_limit, acct_balance, last_name, first_name, street_addr, city_county, usa_state, reserved, comments)
  VALUES (acct_no, acct_limit, acct_balance, last_name, first_name, street_addr, city_county, usa_state, reserved, comments)
WHEN MATCHED THEN
  UPDATE SET
    T.acct_limit = S.acct_limit,
    T.acct_balance = S.acct_balance,
    T.last_name = S.last_name,
    T.first_name = S.first_name,
    T.street_addr = S.street_addr,
    T.city_county = S.city_county,
    T.usa_state = S.usa_state,
    T.comments = S.comments;

--
-- 3. View Definition for the Financial Report
-- This view models the data output of the COBOL program CBL0005.
-- It selects the primary fields for the financial report and provides
-- both the raw data types for analysis and the COBOL-style formatted
-- string representations for reporting.
--
CREATE OR REPLACE VIEW mydataset.vw_cbl0005_financial_report AS
/*
*   Source Logic from CBL0005 `WRITE-RECORD` paragraph:
*   ---------------------------------------------------
*   MOVE ACCT-NO      TO  ACCT-NO-O.
*   MOVE ACCT-LIMIT   TO  ACCT-LIMIT-O.
*   MOVE ACCT-BALANCE TO  ACCT-BALANCE-O.
*   MOVE LAST-NAME    TO  LAST-NAME-O.
*
*   Source Formatting from CBL0005 `PRINT-REC` layout:
*   --------------------------------------------------
*   05  ACCT-NO-O      PIC X(8).
*   05  LAST-NAME-O    PIC X(20).
*   05  ACCT-LIMIT-O   PIC ZZ,ZZZ,ZZ9.99.
*   05  ACCT-BALANCE-O PIC ZZ,ZZZ,ZZ9.99.
*/
SELECT
  -- Raw data fields from acct_rec for analytical use
  acct_no,
  last_name,
  acct_limit,
  acct_balance,

  -- Renamed fields corresponding to the `MOVE` operations in COBOL
  acct_no AS acct_no_o,
  last_name AS last_name_o,

  -- Formatted fields that replicate the COBOL `PIC` clause behavior.
  -- The format `PIC ZZ,ZZZ,ZZ9.99` implies a 13-character field
  -- (includes sign, 7 digits, 2 commas, decimal point, 2 decimals)
  -- that is space-padded on the left (zero suppression).
  LPAD(FORMAT('%,.2f', acct_limit), 13, ' ') AS acct_limit_o,
  LPAD(FORMAT('%,.2f', acct_balance), 13, ' ') AS acct_balance_o
FROM
  `mydataset.acct_rec`;
