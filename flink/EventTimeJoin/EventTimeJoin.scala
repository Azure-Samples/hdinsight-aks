package org.apache.flink.examples

import org.apache.flink.examples.{Customer, EnrichedTrade, Sources, Trade}
import org.apache.flink.streaming.api.scala._
import org.apache.flink.api.common.serialization.SimpleStringEncoder
import org.apache.flink.core.fs.Path
import org.apache.flink.configuration.MemorySize
import org.apache.flink.connector.file.sink.FileSink
import org.apache.flink.streaming.api.functions.sink.filesystem.rollingpolicies.DefaultRollingPolicy

import java.time.Duration


object EventTimeJoin
{
  def main(args: Array[String]): Unit = {
    // Set up the streaming execution environment
    val env = StreamExecutionEnvironment.getExecutionEnvironment

    // Generate data streams for trades and customers
    val tradeSource: DataStream[Trade] = Sources.generateTrades(env)
    val customerSource: DataStream[Customer] = Sources.generateCustomers(env)

    // Connect the two streams and apply the CoProcessFunction
    val enrichedTradeStream: DataStream[EnrichedTrade] = tradeSource
      .connect(customerSource)
      .keyBy(_.customerID, _.customerID)
      .process(new EventTimeJoinFunctionSolution)

    // Convert EnrichedTrade to String for sinking
    val enrichedTradeStringStream: DataStream[String] = enrichedTradeStream.map(_.toString)

    // Define the sink for the enriched trades (e.g., print to console or write to a file)
    //enrichedTradeStream.print()
    val outputPath: String = "abfs://testdata@gdhilotest.dfs.core.windows.net/flinkoutput"
    val sink: FileSink[String] = FileSink
        .forRowFormat(new Path(outputPath), new SimpleStringEncoder[String]("UTF-8"))
        .withRollingPolicy(
            DefaultRollingPolicy.builder()
                .withRolloverInterval(Duration.ofMinutes(2))
                .withInactivityInterval(Duration.ofMinutes(3))
                .withMaxPartSize(MemorySize.ofMebiBytes(5))
                .build())
        .build()

    enrichedTradeStringStream.sinkTo(sink)

    // Execute the Flink job
    env.execute("Trade and Customer Join Example")
  }

}
