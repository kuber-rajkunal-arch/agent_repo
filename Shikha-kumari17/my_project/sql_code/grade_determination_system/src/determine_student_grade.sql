-- =============================================================================
-- File:         determine_student_grade.sql
-- Project:      Grade Determination System
-- Author:       Senior Software Engineer
-- Created:      2023-10-27
--
-- Description:  This file contains the SQL User-Defined Function (UDF) for
--               determining a student's letter grade based on their numerical
--               marks, as per TR-GRD-001. The function is implemented in
--               PL/pgSQL for PostgreSQL.
--
-- Usage:
--               SELECT public.determine_student_grade('85.5');
--               -- Expected output: 'Grade B'
--
--               SELECT public.determine_student_grade('ninety');
--               -- Expected output: 'Error: Invalid input. Not a valid numerical value.'
--
-- =============================================================================

CREATE OR REPLACE FUNCTION public.determine_student_grade(
    p_student_marks TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
STABLE -- Function does not modify the database and returns same results for same inputs.
AS $$
-- =============================================================================
-- Function:     determine_student_grade
--
-- Description:  Implements the business logic to assign a letter grade based
--               on numerical marks. It includes input validation and logging
--               as specified in TR-GRD-001.
--
-- Parameters:
--   p_student_marks (TEXT): The student's marks as a text string to allow for
--                           explicit validation.
--
-- Returns:
--   (TEXT): The calculated letter grade ('Grade A', 'Grade B', 'Grade C', 'Fail')
--           or an error message if the input is invalid.
-- =============================================================================
DECLARE
    v_marks_numeric NUMERIC;
    v_determined_grade TEXT;
BEGIN
    -- Stage 1: Receive Student Marks & Log Input
    -- The input p_student_marks is received as a parameter.
    RAISE LOG '[TR-GRD-001] Received input for grade determination: %', p_student_marks;

    -- Validate that the input is a valid numerical value.
    -- This is done by attempting a type cast within an exception block.
    BEGIN
        v_marks_numeric := p_student_marks::NUMERIC;
    EXCEPTION
        WHEN others THEN
            -- Error Handling: Log the error and the erroneous value.
            RAISE LOG '[TR-GRD-001] ERROR: Invalid input. Value ''%'' is not a valid numerical value.', p_student_marks;
            -- Prevent grade determination and return an error message.
            RETURN 'Error: Invalid input. Not a valid numerical value.';
    END;

    -- Stage 2: Determine Grade (Transformation Logic)
    -- Evaluate the numerical marks against predefined thresholds.
    CASE
        WHEN v_marks_numeric >= 90 THEN
            v_determined_grade := 'Grade A';
        WHEN v_marks_numeric >= 75 THEN
            v_determined_grade := 'Grade B';
        WHEN v_marks_numeric >= 50 THEN
            v_determined_grade := 'Grade C';
        ELSE
            v_determined_grade := 'Fail';
    END CASE;

    -- Logging: Log the determined letter grade upon successful assignment.
    RAISE LOG '[TR-GRD-001] Successfully determined grade for marks %: %', v_marks_numeric, v_determined_grade;

    -- Stage 3: Output Determined Grade
    RETURN v_determined_grade;

END;
$$;