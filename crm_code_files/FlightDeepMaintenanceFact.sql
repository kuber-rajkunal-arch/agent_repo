/*
    This script processes raw flight telemetry and maintenance records to generate an
    enriched data set for the FlightDeepMaintenanceFact table.

    Logic derived from: oracle_plsql_v4_full
*/
BEGIN
  INSERT INTO `FlightDeepMaintenanceFact` (
    FLIGHT_ID,
    AIRCRAFT_ID,
    MAINT_EVENT_ID,
    OP_STATUS,
    RISK_SCORE,
    VIB_Z_SCORE,
    INTEGRITY_FLAG,
    LOAD_TS
  )
  WITH
    c_complex_extract_inner AS (
      -- SECTION 1: Join flight and maintenance records, extract telemetry, and
      -- calculate average temperature per aircraft.
      SELECT
        f.FLIGHT_ID,
        f.AIRCRAFT_ID,
        f.ENGINE_TEMP,
        f.FATIGUE_INDEX,
        -- Extracts vibration value from a JSON string.
        SAFE_CAST(JSON_EXTRACT_SCALAR(f.TELEMETRY_JSON, '$.engine.vibration') AS NUMERIC) AS vib,
        m.MAINT_EVENT_ID,
        m.EVENT_START_TS,
        m.EVENT_END_TS,
        -- Analytic function to calculate the average temperature per aircraft.
        AVG(f.ENGINE_TEMP) OVER (PARTITION BY f.AIRCRAFT_ID) AS avg_temp
      FROM
        `AeroSrc.Flight` AS f
      INNER JOIN
        `AeroSrc.Maintenance` AS m
        ON f.AIRCRAFT_ID = m.AIRCRAFT_ID
      WHERE
        -- Filter for flights within the last 365 days.
        f.FLIGHT_TS > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 365 DAY)
    ),

    c_complex_extract_wrapper AS (
      -- SECTION 2: Calculate the vibration Z-score and maintenance duration.
      SELECT
        *,
        -- Standard Z-score calculation for engine vibration.
        (vib - AVG(vib) OVER (PARTITION BY AIRCRAFT_ID)) / NULLIF(STDDEV(vib) OVER (PARTITION BY AIRCRAFT_ID), 0) AS vib_z_score,
        -- Calculate the duration of the maintenance event in days.
        TIMESTAMP_DIFF(EVENT_END_TS, EVENT_START_TS, DAY) AS day_delta
      FROM
        c_complex_extract_inner
    ),

    final_calculations AS (
      -- Apply final business logic calculations before insertion.
      SELECT
        *,
        -- Calculate safety risk score based on engine temperature, fatigue, and vibration.
        -- Logic: (temp * 0.4) + (fatigue * 100 * 0.4) + (vib * 0.2)
        (ENGINE_TEMP * 0.4) + (FATIGUE_INDEX * 100 * 0.4) + (vib * 0.2) AS risk_score
      FROM
        c_complex_extract_wrapper
    )

  -- FINAL OUTPUT: Select and transform columns for insertion into the fact table.
  SELECT
    FLIGHT_ID,
    AIRCRAFT_ID,
    MAINT_EVENT_ID,
    -- Determine operational status based on risk score and vibration anomalies.
    CASE
      WHEN risk_score > 80 THEN 'CRITICAL_AOG_REQUIRED'
      WHEN vib_z_score > 2 THEN 'VIBRATION_ANOMALY_DETECTED'
      ELSE 'STABLE'
    END AS OP_STATUS,
    risk_score AS RISK_SCORE,
    vib_z_score AS VIB_Z_SCORE,
    -- Derive a data quality flag based on the calculated maintenance duration.
    CASE
      WHEN day_delta < 0 THEN 'ERR_NEG'
      ELSE 'PASS'
    END AS INTEGRITY_FLAG,
    -- Populate with the current timestamp for load auditing.
    CURRENT_TIMESTAMP() AS LOAD_TS
  FROM
    final_calculations;

EXCEPTION WHEN ERROR THEN
  -- Generic error handler to log exceptions to an error table.
  INSERT INTO `Maint_Error_Log` (ErrorMessage, StackTrace, ErrorTimestamp)
  VALUES (@@error.message, @@error.stack_trace, CURRENT_TIMESTAMP());
END;