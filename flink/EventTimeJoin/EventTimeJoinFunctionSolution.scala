package org.apache.flink.examples

import java.util.{Collections, PriorityQueue}

import org.apache.flink.examples.{Customer, EnrichedTrade, Trade}
import org.apache.flink.api.common.state.{ValueState, ValueStateDescriptor}
import org.apache.flink.streaming.api.functions.co.CoProcessFunction
import org.apache.flink.streaming.api.scala._
import org.apache.flink.util.Collector

class EventTimeJoinFunctionSolution extends CoProcessFunction[Trade, Customer, EnrichedTrade] {

  lazy val tradeBufferState: ValueState[PriorityQueue[EnrichedTrade]] =
    getRuntimeContext.getState(
      new ValueStateDescriptor[PriorityQueue[EnrichedTrade]](
        "tradeBuffer",
        createTypeInformation[PriorityQueue[EnrichedTrade]]
      )
    )

  lazy val customerBufferState: ValueState[PriorityQueue[Customer]] =
    getRuntimeContext.getState(
      new ValueStateDescriptor[PriorityQueue[Customer]](
        "customerBuffer",
        createTypeInformation[PriorityQueue[Customer]]
      )
    )

  override def processElement1(
                                trade: Trade,
                                ctx: CoProcessFunction[Trade, Customer, EnrichedTrade]#Context,
                                collector: Collector[EnrichedTrade]): Unit = {

    System.out.println("Received " + trade.toString)

    if (trade.timestamp >= ctx.timerService().currentWatermark()) {
      val enrichedTrade = joinWithCustomerInfo(trade)
      collector.collect(enrichedTrade)
      bufferPrematureEnrichedTrade(enrichedTrade)
      ctx.timerService().registerEventTimeTimer(trade.timestamp)
    }
  }

  override def processElement2(
                                customer: Customer,
                                ctx: CoProcessFunction[Trade, Customer, EnrichedTrade]#Context,
                                collector: Collector[EnrichedTrade]): Unit = {

    System.out.println("Received " + customer.toString)

    updateCustomerData(customer)
  }

  override def onTimer(
                        timestamp: Long,
                        ctx: CoProcessFunction[Trade, Customer, EnrichedTrade]#OnTimerContext,
                        collector: Collector[EnrichedTrade]): Unit = {

    val currentWatermark = ctx.timerService().currentWatermark()

    while ({
      val lastEmittedTrade = peekPrematureEnrichedTrade()
      lastEmittedTrade != null && lastEmittedTrade.trade.timestamp <= currentWatermark
    }) {
      val trade = removePrematureEnrichedTrade()

      val newEnrichedTrade = joinWithCustomerInfo(trade.trade)
      if (!newEnrichedTrade.equals(trade)) {
        collector.collect(newEnrichedTrade)
      }
    }

    purgeBufferedCustomerDataOlderThanEventTime(currentWatermark)
  }

  // ------------------------------------------------------------------------------------
  //   Utility methods
  // ------------------------------------------------------------------------------------

  /**
   * Joins a given trade event with the customer info at the corresponding event time.
   */
  def joinWithCustomerInfo(trade: Trade): EnrichedTrade = {
    EnrichedTrade(trade, getCustomerInfoAtEventTime(trade.timestamp))
  }

  /**
   * Queries the customer data buffer for the customer data at a given event time.
   */
  def getCustomerInfoAtEventTime(targetTimestamp: Long): String = {
    val customerInfos = customerBufferState.value()

    if (customerInfos != null) {
      val customerInfosCopy = new PriorityQueue[Customer](customerInfos)

      while (!customerInfosCopy.isEmpty) {
        val customer = customerInfosCopy.poll()
        if (customer.timestamp <= targetTimestamp) {
          return customer.customerInfo
        }
      }
    }

    "N/A"
  }

  /**
   * Buffers an early-emitted trade into state, so that it can be
   * checked if a "better" result can be re-emitted in the future.
   *
   * The buffer is essentially a queue of premature enriched trades.
   */
  def bufferPrematureEnrichedTrade(enrichedTrade: EnrichedTrade): Unit = {
    var tradeBuffer = tradeBufferState.value()

    if (tradeBuffer == null) {
      tradeBuffer = new PriorityQueue[EnrichedTrade]()
    }
    tradeBuffer.add(enrichedTrade)

    tradeBufferState.update(tradeBuffer)
  }

  /**
   * Returns the last prematurely enriched trade, without removing it from buffer.
   */
  def peekPrematureEnrichedTrade(): EnrichedTrade = {
    val tradeBuffer = tradeBufferState.value()
    tradeBuffer.peek()
  }

  /**
   * Gets and removes the last prematurely enriched trade from the enriched trade buffer.
   */
  def removePrematureEnrichedTrade(): EnrichedTrade = {
    val tradeBuffer = tradeBufferState.value()

    val lastEmittedEnrichedTrade = tradeBuffer.poll()
    tradeBufferState.update(tradeBuffer)

    lastEmittedEnrichedTrade
  }

  /**
   * Updates the customer data buffer.
   */
  def updateCustomerData(customer: Customer): Unit = {
    var customerBuffer = customerBufferState.value()

    if (customerBuffer == null) {
      customerBuffer = new PriorityQueue[Customer](10, Collections.reverseOrder())
    }
    customerBuffer.add(customer)

    customerBufferState.update(customerBuffer)
  }

  /**
   * Clean up customer data in the buffer that are older than a given event time.
   */
  def purgeBufferedCustomerDataOlderThanEventTime(targetTimestamp: Long): Unit = {
    val customerBuffer = customerBufferState.value()
    val purgedBuffer = new PriorityQueue[Customer](10, Collections.reverseOrder())

    var customerTimestamp = Long.MaxValue
    while (!customerBuffer.isEmpty && customerTimestamp >= targetTimestamp) {
      val customer = customerBuffer.poll()
      purgedBuffer.add(customer)
      customerTimestamp = customer.timestamp
    }

    customerBufferState.update(purgedBuffer)
  }
}
