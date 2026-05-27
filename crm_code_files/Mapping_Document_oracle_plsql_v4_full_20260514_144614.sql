/*
This script processes raw flight telemetry and maintenance records to generate an
enriched data set for aircraft safety and maintenance analysis, mirroring the logic
from the 'oracle_plsql_v4_full' mapping document.

Logic:
1.  Joins flight and maintenance records from the last 365 days.
2.  Extracts engine vibration data from a JSON telemetry payload.
3.  Calculates a vibration Z-score and maintenance duration using window functions
    and date functions, respectively.
4.  Calculates a final risk score based on temperature, fatigue, and vibration.
5.  Applies conditional logic to determine operational status and data integrity flags.
6.  Inserts the enriched records into the FlightDeepMaintenanceFact table.
7.  Includes error handling to log exceptions to the Maint_Error_Log table.
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
    -- SECTION 1 -- c_complex_extract (Inner Query)
    -- Purpose: To join flight and maintenance records from the last year, extract engine
    -- vibration data from a JSON payload.
    c_complex_extract AS (
      SELECT
        f.FLIGHT_ID,
        f.AIRCRAFT_ID,
        f.ENGINE_TEMP,
        f.FATIGUE_INDEX,
        SAFE_CAST(JSON_EXTRACT_SCALAR(f.TELEMETRY_JSON, '$.engine.vibration') AS NUMERIC) AS vib,
        m.MAINT_EVENT_ID,
        m.EVENT_START_TS,
        m.EVENT_END_TS,
        -- This column is defined in the source doc but not used in subsequent steps.
        -- It is calculated here to fully represent the source logic.
        AVG(f.ENGINE_TEMP) OVER (PARTITION BY f.AIRCRAFT_ID) AS avg_temp
      FROM
        `AeroSrc.Flight` AS f
      INNER JOIN
        `AeroSrc.Maintenance` AS m
        ON f.AIRCRAFT_ID = m.AIRCRAFT_ID
      WHERE
        -- Filter: Filters for flights within the last 365 days.
        f.FLIGHT_TS > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 365 DAY)
    ),

    -- SECTION 2 -- c_complex_extract (Wrapper)
    -- Purpose: Consumes the joined data to calculate the vibration Z-score and the
    -- duration of maintenance events in days.
    c_complex_extract_wrapper AS (
      SELECT
        FLIGHT_ID,
        AIRCRAFT_ID,
        MAINT_EVENT_ID,
        ENGINE_TEMP,
        FATIGUE_INDEX,
        vib,
        -- The calculated Z-score for engine vibration.
        (vib - AVG(vib) OVER (PARTITION BY AIRCRAFT_ID)) / NULLIF(STDDEV(vib) OVER (PARTITION BY AIRCRAFT_ID), 0) AS vib_z_score,
        -- The duration of the maintenance event in days.
        TIMESTAMP_DIFF(EVENT_END_TS, EVENT_START_TS, DAY) AS day_delta
      FROM
        c_complex_extract
    ),

    -- Intermediate step to calculate risk score before using it in the CASE statement.
    final_calculations AS (
      SELECT
        *,
        -- A calculated safety risk score based on engine temperature, fatigue, and vibration.
        -- Inlined logic from PL/SQL function 'calculate_safety_index'.
        (ENGINE_TEMP * 0.4) + (FATIGUE_INDEX * 100 * 0.4) + (vib * 0.2) AS risk_score
      FROM
        c_complex_extract_wrapper
    )

  -- SECTION -- Final Output
  -- Purpose: Selects and transforms data for insertion into the final fact table.
  SELECT
    -- Group 1 -- Identity & Core Fields
    final_calcs.FLIGHT_ID,
    final_calcs.AIRCRAFT_ID,
    final_calcs.MAINT_EVENT_ID,

    -- Group 3 -- Status Fields
    CASE
      WHEN final_calcs.risk_score > 80 THEN 'CRITICAL_AOG_REQUIRED'
      WHEN final_calcs.vib_z_score > 2 THEN 'VIBRATION_ANOMALY_DETECTED'
      ELSE 'STABLE'
    END AS OP_STATUS,

    -- Group 7 -- Extension / Additional Attributes
    final_calcs.risk_score AS RISK_SCORE,
    final_calcs.vib_z_score AS VIB_Z_SCORE,

    -- Group 12 -- Audit & Metadata
    CASE
      WHEN final_calcs.day_delta < 0 THEN 'ERR_NEG'
      ELSE 'PASS'
    END AS INTEGRITY_FLAG,
    CURRENT_TIMESTAMP() AS LOAD_TS
  FROM
    final_calculations AS final_calcs;

EXCEPTION WHEN ERROR THEN
  -- Error Handling: Logs exceptions to a dedicated error table.
  INSERT INTO `Maint_Error_Log` (error_message, load_ts)
  VALUES (@@error.message, CURRENT_TIMESTAMP());

END;