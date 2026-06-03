CREATE OR REPLACE TABLE `gcp-cloud-source-repo.phenominal.correction_table`
(
  column_a INT64 OPTIONS(description="Dummy column A"),
  column_b STRING OPTIONS(description="Dummy column B"),
  partition_date DATE OPTIONS(description="Partition date for daily partitions")
)
PARTITION BY partition_date
CLUSTER BY column_a;
