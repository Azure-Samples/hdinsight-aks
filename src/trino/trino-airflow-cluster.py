import json
import msal
from airflow import DAG, settings
from airflow.models import Connection
from airflow.operators.python_operator import PythonOperator
from airflow.providers.trino.operators.trino import TrinoOperator
from datetime import datetime
from airflow.exceptions import AirflowFailException

connect_id="_trino_test_connection"

#
# Update with your HDInsight on AKS Trino cluster details.
#
scopes= [ "https://clusteraccess.hdinsightaks.net/.default" ]
authority= "https://login.microsoftonline.com/<azure_tenant_id>"
client_id= "<service_principal_client_id>"
secret= "<service_principal_secret>"
trino_endpoint="<trino_cluster_endpoint>"

#
# Get access token from Azure AD
#
def get_token(authority, scopes, client_id, secret):
    result=None
    app = msal.ConfidentialClientApplication(
        client_id, 
        authority=authority,
        client_credential=secret)

    result = app.acquire_token_silent(scopes, account=None)
    if not result:
        result = app.acquire_token_for_client(scopes=scopes)

    if "access_token" in result:
        return result['access_token']
    else:
        print(result.get("error"))
        print(result.get("error_description"))
        print(result.get("correlation_id"))
        return None

#
# Create an Airflow connection to Trino using JWT auth
# This connection and secrets management is not suitable for producation, serves as an example only.
#
def trino_connect(ds, **kwargs):    
    session = settings.Session()
    if not (session.query(Connection).filter(Connection.conn_id == connect_id).first()):
        new_conn = Connection(
            conn_id=connect_id,
            conn_type='trino',
            host=trino_endpoint,
            port=443
        )

        access_token=get_token(authority, scopes, client_id, secret)
        conn_extra = {
            "protocol": "https",
            "auth": "jwt",
            "jwt__token": access_token
        }
        conn_extra_json = json.dumps(conn_extra)
        new_conn.set_extra(conn_extra_json)        

        session.add(new_conn)
        session.commit()
    else:
        raise AirflowFailException("Connection {conn_id} already exists.".format(conn_id=connect_id))

#
# Print task result and cleanup
#
def print_data(**kwargs):
    task_instance = kwargs['task_instance']
    print('Return Value: ',task_instance.xcom_pull(task_ids='trino_query',key='return_value'))

    session = settings.Session()
    connection = session.query(Connection).filter_by(conn_id=connect_id).one_or_none()
    if connection is None:
        print("Nothing to cleanup")
    else:
        session.delete(connection)
        session.commit()
        print("Successfully deleted connection ", connect_id)

#
# DAG
#
with DAG(
    dag_id="example_trino",
    schedule="@once", 
    start_date=datetime(2023, 1, 1),
    catchup=False,
    tags=["example"],
) as dag:
    trino_connect = PythonOperator(
        dag=dag,
        task_id='trino_connect',
        python_callable=trino_connect,
        provide_context=True,
    )

    trino_query = TrinoOperator(
        task_id="trino_query",
        trino_conn_id=connect_id,
        sql="select * from tpch.tiny.orders limit 1",
        handler=list
    )

    print_result = PythonOperator(
        task_id = 'print_result',
        python_callable = print_data,
        provide_context = True,
        dag = dag)
    
    (
        trino_connect >> trino_query >> print_result
    )
