CREATE OR REPLACE PROCEDURE `enterprise_dwh.reporting.cbl0005_generate_report`()
OPTIONS(
  description="Generates a fixed-width financial report based on the logic from COBOL program CBL0005. It reads account data and produces a 60-character wide formatted text report."
)
BEGIN

  -- This procedure emulates the behavior of the COBOL program CBL0005.
  -- Key behaviors replicated:
  -- 1. Reads from an account master source (`acct_rec`).
  -- 2. Produces a fixed-width (60 characters) report output (`PRINT-LINE`).
  -- 3. Generates headers with the current date.
  -- 4. Formats numeric fields with leading spaces, commas, and two decimal places.
  -- 5. The COBOL `WRITE PRINT-REC FROM HEADER-X` implies that longer header
  --    definitions are truncated to the length of PRINT-REC (60 characters).
  -- 6. Data records are assumed to be processed in order of `acct_no` for
  --    deterministic output, mimicking a sorted input file common in batch processing.

  SELECT
    print_rec
  FROM
    (
      -- Header Line 1: Report Title
      SELECT
        1 AS line_group,
        CAST(NULL AS STRING) AS sort_key,
        RPAD('Financial Report for', 60, ' ') AS print_rec

      UNION ALL

      -- Header Line 2: Report Date
      SELECT
        2,
        NULL,
        RPAD(
          CONCAT(
            'Year ', FORMAT_DATE('%Y', CURRENT_DATE()),
            '  Month ', FORMAT_DATE('%m', CURRENT_DATE()),
            '  Day ', FORMAT_DATE('%d', CURRENT_DATE())
          ),
          60, ' '
        )

      UNION ALL

      -- Blank Line
      SELECT 3, NULL, RPAD('', 60, ' ')

      UNION ALL

      -- Header Line 3: Column Titles
      -- This string is the first 60 characters of the corresponding HEADER-3 definition in COBOL.
      SELECT 4, NULL, 'Account  Last Name               Limit       Balance     '

      UNION ALL

      -- Header Line 4: Column Underlines
      -- This string is the first 60 characters of the corresponding HEADER-4 definition in COBOL.
      SELECT 5, NULL, '--------  ----------               ----------  -------------'

      UNION ALL

      -- Blank Line
      SELECT 6, NULL, RPAD('', 60, ' ')

      UNION ALL

      -- Data Records
      SELECT
        7 AS line_group,
        acct_no AS sort_key,
        CONCAT(
          RPAD(COALESCE(acct_no, ''), 8, ' '),
          '  ',
          RPAD(COALESCE(last_name, ''), 20, ' '),
          '  ',
          LPAD(FORMAT('%,.2f', COALESCE(acct_limit, 0)), 12, ' '),
          '  ',
          LPAD(FORMAT('%,.2f', COALESCE(acct_balance, 0)), 12, ' '),
          '  '
        ) AS print_rec
      FROM
        `enterprise_dwh.raw.cbl0005_acct_rec`
    )
  ORDER BY
    line_group,
    sort_key;

END;