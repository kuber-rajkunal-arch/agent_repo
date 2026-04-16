-- Copyright 2023 Google LLC
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

/*
* Test script for function: grade_assignment.calculate_student_grade
*
* This script validates the correctness of the grade calculation logic,
* including boundary conditions and error handling, as specified in
* TRD-GRD-001.
*/

-- Test Suite: Grade A (>= 90)
ASSERT grade_assignment.calculate_student_grade(100) = 'Grade A' AS 'Test Failed: Grade A for score 100';
ASSERT grade_assignment.calculate_student_grade(90) = 'Grade A' AS 'Test Failed: Grade A for boundary score 90';
ASSERT grade_assignment.calculate_student_grade(95.5) = 'Grade A' AS 'Test Failed: Grade A for score 95.5';

-- Test Suite: Grade B (>= 75 and < 90)
ASSERT grade_assignment.calculate_student_grade(89.99) = 'Grade B' AS 'Test Failed: Grade B for boundary score 89.99';
ASSERT grade_assignment.calculate_student_grade(75) = 'Grade B' AS 'Test Failed: Grade B for boundary score 75';
ASSERT grade_assignment.calculate_student_grade(82) = 'Grade B' AS 'Test Failed: Grade B for score 82';

-- Test Suite: Grade C (>= 50 and < 75)
ASSERT grade_assignment.calculate_student_grade(74.99) = 'Grade C' AS 'Test Failed: Grade C for boundary score 74.99';
ASSERT grade_assignment.calculate_student_grade(50) = 'Grade C' AS 'Test Failed: Grade C for boundary score 50';
ASSERT grade_assignment.calculate_student_grade(63.7) = 'Grade C' AS 'Test Failed: Grade C for score 63.7';

-- Test Suite: Fail (< 50)
ASSERT grade_assignment.calculate_student_grade(49.99) = 'Fail' AS 'Test Failed: Fail for boundary score 49.99';
ASSERT grade_assignment.calculate_student_grade(0) = 'Fail' AS 'Test Failed: Fail for boundary score 0';
ASSERT grade_assignment.calculate_student_grade(25) = 'Fail' AS 'Test Failed: Fail for score 25';

-- Test Suite: Error Handling for Invalid Input (Range Check)
BEGIN
  SELECT grade_assignment.calculate_student_grade(-1);
  ASSERT FALSE AS 'Test Failed: Negative input did not raise an error.';
EXCEPTION WHEN ERROR THEN
  ASSERT TRUE;
END;

BEGIN
  SELECT grade_assignment.calculate_student_grade(-100.5);
  ASSERT FALSE AS 'Test Failed: Negative decimal input did not raise an error.';
EXCEPTION WHEN ERROR THEN
  ASSERT TRUE;
END;

-- Test Suite: Error Handling for Invalid Input (NULL Check)
BEGIN
  SELECT grade_assignment.calculate_student_grade(NULL);
  ASSERT FALSE AS 'Test Failed: NULL input did not raise an error.';
EXCEPTION WHEN ERROR THEN
  ASSERT TRUE;
END;