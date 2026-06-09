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

-- Unit tests for the Curated.quote_detail table.
-- These tests verify data integrity constraints after the MERGE operation.

-- test: not_null_quote_detail_id
-- The primary key of the quote_detail table must not be null.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_detail_id' AS test_name
FROM
  `Curated.quote_detail`
WHERE
  quote_detail_id IS NULL;

-- test: unique_quote_detail_id
-- The primary key of the quote_detail table must be unique.
SELECT
  IF(
    COUNT(quote_detail_id) = COUNT(DISTINCT quote_detail_id),
    'PASS',
    'FAIL'
  ) AS result,
  'unique_quote_detail_id' AS test_name
FROM
  `Curated.quote_detail`;

-- test: not_null_quote_id
-- The foreign key to the quote table must not be null, as a detail line cannot exist without a header.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'not_null_quote_id' AS test_name
FROM
  `Curated.quote_detail`
WHERE
  quote_id IS NULL;

-- test: referential_integrity_quote_id
-- Every quote_detail must be associated with a valid quote_id that exists in the quote table.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'referential_integrity_quote_id' AS test_name
FROM
  `Curated.quote_detail` AS qd
LEFT JOIN
  `Curated.quote` AS q
  ON qd.quote_id = q.quote_id
WHERE
  qd.quote_id IS NOT NULL AND q.quote_id IS NULL;

-- test: non_negative_quantity
-- The quantity of a product on a quote line must not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'non_negative_quantity' AS test_name
FROM
  `Curated.quote_detail`
WHERE
  quantity < 0;

-- test: non_negative_unit_price
-- The unit price of a product on a quote line must not be negative.
SELECT
  IF(COUNT(*) = 0, 'PASS', 'FAIL') AS result,
  'non_negative_unit_price' AS test_name
FROM
  `Curated.quote_detail`
WHERE
  unit_price < 0;
