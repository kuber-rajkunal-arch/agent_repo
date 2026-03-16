
Create or replace  table  gcp-cloud-source-repo.agent_test.orders_sdlc_test_2
AS 
Select * from gcp-cloud-source-repo.agent_test.orders LIMIT 100; 

 
DELETE FROM gcp-cloud-source-repo.agent_test.orders_sdlc_test_2
Where 
order_id IN ('13638'   ,'9484');



