import logging
from datetime import datetime

import requests
from airflow import AirflowException
from airflow import DAG
from airflow.models import Variable
from airflow.operators.python_operator import PythonOperator
from azure.identity import ClientSecretCredential


def submit_spark_job(**kwargs):
    """submit Spark job using Livy REST API"""
    client_id = Variable.get("api-client-id")
    api_secret = Variable.get("api-secret")
    tenant_id = Variable.get("tenant-id")
    client_credential = ClientSecretCredential(
        tenant_id=tenant_id, client_id=client_id, client_secret=api_secret)
    access_token = client_credential.get_token(
        "https://hilo.azurehdinsight.net/.default")
    if access_token is None:
        raise ValueError(
            "not able to retrieve OAuth token, please validate your environment and Azure service principal")
    else:
        cluster_dns = conf["spark_cluster_fqdn"]
        livy_job_url = "https://" + cluster_dns + "/p/livy/batches"
        request_payload = {"className": "org.apache.spark.examples.SparkPi",
                    "args": [10],
                    "name": conf["job_name"],
                    "file": conf["app_jar_path"]
                    }
        headers = {
        'Authorization': f'Bearer {access_token.token}'
        }
        try:
            response = requests.post(livy_job_url, json=request_payload, headers=headers)
            logging.info("response:",response.json())
        except requests.exceptions.RequestException as exception:
            logging.warning(exception)
            raise AirflowException from exception

with DAG(
        "SparkWordCountExample",
        default_args={
            "depends_on_past": False,
            "retries": 0
        },
        description="Submit Spark WordCount Job",
        start_date=datetime(2021, 1, 1),
        catchup=False,
        tags=["HDInsight on AKS example"],
) as dag:
    submit_flink_example_job = PythonOperator(
        task_id="submit_spark_example_job",
        python_callable=submit_spark_job,
        provide_context=True
    )
