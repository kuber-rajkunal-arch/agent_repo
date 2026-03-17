
Create or replace  table  gcp-cloud-source-repo.agent_test.orders_sdlc_test
AS 
Select * from gcp-cloud-source-repo.agent_test.orders LIMIT 100; 

 
DELETE FROM gcp-cloud-source-repo.agent_test.orders_sdlc_test
Where 
order_id IN ('13638' ,'3557' ,'9484');

