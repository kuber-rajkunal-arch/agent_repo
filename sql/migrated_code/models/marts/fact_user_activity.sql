CREATE OR REPLACE TABLE fact_user_activity
AS
WITH
  AggregatedActivity AS (
    SELECT
      DATE(event_ts) AS activity_date,
      user_id,
      attributes.device AS device,
      COUNT(1) AS event_count,
      SUM(metric) AS metric_total,
      AVG(metric) AS metric_avg
    FROM
      raw_events,
      UNNEST(metrics) AS metric
    GROUP BY
      activity_date,
      user_id,
      device
  )
SELECT
  activity_date,
  user_id,
  device,
  event_count,
  metric_total,
  metric_avg,
  RANK() OVER (PARTITION BY activity_date ORDER BY metric_total DESC) AS activity_rank
FROM
  AggregatedActivity;