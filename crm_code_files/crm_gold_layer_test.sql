-- Unit tests for the crm_gold_layer.sql script.
-- These tests are designed to run against the `FlightDeepMaintenanceFact` table
-- to validate the output of the transformation logic.

-- test: not_null_flight_id
-- The FLIGHT_ID is a core part of the primary key and must always be populated.
SELECT
  IF(COUNTIF(FLIGHT_ID IS NULL) = 0, 'PASS', 'FAIL') AS result,
  'not_null_flight_id' AS test_name
FROM
  `FlightDeepMaintenanceFact`;

-- test: not_null_aircraft_id
-- The AIRCRAFT_ID is a core part of the primary key and join key, and must always be populated.
SELECT
  IF(COUNTIF(AIRCRAFT_ID IS NULL) = 0, 'PASS', 'FAIL') AS result,
  'not_null_aircraft_id' AS test_name
FROM
  `FlightDeepMaintenanceFact`;

-- test: not_null_maint_event_id
-- The MAINT_EVENT_ID is a core part of the primary key and must always be populated.
SELECT
  IF(COUNTIF(MAINT_EVENT_ID IS NULL) = 0, 'PASS', 'FAIL') AS result,
  'not_null_maint_event_id' AS test_name
FROM
  `FlightDeepMaintenanceFact`;

-- test: not_null_op_status
-- The operational status is a critical derived field and should never be null.
SELECT
  IF(COUNTIF(OP_STATUS IS NULL) = 0, 'PASS', 'FAIL') AS result,
  'not_null_op_status' AS test_name
FROM
  `FlightDeepMaintenanceFact`;

-- test: not_null_risk_score
-- The RISK_SCORE is a key calculated metric and must always be populated.
SELECT
  IF(COUNTIF(RISK_SCORE IS NULL) = 0, 'PASS', 'FAIL') AS result,
  'not_null_risk_score' AS test_name
FROM
  `FlightDeepMaintenanceFact`;

-- test: not_null_integrity_flag
-- The data integrity flag must always be populated.
SELECT
  IF(COUNTIF(INTEGRITY_FLAG IS NULL) = 0, 'PASS', 'FAIL') AS result,
  'not_null_integrity_flag' AS test_name
FROM
  `FlightDeepMaintenanceFact`;

-- test: not_null_load_ts
-- The load timestamp must always be populated for auditing purposes.
SELECT
  IF(COUNTIF(LOAD_TS IS NULL) = 0, 'PASS', 'FAIL') AS result,
  'not_null_load_ts' AS test_name
FROM
  `FlightDeepMaintenanceFact`;

-- test: uniqueness_primary_key
-- The combination of FLIGHT_ID, AIRCRAFT_ID, and MAINT_EVENT_ID should uniquely identify each record.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'uniqueness_primary_key' AS test_name
FROM (
  SELECT
    FLIGHT_ID,
    AIRCRAFT_ID,
    MAINT_EVENT_ID
  FROM
    `FlightDeepMaintenanceFact`
  GROUP BY
    1, 2, 3
  HAVING
    COUNT(*) > 1
);

-- test: domain_op_status
-- The OP_STATUS field must contain one of the predefined values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'domain_op_status' AS test_name
FROM
  `FlightDeepMaintenanceFact`
WHERE
  OP_STATUS NOT IN ('CRITICAL_AOG_REQUIRED', 'VIBRATION_ANOMALY_DETECTED', 'STABLE');

-- test: domain_integrity_flag
-- The INTEGRITY_FLAG field must contain one of the predefined values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'domain_integrity_flag' AS test_name
FROM
  `FlightDeepMaintenanceFact`
WHERE
  INTEGRITY_FLAG NOT IN ('PASS', 'ERR_NEG');

-- test: logic_op_status_critical
-- If OP_STATUS is 'CRITICAL_AOG_REQUIRED', the RISK_SCORE must be greater than 80.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'logic_op_status_critical' AS test_name
FROM
  `FlightDeepMaintenanceFact`
WHERE
  OP_STATUS = 'CRITICAL_AOG_REQUIRED' AND RISK_SCORE <= 80;

-- test: logic_op_status_vibration_anomaly
-- If OP_STATUS is 'VIBRATION_ANOMALY_DETECTED', RISK_SCORE must be <= 80 and VIB_Z_SCORE must be > 2.
-- This confirms the precedence of the CASE statement logic.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'logic_op_status_vibration_anomaly' AS test_name
FROM
  `FlightDeepMaintenanceFact`
WHERE
  OP_STATUS = 'VIBRATION_ANOMALY_DETECTED' AND (RISK_SCORE > 80 OR VIB_Z_SCORE <= 2);

-- test: logic_op_status_stable
-- If OP_STATUS is 'STABLE', RISK_SCORE must be <= 80 and VIB_Z_SCORE must be <= 2.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'logic_op_status_stable' AS test_name
FROM
  `FlightDeepMaintenanceFact`
WHERE
  OP_STATUS = 'STABLE' AND (RISK_SCORE > 80 OR VIB_Z_SCORE > 2);

-- test: range_risk_score_non_negative
-- Assuming input metrics are non-negative, the calculated RISK_SCORE should not be negative.
SELECT
  IF(COUNTIF(RISK_SCORE < 0) = 0, 'PASS', 'FAIL') AS result,
  'range_risk_score_non_negative' AS test_name
FROM
  `FlightDeepMaintenanceFact`;

-- test: range_load_ts_is_recent
-- The load timestamp should be recent (e.g., within the last 24 hours) and not in the future.
-- This helps detect stale data or clock synchronization issues.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_load_ts_is_recent' AS test_name
FROM
  `FlightDeepMaintenanceFact`
WHERE
  LOAD_TS < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY) OR LOAD_TS > CURRENT_TIMESTAMP();

-- test: referential_flight_aircraft_id
-- Every (FLIGHT_ID, AIRCRAFT_ID) pair in the fact table must exist in the source Flight table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_flight_aircraft_id' AS test_name
FROM
  `FlightDeepMaintenanceFact` AS fact
LEFT JOIN
  `AeroSrc.Flight` AS src ON fact.FLIGHT_ID = src.FLIGHT_ID AND fact.AIRCRAFT_ID = src.AIRCRAFT_ID
WHERE
  src.FLIGHT_ID IS NULL;

-- test: referential_maint_aircraft_id
-- Every (MAINT_EVENT_ID, AIRCRAFT_ID) pair in the fact table must exist in the source Maintenance table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_maint_aircraft_id' AS test_name
FROM
  `FlightDeepMaintenanceFact` AS fact
LEFT JOIN
  `AeroSrc.Maintenance` AS src ON fact.MAINT_EVENT_ID = src.MAINT_EVENT_ID AND fact.AIRCRAFT_ID = src.AIRCRAFT_ID
WHERE
  src.MAINT_EVENT_ID IS NULL;