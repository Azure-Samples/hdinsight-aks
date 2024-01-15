# Replace the TODOs with parameters specific to your setup

# imports
from time import sleep
from json import dumps
from kafka import KafkaProducer
from kafka.errors import KafkaError

import sys
import requests
import json
import random
import time

## Configuration section
iextoken = '' #An iexToken to use if you want to connect with the iex for stock quotes
stockList = ['msft', 'ba', 'jnj', 'f', 'tsla', 'bac', 'ge', 'mmm', 'intc', 'wmt']
# Use this dictionary to generate random prices for each stock based on mean and standard deviation
stockMeanPrices =   {'msft':{"mean":152, "stddev":5}, 'ba':{"mean":345, "stddev":10}, 'jnj':{"mean":141, "stddev":10}, 'f':{"mean":9, "stddev":1}, 'tsla':{"mean":330, "stddev":10}, \
                    'bac':{"mean":34, "stddev":1}, 'ge':{"mean":11, "stddev":1}, 'mmm':{"mean":168, "stddev":5}, 'intc':{"mean":55, "stddev":2}, 'wmt':{"mean":120, "stddev":3}}
defaultLoops = 1000
kafkaBrokers = ['wn0-jokers.4xlssw4otekunb0s5bkoftvtee.bx.internal.cloudapp.net:9092','wn1-jokers.4xlssw4otekunb0s5bkoftvtee.bx.internal.cloudapp.net:9092','wn2-jokers.4xlssw4otekunb0s5bkoftvtee.bx.internal.cloudapp.net:9092'] #TODO: Replace with your Kafak broker endpoint (including port)
kafkaTopic = 'stockVals'
simulator = True

## Read command line arguments
try:
    loops = int(sys.argv[1])
    print ("Number of loops is ", loops)
except:
    loops = defaultLoops
    print ("No loops argument provided. Default loops are ", loops)

## notify if simulator is on
if simulator:
    print ("Running in simulated mode")

## Construct parameters for the REST Request
requestParams = {'token':iextoken, 'symbols':",".join(stockList)}

# Configure Producer
producer = KafkaProducer(bootstrap_servers=kafkaBrokers,key_serializer=lambda k: k.encode('ascii','ignore'),value_serializer=lambda x: dumps(x).encode('utf-8'))

#### Main definition
def main():
    # Send messages
    for x in range(loops):
        ## Make a rest call from Python to get streaming data
        if simulator:
            responseList = simulatedResponse()
        else:
            responseList = requests.get(url=getStockApi, params=requestParams).json()

        print(json.dumps(responseList, indent=2))
        for stock in responseList:
            future = producer.send(kafkaTopic, key=stock["symbol"], value=stock)
            response = future.get(timeout=10)
            print (response.topic)
            print (response.partition)
            print (response.offset)
        sleep(1)


## Define simulator method: returns list with artificial stock data 
def simulatedResponse():
    # Empty json request
    responseList = []
    # Create a record for each stock and add it to the json request
    for stock in stockList:
        stockRecord = {
            "symbol" : stock.upper(),
            "time" : currentMilliTime(),
            "price" : round(random.gauss(stockMeanPrices[stock]["mean"], stockMeanPrices[stock]["stddev"]),3),
            "size" : random.randint(1,500)
        }
        responseList.append(stockRecord)

    return responseList

def currentMilliTime():
    return int(round(time.time() * 1000))

#### Main execution
main()