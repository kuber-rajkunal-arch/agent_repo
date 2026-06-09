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

-- Unit tests for the Curated.opportunity table.
-- These tests verify data integrity constraints after the MERGE operation.

-- test: not_null_opportunity_id
-- The primary key of the opportunity table must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_opportunity_id' AS test_name
FROM
  `Curated.opportunity`
WHERE
  opportunity_id IS NULL;

-- test: unique_opportunity_id
-- The primary key of the opportunity table must be unique.
SELECT
  IF(
    COUNT(opportunity_id) = COUNT(DISTINCT opportunity_id),
    'PASS',
    'FAIL'
  ) AS result,
  'unique_opportunity_id' AS test_name
FROM
  `Curated.opportunity`;

-- test: referential_integrity_customer_id
-- If an opportunity is associated with a customer, that customer_id must exist in the customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customer_id' AS test_name
FROM
  `Curated.opportunity` AS o
LEFT JOIN
  `Curated.customer` AS c
  ON o.customer_id = c.customer_id
WHERE
  o.customer_id IS NOT NULL AND c.customer_id IS NULL;

-- test: referential_integrity_originating_lead_id
-- If an opportunity has an originating lead, that lead_id must exist in the lead table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_originating_lead_id' AS test_name
FROM
  `Curated.opportunity` AS o
LEFT JOIN
  `Curated.lead` AS l
  ON o.originating_lead_id = l.lead_id
WHERE
  o.originating_lead_id IS NOT NULL AND l.lead_id IS NULL;

-- test: range_check_probability
-- The probability of an opportunity should be between 0 and 1, inclusive.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'range_check_probability' AS test_name
FROM
  `Curated.opportunity`
WHERE
  probability < 0 OR probability > 1;

-- test: non_negative_estimated_value
-- The estimated value of an opportunity must not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'non_negative_estimated_value' AS test_name
FROM
  `Curated.opportunity`
WHERE
  estimated_value < 0;
