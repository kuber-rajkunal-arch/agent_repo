/*
 * Copyright Contributors to the COBOL Programming Course
 * SPDX-License-Identifier: CC-BY-4.0
 *
 * This BQSQL script is a translation of the business logic
 * contained in the COBOL program CBL0005.
 *
 * It creates a view that replicates the record processing and output
 * formatting of the original program.
 *
 * MAPPING:
 *   - COBOL Program: CBL0005
 *   - Input File: ACCT-REC -> Source Table: `your_project.your_dataset.acct_rec`
 *   - Output File: PRINT-LINE -> This View: `your_project.your_dataset.cbl0005_financial_report`
 *   - PROCEDURE DIVISION Logic: The main read/write loop is implemented as a SELECT statement.
 *     The formatting of numeric fields (`PIC ZZ,ZZZ,ZZ9.99`) is handled using
 *     the `FORMAT` and `LPAD` functions to match the COBOL picture clause.
 */
CREATE OR REPLACE VIEW `your_project.your_dataset.cbl0005_financial_report`
OPTIONS(
  description="Generates a financial report view based on the logic from CBL0005.cobol. This view selects and formats account data from the acct_rec table."
)
AS
SELECT
  -- Corresponds to COBOL statement: MOVE ACCT-NO TO ACCT-NO-O.
  -- PIC X(8)
  t.ACCT_NO AS ACCT_NO_O,

  -- Corresponds to COBOL statement: MOVE LAST-NAME TO LAST-NAME-O.
  -- PIC X(20)
  t.LAST_NAME AS LAST_NAME_O,

  -- Corresponds to COBOL statement: MOVE ACCT-LIMIT TO ACCT-LIMIT-O.
  -- PIC ZZ,ZZZ,ZZ9.99 (13 characters total width)
  -- This format emulates the COBOL picture clause by creating a
  -- comma-separated numeric string and left-padding it with spaces to a
  -- fixed width of 13 characters, effectively suppressing leading zeros with spaces.
  LPAD(FORMAT('%,.2f', t.ACCT_LIMIT), 13, ' ') AS ACCT_LIMIT_O,

  -- Corresponds to COBOL statement: MOVE ACCT-BALANCE TO ACCT-BALANCE-O.
  -- PIC ZZ,ZZZ,ZZ9.99 (13 characters total width)
  -- This format emulates the COBOL picture clause similarly.
  LPAD(FORMAT('%,.2f', t.ACCT_BALANCE), 13, ' ') AS ACCT_BALANCE_O

FROM
  -- This represents the input file ACCT-REC.
  -- The table schema should match the ACCT-FIELDS layout.
  `your_project.your_dataset.acct_rec` AS t;