import java.io.File
import java.net.URL
import org.apache.commons.io.FileUtils
import org.apache.hadoop.fs._
    
// data file object is being used for future reference in order to read parquet files from HDFS
case class DataFile(name:String, downloadURL:String, hdfsPath:String)
    
// get Hadoop file system
val fs:FileSystem = FileSystem.get(spark.sparkContext.hadoopConfiguration)
    
val fileUrls= List(
"https://d37ci6vzurychx.cloudfront.net/trip-data/fhvhv_tripdata_2022-01.parquet"
    )
    
// Add a file to be downloaded with this Spark job on every node.
        val listOfDataFile = fileUrls.map(url=>{
        val urlPath=url.split("/") 
        val fileName = urlPath(urlPath.size-1)
        val urlSaveFilePath = s"/tmp/${fileName}"
        val hdfsSaveFilePath = s"/tmp/${fileName}"
        val file = new File(urlSaveFilePath)
        FileUtils.copyURLToFile(new URL(url), file)
        // copy local file to HDFS /tmp/${fileName}
        // use FileSystem.copyFromLocalFile(boolean delSrc, boolean overwrite, Path src, Path dst)
        fs.copyFromLocalFile(true,true,new org.apache.hadoop.fs.Path(urlSaveFilePath),new org.apache.hadoop.fs.Path(hdfsSaveFilePath))
        DataFile(urlPath(urlPath.size-1),url, hdfsSaveFilePath)
})