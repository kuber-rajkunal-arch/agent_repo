-- Unit tests for crm_code_files/Mapping_Document_oracle_plsql_v4_full_20260514_144614.sql

-- This test suite replicates the logic of the target script against a controlled
-- set of mock data to verify its behavior under various conditions.
WITH
  -- Mock Input Table: AeroSrc.Flight
  mock_flight AS (
    -- Scenario 1: Aircraft 'AC-101' to test all OP_STATUS branches
    -- 9 normal flights to establish a baseline for Z-score
    SELECT 'F-101-1' AS FLIGHT_ID, 'AC-101' AS AIRCRAFT_ID, CURRENT_TIMESTAMP() AS FLIGHT_TS, 50 AS ENGINE_TEMP, 0.5 AS FATIGUE_INDEX, '{"engine":{"vibration":1.0}}' AS TELEMETRY_JSON UNION ALL
    SELECT 'F-101-2', 'AC-101', CURRENT_TIMESTAMP(), 50, 0.5, '{"engine":{"vibration":1.0}}' UNION ALL
    SELECT 'F-101-3', 'AC-101', CURRENT_TIMESTAMP(), 50, 0.5, '{"engine":{"vibration":1.0}}' UNION ALL
    SELECT 'F-101-4', 'AC-101', CURRENT_TIMESTAMP(), 50, 0.5, '{"engine":{"vibration":1.0}}' UNION ALL
    SELECT 'F-101-5', 'AC-101', CURRENT_TIMESTAMP(), 50, 0.5, '{"engine":{"vibration":1.0}}' UNION ALL
    SELECT 'F-101-6', 'AC-101', CURRENT_TIMESTAMP(), 50, 0.5, '{"engine":{"vibration":1.0}}' UNION ALL
    SELECT 'F-101-7', 'AC-101', CURRENT_TIMESTAMP(), 50, 0.5, '{"engine":{"vibration":1.0}}' UNION ALL
    SELECT 'F-101-8', 'AC-101', CURRENT_TIMESTAMP(), 50, 0.5, '{"engine":{"vibration":1.0}}' UNION ALL
    SELECT 'F-101-9', 'AC-101', CURRENT_TIMESTAMP(), 50, 0.5, '{"engine":{"vibration":1.0}}' UNION ALL
    -- 1 flight with a vibration outlier to trigger VIBRATION_ANOMALY_DETECTED (Z-score > 2)
    SELECT 'F-101-10', 'AC-101', CURRENT_TIMESTAMP(), 50, 0.1, '{"engine":{"vibration":10.0}}' UNION ALL
    -- 1 flight with high temp/fatigue to trigger CRITICAL_AOG_REQUIRED (risk_score > 80)
    SELECT 'F-101-11', 'AC-101', CURRENT_TIMESTAMP(), 150, 0.9, '{"engine":{"vibration":1.1}}' UNION ALL

    -- Scenario 2: Aircraft 'AC-202' to test INTEGRITY_FLAG logic
    -- Case for ERR_NEG (negative day_delta)
    SELECT 'F-202-1', 'AC-202', CURRENT_TIMESTAMP(), 70, 0.3, '{"engine":{"vibration":1.5}}' UNION ALL
    -- Case for PASS (positive day_delta)
    SELECT 'F-202-2', 'AC-202', CURRENT_TIMESTAMP(), 70, 0.3, '{"engine":{"vibration":1.5}}' UNION ALL

    -- Scenario 3: Aircraft 'AC-303' to test NULL/invalid JSON handling
    -- Case with missing vibration path in JSON
    SELECT 'F-303-1', 'AC-303', CURRENT_TIMESTAMP(), 80, 0.2, '{"engine":{"other_metric":99}}' UNION ALL
    -- Case with NULL TELEMETRY_JSON
    SELECT 'F-303-2', 'AC-303', CURRENT_TIMESTAMP(), 80, 0.2, NULL UNION ALL

    -- Scenario 4: Aircraft 'AC-404' to test date filtering
    -- Flight older than 365 days, should be excluded
    SELECT 'F-404-1', 'AC-404', TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 400 DAY), 90, 0.1, '{"engine":{"vibration":2.0}}' UNION ALL

    -- Scenario 5: Aircraft 'AC-505' to test INNER JOIN behavior
    -- Flight with no matching maintenance record, should be excluded
    SELECT 'F-505-1', 'AC-505', CURRENT_TIMESTAMP(), 65, 0.25, '{"engine":{"vibration":1.2}}' UNION ALL

    -- Scenario 6: Aircraft 'AC-606' to test Z-score with zero standard deviation
    -- All vibration values are identical, STDDEV is 0, Z-score should be NULL
    SELECT 'F-606-1', 'AC-606', CURRENT_TIMESTAMP(), 75, 0.35, '{"engine":{"vibration":3.0}}' UNION ALL
    SELECT 'F-606-2', 'AC-606', CURRENT_TIMESTAMP(), 75, 0.35, '{"engine":{"vibration":3.0}}'
  ),

  -- Mock Input Table: AeroSrc.Maintenance
  mock_maintenance AS (
    SELECT 'M-101' AS MAINT_EVENT_ID, 'AC-101' AS AIRCRAFT_ID, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 10 DAY) AS EVENT_START_TS, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 8 DAY) AS EVENT_END_TS UNION ALL
    -- Maintenance event with negative duration
    SELECT 'M-202-NEG', 'AC-202', TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 5 DAY), TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 6 DAY) UNION ALL
    -- Maintenance event with positive duration
    SELECT 'M-202-POS', 'AC-202', TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 5 DAY), TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 4 DAY) UNION ALL
    SELECT 'M-303', 'AC-303', TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 3 DAY), TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 DAY) UNION ALL
    SELECT 'M-404', 'AC-404', TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 400 DAY), TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 399 DAY) UNION ALL
    SELECT 'M-606', 'AC-606', TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY), CURRENT_TIMESTAMP() UNION ALL
    -- Maintenance for an aircraft with no flights in the mock data
    SELECT 'M-999', 'AC-999', TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY), CURRENT_TIMESTAMP()
  ),

  -- Re-implementation of the script's transformation logic using mock data
  final_output AS (
    WITH
      c_complex_extract AS (
        SELECT
          f.FLIGHT_ID,
          f.AIRCRAFT_ID,
          f.ENGINE_TEMP,
          f.FATIGUE_INDEX,
          SAFE_CAST(JSON_EXTRACT_SCALAR(f.TELEMETRY_JSON, '$.engine.vibration') AS NUMERIC) AS vib,
          m.MAINT_EVENT_ID,
          m.EVENT_START_TS,
          m.EVENT_END_TS
        FROM
          mock_flight AS f
        INNER JOIN
          mock_maintenance AS m
          ON f.AIRCRAFT_ID = m.AIRCRAFT_ID
        WHERE
          f.FLIGHT_TS > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 365 DAY)
      ),

      c_complex_extract_wrapper AS (
        SELECT
          FLIGHT_ID,
          AIRCRAFT_ID,
          MAINT_EVENT_ID,
          ENGINE_TEMP,
          FATIGUE_INDEX,
          vib,
          (vib - AVG(vib) OVER (PARTITION BY AIRCRAFT_ID)) / NULLIF(STDDEV(vib) OVER (PARTITION BY AIRCRAFT_ID), 0) AS vib_z_score,
          TIMESTAMP_DIFF(EVENT_END_TS, EVENT_START_TS, DAY) AS day_delta
        FROM
          c_complex_extract
      ),

      final_calculations AS (
        SELECT
          *,
          (ENGINE_TEMP * 0.4) + (FATIGUE_INDEX * 100 * 0.4) + (vib * 0.2) AS risk_score
        FROM
          c_complex_extract_wrapper
      )

    SELECT
      final_calcs.FLIGHT_ID,
      final_calcs.AIRCRAFT_ID,
      final_calcs.MAINT_EVENT_ID,
      CASE
        WHEN final_calcs.risk_score > 80 THEN 'CRITICAL_AOG_REQUIRED'
        WHEN final_calcs.vib_z_score > 2 THEN 'VIBRATION_ANOMALY_DETECTED'
        ELSE 'STABLE'
      END AS OP_STATUS,
      final_calcs.risk_score AS RISK_SCORE,
      final_calcs.vib_z_score AS VIB_Z_SCORE,
      CASE
        WHEN final_calcs.day_delta < 0 THEN 'ERR_NEG'
        ELSE 'PASS'
      END AS INTEGRITY_FLAG,
      CURRENT_TIMESTAMP() AS LOAD_TS
    FROM
      final_calculations AS final_calcs
  )

-- test: test_risk_score_calculation
-- Verifies the risk score formula is calculated correctly for a known high-risk flight.
SELECT
  IF(
    -- Risk Score = (150 * 0.4) + (0.9 * 100 * 0.4) + (1.1 * 0.2) = 60 + 36 + 0.22 = 96.22
    ABS(RISK_SCORE - 96.22) < 0.001,
    'PASS',
    'FAIL'
  ) AS result,
  'test_risk_score_calculation' AS test_name
FROM final_output
WHERE FLIGHT_ID = 'F-101-11';

-- test: test_op_status_critical
-- Verifies that a risk score > 80 correctly sets the status to CRITICAL_AOG_REQUIRED.
SELECT
  IF(OP_STATUS = 'CRITICAL_AOG_REQUIRED', 'PASS', 'FAIL') AS result,
  'test_op_status_critical' AS test_name
FROM final_output
WHERE FLIGHT_ID = 'F-101-11';

-- test: test_op_status_vibration_anomaly
-- Verifies that a high Z-score (> 2) correctly sets the status to VIBRATION_ANOMALY_DETECTED.
SELECT
  IF(OP_STATUS = 'VIBRATION_ANOMALY_DETECTED', 'PASS', 'FAIL') AS result,
  'test_op_status_vibration_anomaly' AS test_name
FROM final_output
WHERE FLIGHT_ID = 'F-101-10';

-- test: test_op_status_stable
-- Verifies that a flight with normal parameters is marked as STABLE.
SELECT
  IF(OP_STATUS = 'STABLE', 'PASS', 'FAIL') AS result,
  'test_op_status_stable' AS test_name
FROM final_output
WHERE FLIGHT_ID = 'F-101-1';

-- test: test_integrity_flag_err_neg
-- Verifies that a negative maintenance duration (end before start) flags the record as 'ERR_NEG'.
SELECT
  IF(INTEGRITY_FLAG = 'ERR_NEG', 'PASS', 'FAIL') AS result,
  'test_integrity_flag_err_neg' AS test_name
FROM final_output
WHERE FLIGHT_ID = 'F-202-1' AND MAINT_EVENT_ID = 'M-202-NEG';

-- test: test_integrity_flag_pass
-- Verifies that a non-negative maintenance duration is flagged as 'PASS'.
SELECT
  IF(INTEGRITY_FLAG = 'PASS', 'PASS', 'FAIL') AS result,
  'test_integrity_flag_pass' AS test_name
FROM final_output
WHERE FLIGHT_ID = 'F-202-2' AND MAINT_EVENT_ID = 'M-202-POS';

-- test: test_filter_old_flights
-- Verifies that flights older than 365 days are excluded from the output.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'test_filter_old_flights' AS test_name
FROM final_output
WHERE AIRCRAFT_ID = 'AC-404';

-- test: test_join_excludes_unmatched_flights
-- Verifies that flights without a corresponding maintenance record are excluded due to the INNER JOIN.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'test_join_excludes_unmatched_flights' AS test_name
FROM final_output
WHERE AIRCRAFT_ID = 'AC-505';

-- test: test_null_risk_score_from_invalid_json
-- Verifies that RISK_SCORE is NULL when vibration data is missing from the JSON payload.
SELECT
  IF(RISK_SCORE IS NULL, 'PASS', 'FAIL') AS result,
  'test_null_risk_score_from_invalid_json' AS test_name
FROM final_output
WHERE FLIGHT_ID = 'F-303-1';

-- test: test_null_z_score_from_invalid_json
-- Verifies that VIB_Z_SCORE is NULL when vibration data is missing from the JSON payload.
SELECT
  IF(VIB_Z_SCORE IS NULL, 'PASS', 'FAIL') AS result,
  'test_null_z_score_from_invalid_json' AS test_name
FROM final_output
WHERE FLIGHT_ID = 'F-303-2';

-- test: test_z_score_null_on_zero_stddev
-- Verifies that VIB_Z_SCORE is NULL when standard deviation is zero, preventing division-by-zero errors.
SELECT
  IF(COUNTIF(VIB_Z_SCORE IS NOT NULL) = 0, 'PASS', 'FAIL') AS result,
  'test_z_score_null_on_zero_stddev' AS test_name
FROM final_output
WHERE AIRCRAFT_ID = 'AC-606';

-- test: test_not_null_output_keys
-- Verifies that key identifier fields in the output are never NULL.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'test_not_null_output_keys' AS test_name
FROM final_output
WHERE FLIGHT_ID IS NULL OR AIRCRAFT_ID IS NULL OR MAINT_EVENT_ID IS NULL;

-- test: test_op_status_domain
-- Verifies that OP_STATUS only contains allowed values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'test_op_status_domain' AS test_name
FROM final_output
WHERE OP_STATUS NOT IN ('CRITICAL_AOG_REQUIRED', 'VIBRATION_ANOMALY_DETECTED', 'STABLE');

-- test: test_integrity_flag_domain
-- Verifies that INTEGRITY_FLAG only contains allowed values.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'test_integrity_flag_domain' AS test_name
FROM final_output
WHERE INTEGRITY_FLAG NOT IN ('ERR_NEG', 'PASS');

-- test: test_completeness_load_ts
-- Verifies that the load timestamp is always populated.
SELECT
  IF(COUNTIF(LOAD_TS IS NULL) = 0, 'PASS', 'FAIL') AS result,
  'test_completeness_load_ts' AS test_name
FROM final_output;