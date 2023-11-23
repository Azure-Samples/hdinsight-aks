package contoso.example;

import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.table.data.RowData;

import org.apache.hadoop.conf.Configuration;

import org.apache.hadoop.hive.conf.HiveConf;
import org.apache.iceberg.DistributionMode;
import org.apache.iceberg.Schema;
import org.apache.iceberg.flink.FlinkSchemaUtil;
import org.apache.iceberg.flink.TableLoader;
import org.apache.iceberg.flink.sink.FlinkSink;
import org.apache.iceberg.types.Types;

import org.apache.iceberg.catalog.TableIdentifier;
import org.apache.iceberg.flink.CatalogLoader;

import java.util.Collections;

public class FlinkSinkTest {
    public static void main(String[] args) throws Exception {

        // Set up the execution environment for the Flink streaming job
        final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        // checkpointing is set to 10 seconds
        env.enableCheckpointing(10000);
        String checkPointPath = "abfs://<container>@<storage_account>.dfs.core.windows.net/CheckPoint";
        env.getCheckpointConfig().setCheckpointStorage(checkPointPath);

        // Generate the stream data
        // the interval at which a fake data record is generated is set to 5 seconds
        DataStream<RowData> streamSource = env.addSource(new LordSourceFunction());
        streamSource.print();

        // Define the Iceberg schema
        Schema icebergSchema = new Schema(
                Types.NestedField.optional(1, "character", Types.StringType.get()),
                Types.NestedField.optional(2, "location", Types.StringType.get()),
                Types.NestedField.optional(3, "event_time", Types.TimestampType.withoutZone())
        );

        // Create a catalog loader
        String catalogName = "hive_catalog";
        String databaseName = "lord";
        String tableName = "character_sightings";

        // Create a HiveConf
        HiveConf hiveConf = new HiveConf();
        hiveConf.set("hive.metastore.uris", "thrift://hive-metastore:9083");
        hiveConf.set("hive.metastore.warehouse.dir", "abfs://<container>@<storage_account>.dfs.core.windows.net/iceberg-output");

        // Convert HiveConf to Configuration
        Configuration hadoopConf = new Configuration(hiveConf);

       // Create a CatalogLoader
        CatalogLoader catalogLoader = CatalogLoader.hive(catalogName, hadoopConf, Collections.emptyMap());

        // Create a TableIdentifier
        TableIdentifier identifier = TableIdentifier.of(databaseName, tableName);

        // Create a TableLoader
        TableLoader tableLoader = TableLoader.fromCatalog(catalogLoader, identifier);

        // Sink the stream data into the Iceberg table
        FlinkSink.forRowData(streamSource)
                .tableLoader(tableLoader)
                .tableSchema(FlinkSchemaUtil.toSchema(icebergSchema))
                .distributionMode(DistributionMode.HASH)
                .writeParallelism(2)
                .append();
        
        // Start the Flink streaming job
        env.execute("iceberg Sink Job");
    }
    
}
