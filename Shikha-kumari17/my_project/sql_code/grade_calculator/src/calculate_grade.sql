--
-- Technical Requirement ID: TR-GRD-001
-- Objective: Implement a module to calculate and assign a letter grade.
--
-- This function calculates a letter grade (A, B, C, Fail) based on a student's
-- numerical marks using predefined thresholds. It is designed for enterprise-grade,
-- production-quality systems and adheres to standard SQL practices.
--
-- The implementation uses PL/pgSQL for robust error handling and logging capabilities.
--

CREATE OR REPLACE FUNCTION calculate_grade(p_marks NUMERIC)
RETURNS TEXT AS $$
DECLARE
    v_determined_grade TEXT;
BEGIN
    -- Input Validation: Validate that the received input is not NULL.
    -- The function's NUMERIC parameter type implicitly handles errors for non-numerical strings,
    -- as the database engine will raise a type conversion error.
    IF p_marks IS NULL THEN
        RAISE LOG 'Input validation failed: student marks cannot be NULL. TR-GRD-001.';
        RETURN NULL; -- Return NULL to signify invalid/unknown status.
    END IF;

    -- Logging: Log the input numerical marks for traceability.
    RAISE LOG 'Processing TR-GRD-001: Received input marks: %', p_marks;

    -- Business Logic: Assigns a letter grade based on the numerical value of student marks.
    -- Transformation Logic from TRD Section 8.
    CASE
        WHEN p_marks >= 90 THEN
            v_determined_grade := 'Grade A';
        WHEN p_marks >= 75 THEN
            v_determined_grade := 'Grade B';
        WHEN p_marks >= 50 THEN
            v_determined_grade := 'Grade C';
        ELSE
            v_determined_grade := 'Fail';
    END CASE;

    -- Logging: Log the determined grade after processing.
    RAISE LOG 'Processing TR-GRD-001: Determined grade is "%" for marks: %', v_determined_grade, p_marks;

    RETURN v_determined_grade;

EXCEPTION
    -- Error Handling: Log any other exceptions encountered during the process.
    WHEN others THEN
        RAISE LOG 'Error during grade determination for input "%". SQLSTATE: %, MESSAGE: %', p_marks, SQLSTATE, SQLERRM;
        -- Re-raise the exception to ensure the calling context is aware of the failure.
        RAISE;
END;
$$ LANGUAGE plpgsql
IMMUTABLE;