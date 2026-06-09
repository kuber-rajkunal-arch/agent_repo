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

-- Unit tests for the Curated.quote table.
-- These tests verify data integrity constraints after the MERGE operation.

-- test: not_null_quote_id
-- The primary key of the quote table must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_id' AS test_name
FROM
  `Curated.quote`
WHERE
  quote_id IS NULL;

-- test: unique_quote_id
-- The primary key of the quote table must be unique.
SELECT
  IF(COUNT(quote_id) = COUNT(DISTINCT quote_id), 'PASS', 'FAIL') AS result,
  'unique_quote_id' AS test_name
FROM
  `Curated.quote`;

-- test: referential_integrity_opportunity_id
-- If a quote is associated with an opportunity, that opportunity_id must exist in the opportunity table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_opportunity_id' AS test_name
FROM
  `Curated.quote` AS q
LEFT JOIN
  `Curated.opportunity` AS o
  ON q.opportunity_id = o.opportunity_id
WHERE
  q.opportunity_id IS NOT NULL AND o.opportunity_id IS NULL;

-- test: referential_integrity_customer_id
-- If a quote is associated with a customer, that customer_id must exist in the customer table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_customer_id' AS test_name
FROM
  `Curated.quote` AS q
LEFT JOIN
  `Curated.customer` AS c
  ON q.customer_id = c.customer_id
WHERE
  q.customer_id IS NOT NULL AND c.customer_id IS NULL;

-- test: non_negative_total_amount
-- The total amount of a quote must not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'non_negative_total_amount' AS test_name
FROM
  `Curated.quote`
WHERE
  total_amount < 0;

-- test: valid_date_range
-- The valid_to date for a quote must be on or after the valid_from date.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'valid_date_range' AS test_name
FROM
  `Curated.quote`
WHERE
  valid_to < valid_from;
