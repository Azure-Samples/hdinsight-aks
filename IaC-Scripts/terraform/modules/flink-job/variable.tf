variable "hdi_on_aks_pool_id" {
  description = "HDI on AKS pool id"
  type        = string
}

variable "env" {
  type        = string
  description = "Environment name like dev/test/prod/etc."
}


variable "flink_cluster_id" {
  description = "Flink cluster Id"
  type        = string
}

variable "hdi_arm_api_version" {
  type        = string
  description = "Azure HDI on AKS API version"
}

variable "location_name" {
  type        = string
  description = "location name/region"
}

variable "tags" {
  type        = map(string)
  description = "list of tags for resources"
}

variable "flink_job_action_flag" {
  type        = bool
  description = "Create/update/delete Flink job"
}

variable "flink_job_name" {
  type        = string
  description = "Flink Job Name"
}

variable "storage_account_name" {
  type        = string
  description = "storage account name; accessible from the flink cluster or associated MSI has permission to read this account"
}


variable "flink_job_jar_file" {
  type        = string
  description = <<-EOT
    Flink job jar file, it should be at present at the root level, if you are using CI/CD process,
    please ensure facts should be available to the terraform root
   EOT
}

# We don't pass value for flink_jar_container, in main.tf for flink-job module
# It is using Flink default container and storage account
variable "flink_jar_container" {
  type        = string
  description = <<-EOT
    Location of job jar file, this container should be accessible from the flink cluster,
    default value empty means it will use default flink cluster default container
  EOT
  default     = ""
}

variable "flink_job_entry_class_name" {
  type        = string
  description = "Flink job entry class name"
}

variable "flink_job_args" {
  type        = string
  description = <<-EOT
      Flink job arguments, like --<<var name1>> <<var value1>> --<<var name2>> <<var value2>>
    EOT
}

variable "flink_job_action" {
  type        = string
  description = "Job action can be NEW, UPDATE, STOP, START, CANCEL, or DELETE."
}
