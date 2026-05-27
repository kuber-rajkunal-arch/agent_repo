/*
    Unit Tests for FlightDeepMaintenanceFact.sql
    
    This test suite validates the business logic and data transformations
    in the FlightDeepMaintenanceFact.sql script. It uses a common table expression (CTE)
    to define mock input data and then applies the script's logic to this data.
    Each test then asserts a specific outcome on the resulting data set.
*/
WITH
  AeroSrc_Flight_mock AS (
    -- Mock data for the AeroSrc.Flight table
    SELECT 1001 AS FLIGHT_ID, 101 AS AIRCRAFT_ID, 100.0 AS ENGINE_TEMP, 0.2 AS FATIGUE_INDEX, '{"engine": {"vibration": 5.0}}' AS TELEMETRY_JSON, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 10 DAY) AS FLIGHT_TS UNION ALL
    -- Flight to create a vibration anomaly for Aircraft 101 (vib=25 vs vib=5)
    SELECT 1002 AS FLIGHT_ID, 101 AS AIRCRAFT_ID, 105.0 AS ENGINE_TEMP, 0.22 AS FATIGUE_INDEX, '{"engine": {"vibration": 25.0}}' AS TELEMETRY_JSON, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 9 DAY) AS FLIGHT_TS UNION ALL
    -- Flight with high temp/fatigue to trigger CRITICAL status (risk score > 80)
    SELECT 2001 AS FLIGHT_ID, 202 AS AIRCRAFT_ID, 150.0 AS ENGINE_TEMP, 0.6 AS FATIGUE_INDEX, '{"engine": {"vibration": 10.0}}' AS TELEMETRY_JSON, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 20 DAY) AS FLIGHT_TS UNION ALL
    -- Flight associated with a maintenance record having a negative duration
    SELECT 3001 AS FLIGHT_ID, 303 AS AIRCRAFT_ID, 90.0 AS ENGINE_TEMP, 0.1 AS FATIGUE_INDEX, '{"engine": {"vibration": 4.0}}' AS TELEMETRY_JSON, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY) AS FLIGHT_TS UNION ALL
    -- Single flight for an aircraft to test Z-score calculation (should be NULL)
    SELECT 4001 AS FLIGHT_ID, 404 AS AIRCRAFT_ID, 95.0 AS ENGINE_TEMP, 0.15 AS FATIGUE_INDEX, '{"engine": {"vibration": 7.0}}' AS TELEMETRY_JSON, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 40 DAY) AS FLIGHT_TS UNION ALL
    -- Flight with malformed/missing JSON key to test SAFE_CAST
    SELECT 5001 AS FLIGHT_ID, 505 AS AIRCRAFT_ID, 98.0 AS ENGINE_TEMP, 0.18 AS FATIGUE_INDEX, '{"engine": {}}' AS TELEMETRY_JSON, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 50 DAY) AS FLIGHT_TS UNION ALL
    -- Flight that is older than 365 days and should be filtered out
    SELECT 6001 AS FLIGHT_ID, 606 AS AIRCRAFT_ID, 100.0 AS ENGINE_TEMP, 0.2 AS FATIGUE_INDEX, '{"engine": {"vibration": 5.0}}' AS TELEMETRY_JSON, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 400 DAY) AS FLIGHT_TS UNION ALL
    -- Flight where both risk score > 80 and vib_z_score > 2 to test status priority
    SELECT 7001 AS FLIGHT_ID, 707 AS AIRCRAFT_ID, 160.0 AS ENGINE_TEMP, 0.5 AS FATIGUE_INDEX, '{"engine": {"vibration": 5.0}}' AS TELEMETRY_JSON, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 60 DAY) AS FLIGHT_TS UNION ALL
    SELECT 7002 AS FLIGHT_ID, 707 AS AIRCRAFT_ID, 100.0 AS ENGINE_TEMP, 0.2 AS FATIGUE_INDEX, '{"engine": {"vibration": 30.0}}' AS TELEMETRY_JSON, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 59 DAY) AS FLIGHT_TS
  ),

  AeroSrc_Maintenance_mock AS (
    -- Mock data for the AeroSrc.Maintenance table
    SELECT 9001 AS MAINT_EVENT_ID, 101 AS AIRCRAFT_ID, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 8 DAY) AS EVENT_START_TS, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY) AS EVENT_END_TS UNION ALL
    SELECT 9002 AS MAINT_EVENT_ID, 202 AS AIRCRAFT_ID, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 19 DAY) AS EVENT_START_TS, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 18 DAY) AS EVENT_END_TS UNION ALL
    -- Maintenance event with negative duration (end before start)
    SELECT 9003 AS MAINT_EVENT_ID, 303 AS AIRCRAFT_ID, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 28 DAY) AS EVENT_START_TS, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 29 DAY) AS EVENT_END_TS UNION ALL
    SELECT 9004 AS MAINT_EVENT_ID, 404 AS AIRCRAFT_ID, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 39 DAY) AS EVENT_START_TS, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 38 DAY) AS EVENT_END_TS UNION ALL
    SELECT 9005 AS MAINT_EVENT_ID, 505 AS AIRCRAFT_ID, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 49 DAY) AS EVENT_START_TS, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 48 DAY) AS EVENT_END_TS UNION ALL
    SELECT 9006 AS MAINT_EVENT_ID, 606 AS AIRCRAFT_ID, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 399 DAY) AS EVENT_START_TS, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 398 DAY) AS EVENT_END_TS UNION ALL
    SELECT 9007 AS MAINT_EVENT_ID, 707 AS AIRCRAFT_ID, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 58 DAY) AS EVENT_START_TS, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 57 DAY) AS EVENT_END_TS
  ),

  -- =================================================================================
  -- REPLICATION OF THE SOURCE SCRIPT'S LOGIC ON MOCK DATA
  -- =================================================================================
  c_complex_extract_inner AS (
    SELECT
      f.FLIGHT_ID,
      f.AIRCRAFT_ID,
      f.ENGINE_TEMP,
      f.FATIGUE_INDEX,
      SAFE_CAST(JSON_EXTRACT_SCALAR(f.TELEMETRY_JSON, '$.engine.vibration') AS NUMERIC) AS vib,
      m.MAINT_EVENT_ID,
      m.EVENT_START_TS,
      m.EVENT_END_TS,
      AVG(f.ENGINE_TEMP) OVER (PARTITION BY f.AIRCRAFT_ID) AS avg_temp
    FROM
      AeroSrc_Flight_mock AS f
    INNER JOIN
      AeroSrc_Maintenance_mock AS m
      ON f.AIRCRAFT_ID = m.AIRCRAFT_ID
    WHERE
      f.FLIGHT_TS > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 365 DAY)
  ),

  c_complex_extract_wrapper AS (
    SELECT
      *,
      (vib - AVG(vib) OVER (PARTITION BY AIRCRAFT_ID)) / NULLIF(STDDEV(vib) OVER (PARTITION BY AIRCRAFT_ID), 0) AS vib_z_score,
      TIMESTAMP_DIFF(EVENT_END_TS, EVENT_START_TS, DAY) AS day_delta
    FROM
      c_complex_extract_inner
  ),

  final_calculations AS (
    SELECT
      *,
      (ENGINE_TEMP * 0.4) + (FATIGUE_INDEX * 100 * 0.4) + (vib * 0.2) AS risk_score
    FROM
      c_complex_extract_wrapper
  ),

  model_output AS (
    -- Final output projection, mirroring the source script's final SELECT
    SELECT
      FLIGHT_ID,
      AIRCRAFT_ID,
      MAINT_EVENT_ID,
      CASE
        WHEN risk_score > 80 THEN 'CRITICAL_AOG_REQUIRED'
        WHEN vib_z_score > 2 THEN 'VIBRATION_ANOMALY_DETECTED'
        ELSE 'STABLE'
      END AS OP_STATUS,
      risk_score AS RISK_SCORE,
      vib_z_score AS VIB_Z_SCORE,
      CASE
        WHEN day_delta < 0 THEN 'ERR_NEG'
        ELSE 'PASS'
      END AS INTEGRITY_FLAG,
      CURRENT_TIMESTAMP() AS LOAD_TS
    FROM
      final_calculations
  )

-- =================================================================================
-- BEGIN UNIT TESTS
-- =================================================================================

-- test: not_null_primary_keys
-- Verifies that key identifiers are always populated.
SELECT
  IF(
    COUNTIF(FLIGHT_ID IS NULL) = 0 AND
    COUNTIF(AIRCRAFT_ID IS NULL) = 0 AND
    COUNTIF(MAINT_EVENT_ID IS NULL) = 0,
    'PASS', 'FAIL'
  ) AS result,
  'not_null_primary_keys' AS test_name
FROM model_output;

-- test: not_null_core_fields
-- Verifies that critical calculated and metadata fields are always populated.
-- VIB_Z_SCORE is excluded as it can be legitimately NULL for single-flight aircraft.
SELECT
  IF(
    COUNTIF(OP_STATUS IS NULL) = 0 AND
    COUNTIF(RISK_SCORE IS NULL) = 0 AND
    COUNTIF(INTEGRITY_FLAG IS NULL) = 0 AND
    COUNTIF(LOAD_TS IS NULL) = 0,
    'PASS', 'FAIL'
  ) AS result,
  'not_null_core_fields' AS test_name
FROM model_output;

-- test: domain_op_status
-- Ensures OP_STATUS contains only allowed values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'domain_op_status' AS test_name
FROM model_output
WHERE OP_STATUS NOT IN ('STABLE', 'VIBRATION_ANOMALY_DETECTED', 'CRITICAL_AOG_REQUIRED');

-- test: domain_integrity_flag
-- Ensures INTEGRITY_FLAG contains only allowed values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'domain_integrity_flag' AS test_name
FROM model_output
WHERE INTEGRITY_FLAG NOT IN ('PASS', 'ERR_NEG');

-- test: logic_op_status_critical
-- Verifies that a high risk score correctly flags the status as CRITICAL.
SELECT
  IF(COUNT(*) = 1, 'PASS', 'FAIL') AS result,
  'logic_op_status_critical' AS test_name
FROM model_output
WHERE FLIGHT_ID = 2001 AND OP_STATUS = 'CRITICAL_AOG_REQUIRED';

-- test: logic_op_status_vibration_anomaly
-- Verifies that a high vibration Z-score correctly flags a vibration anomaly.
-- For aircraft 101, flight 1002 has a much higher vibration than 1001, resulting in a high Z-score.
SELECT
  IF(COUNT(*) = 1, 'PASS', 'FAIL') AS result,
  'logic_op_status_vibration_anomaly' AS test_name
FROM model_output
WHERE FLIGHT_ID = 1002 AND OP_STATUS = 'VIBRATION_ANOMALY_DETECTED';

-- test: logic_op_status_stable
-- Verifies that a normal flight is correctly flagged as STABLE.
SELECT
  IF(COUNT(*) = 1, 'PASS', 'FAIL') AS result,
  'logic_op_status_stable' AS test_name
FROM model_output
WHERE FLIGHT_ID = 1001 AND OP_STATUS = 'STABLE';

-- test: logic_op_status_priority
-- Verifies that CRITICAL status takes precedence over VIBRATION ANOMALY when both conditions are met.
-- Flight 7002 has both a high risk score (from its aircraft's high-temp flight 7001) and a high vibration.
SELECT
  IF(COUNT(*) = 1, 'PASS', 'FAIL') AS result,
  'logic_op_status_priority' AS test_name
FROM model_output
WHERE FLIGHT_ID = 7002 AND OP_STATUS = 'CRITICAL_AOG_REQUIRED';

-- test: logic_integrity_flag_error
-- Verifies that a negative maintenance duration correctly sets the integrity flag to 'ERR_NEG'.
SELECT
  IF(COUNT(*) = 1, 'PASS', 'FAIL') AS result,
  'logic_integrity_flag_error' AS test_name
FROM model_output
WHERE FLIGHT_ID = 3001 AND INTEGRITY_FLAG = 'ERR_NEG';

-- test: logic_integrity_flag_pass
-- Verifies that a valid maintenance duration correctly sets the integrity flag to 'PASS'.
SELECT
  IF(COUNT(*) = 1, 'PASS', 'FAIL') AS result,
  'logic_integrity_flag_pass' AS test_name
FROM model_output
WHERE FLIGHT_ID = 1001 AND INTEGRITY_FLAG = 'PASS';

-- test: calculation_risk_score
-- Validates the risk score formula for a known input.
-- For flight 1001: (100.0 * 0.4) + (0.2 * 100 * 0.4) + (5.0 * 0.2) = 40 + 8 + 1 = 49
SELECT
  IF(ABS(RISK_SCORE - 49.0) < 0.001, 'PASS', 'FAIL') AS result,
  'calculation_risk_score' AS test_name
FROM model_output
WHERE FLIGHT_ID = 1001;

-- test: calculation_vib_z_score_is_null_for_single_flight
-- Verifies that VIB_Z_SCORE is NULL when STDDEV is zero (or NULL), which occurs for aircraft with a single flight record.
SELECT
  IF(VIB_Z_SCORE IS NULL, 'PASS', 'FAIL') AS result,
  'calculation_vib_z_score_is_null_for_single_flight' AS test_name
FROM model_output
WHERE FLIGHT_ID = 4001;

-- test: behavior_filter_old_flights
-- Verifies that flights older than 365 days are correctly excluded from the output.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'behavior_filter_old_flights' AS test_name
FROM model_output
WHERE FLIGHT_ID = 6001;

-- test: behavior_handle_null_json_value
-- Verifies that if JSON extraction fails (due to missing key), the vibration-dependent fields are handled gracefully (become NULL).
SELECT
  IF(VIB_Z_SCORE IS NULL AND RISK_SCORE IS NULL, 'PASS', 'FAIL') AS result,
  'behavior_handle_null_json_value' AS test_name
FROM model_output
WHERE FLIGHT_ID = 5001;
