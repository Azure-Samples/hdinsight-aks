"""
Example uses service principal to authorize for the cluster access (https://learn.microsoft.com/en-us/azure/hdinsight-aks/hdinsight-on-aks-manage-authorization-profile#how-to-grant-access). 
It would require following variables setup in Airflow:

- api-client-id - Client id of service principal 
- api-secret - Secret of service principal 
- tenant-id - Tenant Id of service principal 
- app_jar_path - Complete path of file containing the application to execute (accessible from the cluster)
- job_name - Job Name
- className - Application Java/Spark main class
- spark_cluster_fqdn - cluster FQDN (for example demospark.63784884848.eastus2.hdinsightaks.net)

You can enable Azure Managed Airflow to use Key vault to get service principal detail.
(https://learn.microsoft.com/en-us/azure/data-factory/enable-azure-key-vault-for-managed-airflow)

The example covers the following scenario using using Apache Livy API. 

1. Orchestrate Airflow DAG for Spark job submission
2. Periodically checking job status 
3. and Getting driver log

"""
import json
import logging
from datetime import datetime

import requests
from airflow import AirflowException
from airflow import DAG
from airflow.contrib.sensors.python_sensor import PythonSensor
from airflow.models import Variable
from airflow.operators.python_operator import PythonOperator
from azure.identity import ClientSecretCredential

# get service principal details from Variables
# for more secure way you can use Airflow backend with Azure Key Vault as well
client_id = Variable.get("api-client-id")
api_secret = Variable.get("api-secret")
tenant_id = Variable.get("tenant-id")
# cluster DNS from Variable
cluster_dns = Variable.get("spark_cluster_fqdn")
# list of job status when we should consider it is completed (successful or failed)
job_status = ['dead', 'killed', 'success', 'error']


def _get_oauth_token():
    # get OAuth Token
    client_credential = ClientSecretCredential(
        tenant_id=tenant_id, client_id=client_id, client_secret=api_secret)
    access_token = client_credential.get_token(
        "https://hilo.azurehdinsight.net/.default")
    return access_token


def submit_spark_job(**kwargs):
    """submit Spark job using Livy REST API"""
    ti = kwargs['ti']
    access_token = _get_oauth_token()
    if access_token is None:
        raise ValueError(
            "not able to retrieve OAuth token, please validate your environment and Azure service principal")
    else:
        livy_job_end_point = "https://" + cluster_dns + "/p/livy/batches"
        request_payload = {"className": Variable.get("className"),
                           "args": [10],
                           "name": Variable.get("job_name"),
                           "file": Variable.get("app_jar_path")
                           }
        headers = {
            'Authorization': f'Bearer {access_token.token}'
        }
        try:
            response = requests.post(livy_job_end_point, json=request_payload, headers=headers)
            parsed_response = json.loads(response.text)
            ti.xcom_push(key="job_response_code", value=response.status_code)
            ti.xcom_push(key="session_id", value=parsed_response.get("id"))
            logging.info(response.status_code)
            logging.info(json.dumps(parsed_response, indent=4))
        except requests.exceptions.RequestException as exception:
            logging.warning(exception)
            raise AirflowException from exception


def check_job_status(**kwargs):
    """check job status using Livy Session ID"""
    ti = kwargs['ti']
    job_status_code = ti.xcom_pull(key="job_response_code")
    logging.info("checking job status %s", str(job_status_code))
    try:
        if job_status_code == 201:  # if job created successfully
            # get OAuth Token
            access_token = _get_oauth_token()
            if access_token is None:
                raise ValueError(
                    "not able to retrieve OAuth token, please validate your environment and Azure service principal")
            else:
                session_id = ti.xcom_pull(key="session_id")
                livy_session_status_end_point = f"https://{cluster_dns}/p/livy/batches/{session_id}/state"
                headers = {
                    'Authorization': f'Bearer {access_token.token}'
                }
                response = requests.get(livy_session_status_end_point, headers=headers)
                parsed_response = json.loads(response.text)
                logging.info("job status response: %s", parsed_response)
                # check session state
                if parsed_response.get("state") in job_status:
                    # pass session id to next step
                    ti.xcom_push(key="session_id", value=session_id)
                    return True
                else:
                    # pass them back for the next iteration
                    ti.xcom_push(key="job_response_code", value=job_status_code)
                    ti.xcom_push(key="session_id", value=session_id)
                    return False
        else:
            return True
    except Exception as exception:
        logging.warning(exception)
        raise AirflowException from exception


def get_driver_log(**kwargs):
    """get driver log for the submitted job"""
    ti = kwargs['ti']
    session_id = ti.xcom_pull(key="session_id")
    try:
        if session_id is not None:
            # get OAuth Token
            logging.info("getting driver log")
            access_token = _get_oauth_token()
            if access_token is None:
                raise ValueError(
                    "not able to retrieve OAuth token, please validate your environment and Azure service principal")
            else:
                driver_log_end_point = f"https://{cluster_dns}/p/livy/batches/{session_id}/log"
                headers = {
                    'Authorization': f'Bearer {access_token.token}'
                }
                response = requests.get(driver_log_end_point, headers=headers)
                parsed_response = json.loads(response.text)
                log_list = parsed_response.get('log')
                logging.info("************************************* Driver Log ************************************")
                [print(log_line) for log_line in log_list]
        else:
            return True
    except Exception as exception:
        logging.warning(exception)
        raise AirflowException from exception


with DAG(
        "SparkPi",
        default_args={
            "depends_on_past": False,
            "retries": 0
        },
        description="Submit Spark WordCount Job",
        start_date=datetime(2021, 1, 1),
        catchup=False,
        tags=["HDInsight on AKS example"],
) as dag:
    submit_job = PythonOperator(
        task_id="submit_spark_example_job",
        python_callable=submit_spark_job,
        provide_context=True
    )
    wait_for_completion = PythonSensor(
        task_id='wait_for_job_completion',
        python_callable=check_job_status,
        mode='reschedule',
        poke_interval=20
    )
    driver_log = PythonOperator(
        task_id="job_driver_log",
        python_callable=get_driver_log,
        provide_context=True
    )
    submit_job >> wait_for_completion >> driver_log
