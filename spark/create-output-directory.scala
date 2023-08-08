import org.apache.hadoop.fs._

// this is used to store source data being transformed and stored delta format
val transformDeltaOutputPath = "/nyctaxideltadata/transform"
// this is used to store Average KPI data in delta format
val avgDeltaOutputKPIPath = "/nyctaxideltadata/avgkpi"
// this is used for POWER BI reporting to show Month on Month change in KPI (not in delta format)
val avgMoMKPIChangePath = "/nyctaxideltadata/avgMoMKPIChangePath"

// create directory/folder if not exist
def createDirectory(dataSourcePath: String) = {
    val fs:FileSystem = FileSystem.get(spark.sparkContext.hadoopConfiguration)
    val path =  new Path(dataSourcePath)
    if(!fs.exists(path) && !fs.isDirectory(path)) {
        fs.mkdirs(path)
    }
}

createDirectory(transformDeltaOutputPath)
createDirectory(avgDeltaOutputKPIPath)
createDirectory(avgMoMKPIChangePath)