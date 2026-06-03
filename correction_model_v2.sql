INSERT INTO `gcp-cloud-source-repo.phenominal.correction_table` (column_a, column_b, partition_date)
SELECT
  1 AS column_a,
  'dummy_value' AS column_b,
  CURRENT_DATE() as partition_date;
