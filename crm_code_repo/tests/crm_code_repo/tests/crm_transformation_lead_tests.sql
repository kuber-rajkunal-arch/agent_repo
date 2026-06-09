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

-- Unit tests for the Curated.lead table.
-- These tests verify data integrity constraints after the MERGE operation.

-- test: not_null_lead_id
-- The primary key of the lead table must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_lead_id' AS test_name
FROM
  `Curated.lead`
WHERE
  lead_id IS NULL;

-- test: unique_lead_id
-- The primary key of the lead table must be unique.
SELECT
  IF(COUNT(lead_id) = COUNT(DISTINCT lead_id), 'PASS', 'FAIL') AS result,
  'unique_lead_id' AS test_name
FROM
  `Curated.lead`;

-- test: not_null_created_on
-- The created_on timestamp should always be populated.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_created_on' AS test_name
FROM
  `Curated.lead`
WHERE
  created_on IS NULL;

-- test: referential_integrity_customer_id
-- If a lead is associated with a customer, that customer_id must exist in the customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customer_id' AS test_name
FROM
  `Curated.lead` AS l
LEFT JOIN
  `Curated.customer` AS c
  ON l.customer_id = c.customer_id
WHERE
  l.customer_id IS NOT NULL AND c.customer_id IS NULL;
