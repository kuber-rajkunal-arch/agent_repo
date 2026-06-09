-- Copyright 2023 Google LLC
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may ontain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- Unit tests for the Curated.customer table.
-- These tests verify data integrity constraints after the MERGE operation.

-- test: not_null_customer_id
-- The primary key of the customer table must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_customer_id' AS test_name
FROM
  `Curated.customer`
WHERE
  customer_id IS NULL;

-- test: unique_customer_id
-- The primary key of the customer table must be unique.
SELECT
  IF(
    COUNT(customer_id) = COUNT(DISTINCT customer_id),
    'PASS',
    'FAIL'
  ) AS result,
  'unique_customer_id' AS test_name
FROM
  `Curated.customer`;

-- test: not_null_created_on
-- The created_on timestamp should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_created_on' AS test_name
FROM
  `Curated.customer`
WHERE
  created_on IS NULL;

-- test: not_null_is_active
-- The is_active flag should always be populated (TRUE or FALSE).
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_is_active' AS test_name
FROM
  `Curated.customer`
WHERE
  is_active IS NULL;
