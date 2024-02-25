**This bloc is to efficiently integrate customer data from Microsoft Dataverse, processes it using Flink, 
enriches it with LinkedIn insights via LangChain, leverages OpenAI for additional processing, and finally visualizes the enriched customer leads 
in Power BI for effective business decision-making. This end-to-end automation enhances lead generation and customer relationship management.**

Below is the architecture:<br>

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/266fc505-8013-400b-9e6b-6bac47f03630)

Here’s a summary for the workflow: <br>

**Microsoft Dataverse:** This is the starting point of the workflow. It’s connected to a “Sales/contacts table” which feeds into the workflow.<br>
**Azure Eventhub:** store layer.<br>
**Flink:** The data from the “Dataverse: contacts Topic” is processed in Flink SQL and then sent to “Dataverse: myleads Topic (Code Ceiling).”<br>
**LangChain:** An agent uses LangChain and Proxycurl for scraping data from LinkedIn. The process of extracting LinkedIn profiles and summaries is depicted, leading to “Azure Event Hub Dataverse: myleads Topic (Ice-Breaker generation).”****
**OpenAI:** The data flows into OpenAI for further processing.<br>
**Power BI:** Power BI is involved in calling an APP and generating calling list reports.<br>
