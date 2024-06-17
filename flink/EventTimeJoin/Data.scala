package org.apache.flink.examples

import org.apache.flink.streaming.api.functions.source.SourceFunction
import org.apache.flink.streaming.api.functions.source.SourceFunction.SourceContext
import org.apache.flink.streaming.api.scala._
import org.apache.flink.streaming.api.watermark.Watermark

case class Customer(timestamp: Long, customerID: Long, customerInfo: String) extends Comparable[Customer] {
  override def compareTo(o: Customer): Int = timestamp.compareTo(o.timestamp)
}

case class Trade(timestamp: Long, customerID: Long, tradeInfo: String)
case class EnrichedTrade(trade: Trade, customerInfo: String) extends Comparable[EnrichedTrade] {
  override def compareTo(o: EnrichedTrade): Int = trade.timestamp.compareTo(o.trade.timestamp)
}

/**
 * Utility to generate simulated data points.
 */
object Sources {

  def generateCustomers(env: StreamExecutionEnvironment): DataStream[Customer] = {
    env.addSource(
      new SourceFunction[Customer] {
        override def run(sc: SourceContext[Customer]): Unit = {
          sc.collectWithTimestamp(Customer(0L, 0L, "Customer data @ 0"), 0)
          sc.emitWatermark(new Watermark(0))
          Thread.sleep(2000)
          sc.collectWithTimestamp(Customer(500L, 0L, "Customer data @ 500"), 500)
          sc.emitWatermark(new Watermark(500))
          Thread.sleep(1000)
          sc.collectWithTimestamp(Customer(1500L, 0L, "Customer data @ 1500"), 1500)
          sc.emitWatermark(new Watermark(1500))
          Thread.sleep(6000)
          sc.collectWithTimestamp(Customer(1600L, 0L, "Customer data @ 1600"), 1600)
          sc.emitWatermark(new Watermark(1600))
          Thread.sleep(1000)
          sc.collectWithTimestamp(Customer(2100L, 0L, "Customer data @ 2100"), 2100)
          sc.emitWatermark(new Watermark(2100))

          while (true) {
            Thread.sleep(1000)
          }
        }

        override def cancel(): Unit = {}
      }
    )
  }

  def generateTrades(env: StreamExecutionEnvironment): DataStream[Trade] = {
    env.addSource(
      new SourceFunction[Trade] {
        override def run(sc: SourceContext[Trade]): Unit = {
          Thread.sleep(1000)
          sc.collectWithTimestamp(Trade(1000L, 0L, "trade-1"), 1000)
          sc.emitWatermark(new Watermark(1000))
          Thread.sleep(3000)
          sc.collectWithTimestamp(Trade(1200L, 0L, "trade-2"), 1200)
          sc.emitWatermark(new Watermark(1200))
          Thread.sleep(1000)
          sc.collectWithTimestamp(Trade(1500L, 0L, "trade-3"), 1500)
          sc.emitWatermark(new Watermark(1500))
          Thread.sleep(1000)
          sc.collectWithTimestamp(Trade(1700L, 0L, "trade-4"), 1700)
          sc.emitWatermark(new Watermark(1700))
          Thread.sleep(1000)
          sc.collectWithTimestamp(Trade(1800L, 0L, "trade-5"), 1800)
          sc.emitWatermark(new Watermark(1800))
          Thread.sleep(1000)
          sc.collectWithTimestamp(Trade(2000L, 0L, "trade-6"), 2000)
          sc.emitWatermark(new Watermark(2000))

          while (true) {
            Thread.sleep(1000)
          }
        }

        override def cancel(): Unit = {}
      }
    )
  }

}

