## This blog is to efficiently integrate customer data from Microsoft Dataverse, processes it using Flink, enriches it with LinkedIn insights via LangChain, leverages OpenAI for additional processing, and finally visualizes the enriched customer leads in Power BI for effective business decision-making. This end-to-end automation enhances lead generation and customer relationship management.

Below is the architecture:<br>

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/a0a86e62-8aba-43c3-9544-3e2258399e0c)


Here’s a summary for the workflow: <br>
**Microsoft Dataverse:** This is the starting point of the workflow. It’s connected to a “Sales/contacts table” which feeds into the workflow.<br>
**Azure Eventhub:** store layer.<br>
**Flink:** The data from the “Dataverse: contacts Topic” is processed in Flink SQL and then sent to "Dataverse: myleads Topic (Cold Calling).”<br>
**LangChain:** An LangChain agent uses LangChain and Proxycurl for scraping LinkedIn Profile data. The process of extracting LinkedIn profiles and summaries is depicted, leading to "Azure Event Hub Dataverse: myleads Topic (Ice-Breaker generation)."
**OpenAI:** The data flows into OpenAI for further processing.<br>
**Power BI:** Power BI is involved in calling an APP and generating calling list reports.<br>

## Prerequisites
. Apache Flink 1.17.0 Cluster on HDInsight on AKS <br>
. Azure Eventhub <br>
. Microsoft Dataverse and Dynamics 365 Sales

## Dynamics 365 and Dataverse

Dataverse lets you securely store and manage data that's used by business applications. Data within Dataverse is stored within a set of tables. 

#Ref <br>
https://learn.microsoft.com/en-us/power-apps/maker/data-platform/data-platform-intro

Dynamics 365 Sales, is a part of the Microsoft Dynamics 365 suite of business applications, it enables salespeople to build strong relationships with their customers, take actions based on insights, and close deals faster. Use Dynamics 365 Sales to keep track of your accounts and contacts, nurture your sales from lead to order, and create sales collateral. 

#Ref <br>
https://learn.microsoft.com/en-us/dynamics365/sales/overview

## Apache Flink® in Azure HDInsight on AKS

Apache Flink clusters in HDInsight on AKS are a fully managed service. <br>
See more about [Apache Flink clusters in HDInsight on AKS](https://learn.microsoft.com/en-us/azure/hdinsight-aks/flink/flink-overview)

## Azure Eventhub

Azure Event Hubs is a cloud native data streaming service that can stream millions of events per second, with low latency, from any source to any destination. Event Hubs is compatible with Apache Kafka, and it enables you to run existing Kafka workloads without any code changes.

#Ref <br>
https://learn.microsoft.com/en-us/azure/event-hubs/event-hubs-about

## LangChain
LangChain is a framework for developing applications powered by language models. 
This blog uses LangChain and Proxycurl for scraping data from LinkedIn using OpenAI (a popular model available via API) 

#Ref <br>
https://python.langchain.com/docs/get_started/introduction

## Implementation

### Creating Topic in Azure eventhub

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/b65d85c2-db10-4437-9d48-630d0d4a40d0)


### Creating a workflow in PowerAPP
In [PowerApp](https://make.preview.powerapps.com/), Creating a workflow in Microsoft Dataverse that’s designed to process changes in the Contacts table and then sink the data into Azure Event Hub. 

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/71f43296-ba4c-4a00-9ed5-f199a105de7a)

Do some changes on contact table <br>

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/8f54ae20-0e67-4e69-b617-745efdb01206)

### Check dataverse_contacts topic in Azure Eventhub

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/9422a015-172e-4499-9b93-531aa1e266dd)

### Process Flink SQL

Process dataverse_contacts topic and sink to dataverse_myleads topic in Azure Eventhub

on Webssh, Add jar: <br>
```
wget https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/3.2.0/kafka-clients-3.2.0.jar
wget https://repo1.maven.org/maven2/org/apache/flink/flink-connector-kafka/1.17.0/flink-connector-kafka-1.17.0.jar
```

Launch sql-client.sh to Flink SQL<br>
Note: you can do more complex transormation using Flink SQL API or Datastream API per your requirement, in this blog, I only concat contact first name, last name and company into a new column called information <br>
```
bin/sql-client.sh -j kafka-clients-3.2.0.jar -j flink-connector-kafka-1.17.0.jar
```

Example: <br>
Get eventhub connection string in Azure portal <br>
``` SQL
CREATE TABLE dataverse_contacts (
    `First Name` STRING,
    `Last Name` STRING,
    `Full Name` STRING,
    `Salutation` STRING,
    `Gendar` STRING,
    `Company Name` STRING,
    `Email` String
) WITH (
    'connector' = 'kafka',
    'topic' = 'dataverse_contacts',
    'properties.bootstrap.servers' = '<eventhubnamespace>.servicebus.windows.net:9093',
    'properties.group.id' = 'mygroup1',
    'format' = 'json',
    'scan.startup.mode' = 'earliest-offset',
    'properties.sasl.mechanism' = 'PLAIN',
    'properties.security.protocol' = 'SASL_SSL',
    'properties.sasl.jaas.config' = 'org.apache.kafka.common.security.plain.PlainLoginModule required username="$ConnectionString" password="Endpoint=sb://<eventhubnamespace>.servicebus.windows.net/;SharedAccessKeyName=<policy>;SharedAccessKey=<key>";'
);

select * from dataverse_contacts;

CREATE TABLE dataverse_myleads (
    `first_name` STRING,
    `last_name` STRING,
    `information` STRING,
    `Salutation` STRING,
    `Gendar` STRING,
    `Company Name` STRING,
    `Email` String,
    PRIMARY KEY (`Email`) NOT ENFORCED
) WITH (
  'connector' = 'upsert-kafka',
  'topic' = 'dataverse_myleads',
  'properties.bootstrap.servers' = '<eventhubnamespace>.servicebus.windows.net:9093',  'key.format' = 'json',
  'value.format' = 'json',
  'properties.sasl.mechanism' = 'PLAIN',
  'properties.security.protocol' = 'SASL_SSL',
  'properties.sasl.jaas.config' = 'org.apache.kafka.common.security.plain.PlainLoginModule required username="$ConnectionString" password="Endpoint=sb://<eventhubnamespace>.servicebus.windows.net/;SharedAccessKeyName=<policy>;SharedAccessKey=<key>";'
);

INSERT INTO dataverse_myleads
SELECT 
    `First Name`,
    `Last Name`,
    CONCAT(`First Name`, ' ', `Last Name`, ' ', `Company Name`) AS information,
    `Salutation`,
    `Gendar`,
    `Company Name`,
    `Email`
FROM dataverse_contacts;

select * from dataverse_myleads;
```

### Check dataverse_myleads topic in Azure Eventhub

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/fa2c824f-ee69-4622-bc00-46e000890ca5)

### LangChain agent to use LangChain and Proxycurl for scraping LinkedIn Profile data leverageing OpenAI to to do Ice-Breaker generation

Develop Python in Jypyter Notebook on Azure Windows Virtual Machine created in Azure portal <br>

Main package installed using pip:<br>
```
Package                   Version
------------------------- ---------------
aiohttp                   3.9.3
azure-core                1.30.0
azure-eventhub            5.11.6
azure-identity            1.15.0
json5                     0.9.17
jsonpatch                 1.33
jsonpointer               2.4
jsonschema                4.21.1
jsonschema-specifications 2023.12.1
jupyter                   1.0.0
jupyter_client            8.6.0
jupyter-console           6.6.3
jupyter_core              5.7.1
jupyter-events            0.9.0
jupyter-lsp               2.2.2
jupyter_server            2.12.5
jupyter_server_terminals  0.5.2
jupyterlab                4.1.2
jupyterlab_pygments       0.3.0
jupyterlab_server         2.25.3
jupyterlab_widgets        3.0.10
langchain                 0.1.8
langchain-community       0.0.21
langchain-core            0.1.25
langchain-experimental    0.0.52
langchain-openai          0.0.6
langsmith                 0.1.5
openai                    1.12.0
```

``` 
// Install the packages to send events
pip install azure-eventhub
pip install azure-identity
pip install aiohttp

// Install the packages to receive events
pip install azure-eventhub-checkpointstoreblob-aio
pip install azure-identity

// Install Langchain and openAI
pip install langchain_openai
pip install langchain
pip install google-search-results
```
**Get API keys**

We need a key which allow us to use OpenAI. Follow steps from [here](https://platform.openai.com/docs/quickstart/account-setup) to create an Account and then an API Key only.

Then create proxycurl api key. ProxyCurl will be used to scrape Linkedin. Sign Up to proxyurl and buy credits for 10$ (or whatever you think is enough, maybe you start more less) , [follow these Steps](https://nubela.co/proxycurl/). You get 10 free credit. Which could be enough for a simple demo.

To be able to search in Google the correct linkedin Profile URL, we need a API key of SERP API from [here](https://serpapi.com/)

#Code Ref <br>
https://learn.microsoft.com/en-us/azure/event-hubs/event-hubs-python-get-started-send?tabs=passwordless%2Croles-azure-portal
https://learn.microsoft.com/en-us/azure/event-hubs/event-hubs-kafka-flink-tutorial

**On Jupyter Notebook**

// set enviroment and API key <br>
``` python
import os
os.environ["OPENAI_API_KEY"] = '<OPENAI_API_KEY>'
os.environ["SERPAPI_API_KEY"] = '<SERPAPI_API_KEY>'
os.environ["PROXYCURL_API_KEY"] = '<PROXYCURL_API_KEY>'
os.environ["EVENT_HUB_CONN_STR1"] = '<Azure eventhub connectionstring from Azure portal>'
os.environ["EVENT_HUB_CONN_STR2"] = '<Azure eventhub connectionstring from Azure portal>'
os.environ["EVENT_HUB_NAME_MYLEADS"] = 'dataverse_myleads'
os.environ["EVENT_HUB_NAME_MYCALLS"] = 'dataverse_mycalls'
```

// Function: Get linkedin profile url based on lead info <br>
``` Python
import os
import requests

def scrape_linkedin_profile(linkedin_profile_url: str):
    """
    scrape information from LinkedIn profiles,
    Manually scrape the information from the LinkedIn profile
    """

    api_endpoint = "https://nubela.co/proxycurl/api/v2/linkedin"
    header_dic = {"Authorization": f'Bearer {os.environ.get("PROXYCURL_API_KEY")}'}

    response = requests.get(
        api_endpoint, params={"url": linkedin_profile_url}, headers=header_dic
    )

    data = response.json()
    data = {
        k: v
        for k, v in data.items()
        if v not in ([], "", "", None)
        and k not in ["people_also_viewed", "certifications"]
    }
    if data.get("groups"):
        for group_dict in data.get("groups"):
            group_dict.pop("profile_pic_url")

    return data
```

// Function: to get linkedIn profule url  <br>
``` python
from langchain_community.utilities import SerpAPIWrapper

class CustomSerpAPIWrapper(SerpAPIWrapper):
    def __init__(self):
        super(CustomSerpAPIWrapper, self).__init__()

    @staticmethod
    def _process_response(res: dict) -> str:
        """Process response from SerpAPI."""
        if "error" in res.keys():
            raise ValueError(f"Got error from SerpAPI: {res['error']}")
        if "answer_box" in res.keys() and "answer" in res["answer_box"].keys():
            toret = res["answer_box"]["answer"]
        elif "answer_box" in res.keys() and "snippet" in res["answer_box"].keys():
            toret = res["answer_box"]["snippet"]
        elif (
            "answer_box" in res.keys()
            and "snippet_highlighted_words" in res["answer_box"].keys()
        ):
            toret = res["answer_box"]["snippet_highlighted_words"][0]
        elif (
            "sports_results" in res.keys()
            and "game_spotlight" in res["sports_results"].keys()
        ):
            toret = res["sports_results"]["game_spotlight"]
        elif (
            "knowledge_graph" in res.keys()
            and "description" in res["knowledge_graph"].keys()
        ):
            toret = res["knowledge_graph"]["description"]
        elif "snippet" in res["organic_results"][0].keys():
            toret = res["organic_results"][0]["link"]

        else:
            toret = "No good search result found"
        return toret


# our custom tool
def get_profile_url(name: str):
    """Searches for Linkedin Profile Page."""
    search = CustomSerpAPIWrapper()
    res = search.run(f"{name}")
    return res
```

// Main code <br>
``` python
# General
import json
import os
import time

# Azure eventhub consumer client
from azure.eventhub import EventHubConsumerClient

# Azure eventhub producer client
from azure.eventhub import EventHubProducerClient, EventData
from azure.eventhub.exceptions import EventHubError

# langchain
from tools import CustomSerpAPIWrapper
from linkedin_lookup_agent import lookup as linkedin_lookup_agent
from langchain.prompts import PromptTemplate
from langchain_openai import ChatOpenAI
from langchain.chains import LLMChain

# get API key
OPENAIKEY = os.environ["OPENAI_API_KEY"]
PROXYCURL_API_KEY = os.environ["PROXYCURL_API_KEY"]
SERPAPI_API_KEY = os.environ["SERPAPI_API_KEY"]

# get Azure Eventhub connection string for consumer
CONNECTION_STR1 = os.environ['EVENT_HUB_CONN_STR1']
EVENTHUB_NAME_MYLEADS = os.environ['EVENT_HUB_NAME_MYLEADS']

# get Azure Eventhub connection string for producer
CONNECTION_STR2 = os.environ['EVENT_HUB_CONN_STR2']
EVENTHUB_NAME_MYCALLS = os.environ['EVENT_HUB_NAME_MYCALLS']

def on_event(partition_context, event):
    # Parse the event data as JSON.
    data = json.loads(event.body_as_str())
    
    # Extract the required information.
    first_name = data.get('First Name')
    last_name = data.get('Last Name')
    email = data.get('Email')
    company_name = data.get('Company Name')
    salution = data.get('Salutation')   
    gendar = data.get('Gendar')

    # Replace the 'information' variable.
    information = f"{first_name} {last_name}"
    # information = f"{full_name} {last_name} {company_name}"

    message = (
        "Search for information: "
        + str(information)
        + " with genAI ice-breaker!"
    )

    print(message)
    
    # Here start with genAI
    print("Hello LangChain!")

    # Load OpenAI Model
    llm = ChatOpenAI(model="gpt-3.5-turbo",temperature=0, max_tokens=2048) 
    
    # Input person, output URL (Output Indicator)
    template = """given the full name {name_of_person} I want you to get it me a link to their Linkedin profile page.
                          Your answer should contain only a URL"""# Name of the Tool, Function (this will be called by the Agent if this tool will used), description is the key for choose the right cool, please be clear
    tools_for_agent1 = [
        Tool(
            name="Crawl Google 4 linkedin profile page",
            func=get_profile_url,
            description="useful for when you need get the Linkedin Page URL",
        ),
    ]

    # create template with input
    prompt_template = PromptTemplate(input_variables=["name_of_person"], template=template)
    
    # Initialize the AGENT, verbose=TRUE means we will see everything in the reason process
    agent = initialize_agent(tools_for_agent1, llm, agent=AgentType.ZERO_SHOT_REACT_DESCRIPTION, verbose=True)
    
    # run the Agent
    linkedin_username = agent.run(prompt_template.format_prompt(name_of_person=information))
    print(linkedin_username);
    linkedin_data = scrape_linkedin_profile(linkedin_profile_url=linkedin_username)
    
    # Define tasks for chatgpt
    summary_template = """
        given the Linkedin information {linkedin_information} about a person from I want you to create:
        1. a short summary
        2. two interesting facts about them
        3. A topic that may interest them
        4. 2 creative Ice breakers to open a conversation with them 
    """
    
    # prepare prompt (chat)
    summary_prompt_template = PromptTemplate(
    input_variables=["linkedin_information"],
    template=summary_template)
    
    # create chatgpt instance
    llm = ChatOpenAI(model="gpt-3.5-turbo",temperature=0, max_tokens=2048) 

    # LLM chain
    chain = LLMChain(llm=llm, prompt=summary_prompt_template)
    # execute and print result
    result = chain.run(linkedin_information=linkedin_data)
    print(result)

    # Create a producer client
    producer = EventHubProducerClient.from_connection_string(conn_str=CONNECTION_STR2,eventhub_name=EVENTHUB_NAME_MYCALLS)

    # Prepare your data
    data1 = {
        "event_time": time.time(),
        "first_name": first_name,
        "last_name": last_name,
        "email": email,
        "company_name": company_name,
        "salutation": salution,
        "gender": gendar,
        "ice_breaker": result
    }

    # Convert the data to a JSON string
    json_data = json.dumps(data1)

    # Create a batch
    event_data_batch = producer.create_batch()  
    
    # Add the data to the batch.
    event_data_batch.add(EventData(json_data))
    
    # Send the batch of events to the event hub.
    producer.send_batch(event_data_batch)

def on_partition_initialize(partition_context):
    # Put your code here.
    print("Partition: {} has been initialized.".format(partition_context.partition_id))

def on_partition_close(partition_context, reason):
    # Put your code here.
    print("Partition: {} has been closed, reason for closing: {}.".format(
        partition_context.partition_id,
        reason
    ))

def on_error(partition_context, error):
    # Put your code here. partition_context can be None in the on_error callback.
    if partition_context:
        print("An exception: {} occurred during receiving from Partition: {}.".format(
            partition_context.partition_id,
            error
        ))
    else:
        print("An exception: {} occurred during the load balance process.".format(error))

if __name__ == '__main__':
    # Create a consumer client
    consumer_client = EventHubConsumerClient.from_connection_string(
        conn_str=CONNECTION_STR1,
        consumer_group='$Default',
        eventhub_name=EVENTHUB_NAME_MYLEADS,
    )

    try:
        # Consume message in Azure Eventhub and generate icer Breaker info from Linkin using OpenAI search
        with consumer_client:
            consumer_client.receive(
                on_event=on_event,
                on_partition_initialize=on_partition_initialize,
                on_partition_close=on_partition_close,
                on_error=on_error,
                starting_position="-1",  # "-1" is from the beginning of the partition.
            )
    
    except KeyboardInterrupt:
        print('Stopped receiving.')
```

### Check dataverse_mycalls topic with ice-breaker generated information facts in Azure Eventhub

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/f4717e64-347c-48fe-ba8f-dce80820fb85)




