##This bloc is to efficiently integrate customer data from Microsoft Dataverse, processes it using Flink, enriches it with LinkedIn insights via LangChain, leverages OpenAI for additional processing, and finally visualizes the enriched customer leads in Power BI for effective business decision-making. This end-to-end automation enhances lead generation and customer relationship management.

Below is the architecture:<br>

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/a0a86e62-8aba-43c3-9544-3e2258399e0c)


Here’s a summary for the workflow: <br>
**Microsoft Dataverse:** This is the starting point of the workflow. It’s connected to a “Sales/contacts table” which feeds into the workflow.<br>
**Azure Eventhub:** store layer.<br>
**Flink:** The data from the “Dataverse: contacts Topic” is processed in Flink SQL and then sent to "Dataverse: myleads Topic (Cold Calling).”<br>
**LangChain:** An agent uses LangChain and Proxycurl for scraping data from LinkedIn. The process of extracting LinkedIn profiles and summaries is depicted, leading to "Azure Event Hub Dataverse: myleads Topic (Ice-Breaker generation)."
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

### Creating a workflow in PowerAPP
In [PowerApp](https://make.preview.powerapps.com/), Creating a workflow in Microsoft Dataverse that’s designed to process changes in the Contacts table and then sink the data into Azure Event Hub. 

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/71f43296-ba4c-4a00-9ed5-f199a105de7a)


