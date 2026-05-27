BEGIN
  -- This script processes raw flight and maintenance data, calculates risk scores and
  -- operational statuses, and loads the enriched data into the FlightDeepMaintenanceFact table.
  -- The logic is derived from the oracle_plsql_v4_full mapping document and is implemented
  -- as a single, set-based INSERT...SELECT statement for BigQuery.

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
    -- Joins flight and maintenance records, extracts JSON data, and calculates avg temp per aircraft.
    c_complex_extract_inner AS (
      SELECT
        f.FLIGHT_ID,
        f.AIRCRAFT_ID,
        f.ENGINE_TEMP,
        f.FATIGUE_INDEX,
        CAST(JSON_EXTRACT_SCALAR(f.TELEMETRY_JSON, '$.engine.vibration') AS NUMERIC) AS vib,
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

    -- SECTION 2 -- c_complex_extract (Wrapper)
    -- Calculates the vibration Z-score and maintenance duration in days.
    c_complex_extract_wrapper AS (
      SELECT
        FLIGHT_ID,
        AIRCRAFT_ID,
        MAINT_EVENT_ID,
        ENGINE_TEMP,
        FATIGUE_INDEX,
        vib,
        -- Standard Z-score calculation for engine vibration.
        (vib - AVG(vib) OVER (PARTITION BY AIRCRAFT_ID)) / NULLIF(STDDEV(vib) OVER (PARTITION BY AIRCRAFT_ID), 0) AS vib_z_score,
        -- Calculate the duration of the maintenance event in days.
        TIMESTAMP_DIFF(EVENT_END_TS, EVENT_START_TS, DAY) AS day_delta
      FROM
        c_complex_extract_inner
    ),

    -- Staging CTE to calculate intermediate values before the final select.
    final_staging AS (
      SELECT
        FLIGHT_ID,
        AIRCRAFT_ID,
        MAINT_EVENT_ID,
        vib_z_score,
        -- Inlined logic from the calculate_safety_index PL/SQL function.
        (ENGINE_TEMP * 0.4) + (FATIGUE_INDEX * 100 * 0.4) + (vib * 0.2) AS RISK_SCORE,
        -- Derives a data quality flag based on the calculated maintenance duration.
        CASE
          WHEN day_delta < 0 THEN 'ERR_NEG'
          ELSE 'PASS'
        END AS INTEGRITY_FLAG
      FROM c_complex_extract_wrapper
    )

  -- Final Output Section
  -- Selects and transforms data for insertion into the fact table.
  SELECT
    FLIGHT_ID,
    AIRCRAFT_ID,
    MAINT_EVENT_ID,
    -- Determine operational status based on risk score and vibration anomalies.
    CASE
      WHEN RISK_SCORE > 80 THEN 'CRITICAL_AOG_REQUIRED'
      WHEN vib_z_score > 2 THEN 'VIBRATION_ANOMALY_DETECTED'
      ELSE 'STABLE'
    END AS OP_STATUS,
    RISK_SCORE,
    vib_z_score AS VIB_Z_SCORE,
    INTEGRITY_FLAG,
    -- Populate with the current timestamp at load time.
    CURRENT_TIMESTAMP() AS LOAD_TS
  FROM
    final_staging;

EXCEPTION WHEN ERROR THEN
  -- Generic error handler to log failures to an error table.
  INSERT INTO `Maint_Error_Log` (error_message, load_ts)
  VALUES (@@error.message, CURRENT_TIMESTAMP());

END;