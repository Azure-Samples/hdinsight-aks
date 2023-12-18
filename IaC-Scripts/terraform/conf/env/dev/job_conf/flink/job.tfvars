# create job or not
flink_job_action_flag      = true
flink_job_name             = "testjob"
# the jar file should be present on root of the terraform directory
flink_job_jar_file         = "batch-1.0.jar"
# job main class
flink_job_entry_class_name = "com.ms.hdi.flink.batch.WordCount"
# job arguments
flink_job_args             = "--output abfs://flinkcluster@tfonakssteststorage.dfs.core.windows.net/test1"