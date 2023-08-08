import org.apache.spark.sql.functions.udf
import org.apache.spark.sql.DataFrame

// UDF to compute sum of value paid by customer
def totalCustPaid = udf((basePassengerFare:Double, tolls:Double,bcf:Double,salesTax:Double,congSurcharge:Double,airportFee:Double, tips:Double) => {
    val total = basePassengerFare + tolls + bcf + salesTax + congSurcharge + airportFee + tips
    total
})

// read parquet file from spark conf with given file input
// transform data to compute total amount
// compute kpi for the given file/batch data
def readTransformWriteDelta(fileName:String, oldData:Option[DataFrame], format:String="parquet"):DataFrame = {
    val df = spark.read.format(format).load(fileName)
    val dfNewLoad= df.withColumn("total_amount",totalCustPaid($"base_passenger_fare",$"tolls",$"bcf",$"sales_tax",$"congestion_surcharge",$"airport_fee",$"tips"))
    // union with old data to compute KPI
    val dfFullLoad= oldData match {
        case Some(odf)=>
                dfNewLoad.union(odf)
        case _ =>
                dfNewLoad
    }
    dfFullLoad.createOrReplaceTempView("tempFullLoadCompute")
    val dfKpiCompute = spark.sql("SELECT round(avg(trip_miles),2) AS avgDist,round(avg(total_amount/trip_miles),2) AS avgCostPerMile,round(avg(total_amount),2) avgCost FROM tempFullLoadCompute")
    // save only new transformed data
    dfNewLoad.write.mode("overwrite").format("delta").save(transformDeltaOutputPath)
    //save compute KPI
    dfKpiCompute.write.mode("overwrite").format("delta").save(avgDeltaOutputKPIPath)
    // return incremental dataframe for next set of load
    dfFullLoad
}

// load data for each data file, use last dataframe for KPI compute with the current load
def loadData(dataFile: List[DataFile], oldDF:Option[DataFrame]):Boolean = {
    if(dataFile.isEmpty) {    
        true
    } else {
        val nextDataFile = dataFile.head
        val newFullDF = readTransformWriteDelta(nextDataFile.hdfsPath,oldDF)
        loadData(dataFile.tail,Some(newFullDF))
    }
}
val starTime=System.currentTimeMillis()
loadData(listOfDataFile,None)
println(s"Time taken in Seconds: ${(System.currentTimeMillis()-starTime)/1000}")