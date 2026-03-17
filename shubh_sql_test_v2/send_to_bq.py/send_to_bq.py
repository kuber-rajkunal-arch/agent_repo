from google.cloud import bigquery
 
def upload_to_bigquery(csv_file_path, project_id, dataset_id, table_id):
    client = bigquery.Client(project=project_id)
    dataset_ref = client.dataset(dataset_id)
    table_ref = dataset_ref.table(table_id)

    # Create a job configuration for CSV data load
    job_config = bigquery.LoadJobConfig(source_format=bigquery.SourceFormat.CSV)
    # write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE

    # Start the data load job
    with open(csv_file_path, 'rb') as file:
        job = client.load_table_from_file(file, table_ref, job_config=job_config)
    
    # Wait for the job to complete
    job.result()

    print(f'Data loaded to BigQuery table {project_id}.{dataset_id}.{table_id}')

def upload_process_log():
    project_id = 'mg-accelerator'
    csv_file_path = '/home/genai-usecase-team/backend/process_log.csv'
    dataset_id = 'mg_dataset'
    table_id = 'process_log'
    upload_to_bigquery(csv_file_path, project_id, dataset_id, table_id)
