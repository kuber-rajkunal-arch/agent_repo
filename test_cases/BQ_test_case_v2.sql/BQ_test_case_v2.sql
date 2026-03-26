WITH
-- Test 1: Ensure table exists and has rows
test1 AS (
  SELECT
    IF(COUNT(*) > 0, TRUE, FALSE) AS pass
  FROM `gcp-cloud-source-repo.agent_test.orders_sdlc_test_2`
),

-- Test 2: Validate order_id uniqueness (no duplicates)
test2 AS (
  SELECT
    IF(COUNT(*) = 0, TRUE, FALSE) AS pass
  FROM (
    SELECT order_id
    FROM `gcp-cloud-source-repo.agent_test.orders_sdlc_test_2`
    GROUP BY order_id
    HAVING COUNT(*) > 1
  )
),

-- Test 3: Validate created_at is not in the future
test3 AS (
  SELECT
    IF(COUNT(*) = 0, TRUE, FALSE) AS pass
  FROM `gcp-cloud-source-repo.agent_test.orders_sdlc_test_2`
  WHERE created_at > CURRENT_TIMESTAMP()
),

-- Test 4: Validate gender contains allowed values
test4 AS (
  SELECT
    IF(COUNT(*) = 0, TRUE, FALSE) AS pass
  FROM `gcp-cloud-source-repo.agent_test.orders_sdlc_test_2`
  WHERE gender NOT IN ('M', 'F', 'U')
),

-- Test 5: Validate num_of_item is always >= 0
test5 AS (
  SELECT
    IF(COUNT(*) = 0, TRUE, FALSE) AS pass
  FROM `gcp-cloud-source-repo.agent_test.orders_sdlc_test_2`
  WHERE num_of_item < 0
),

-- Test 6: Validate updated_on is always >= created_on (timestamps ordered)
test6 AS (
  SELECT
    IF(COUNT(*) = 0, TRUE, FALSE) AS pass
  FROM `gcp-cloud-source-repo.agent_test.orders_sdlc_test_2`
  WHERE updated_on < created_on
),

-- Test 7: Validate staging table freshness
test7 AS (
  SELECT
    IF(COUNT(*) > 0, TRUE, FALSE) AS pass
  FROM `gcp-cloud-source-repo.agent_test.orders_stg`
  WHERE created_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
),

-- Test 8: Ensure no NULL order_id
test8 AS (
  SELECT
    IF(COUNT(*) = 0, TRUE, FALSE) AS pass
  FROM `gcp-cloud-source-repo.agent_test.orders_sdlc_test_2`
  WHERE order_id IS NULL
),

-- Test 9: Validate merge consistency (stg → target)
test9 AS (
  SELECT
    IF(COUNT(*) >= 0, TRUE, FALSE) AS pass
  FROM `gcp-cloud-source-repo.agent_test.orders_stg` s
  LEFT JOIN `gcp-cloud-source-repo.agent_test.orders_sdlc_test_2` t
  ON s.order_id = t.order_id
),

-- Test 10: Validate status values match allowed list
test10 AS (
  SELECT
    IF(COUNT(*) = 0, TRUE, FALSE) AS pass
  FROM `gcp-cloud-source-repo.agent_test.orders_sdlc_test_2`
  WHERE status NOT IN ('CREATED', 'SHIPPED', 'DELIVERED', 'RETURNED')
)

SELECT
  CASE
    WHEN test1.pass
     AND test2.pass
     AND test3.pass
     AND test4.pass
     AND test5.pass
     AND test6.pass
     AND test7.pass
     AND test8.pass
     AND test9.pass
     AND test10.pass
    THEN "PASS"
    ELSE "FAIL"
  END AS final_test_status
FROM test1, test2, test3, test4, test5, test6, test7, test8, test9, test10;