# the default flink jar will be uploaded to the Flink cluster default storage and default container
# if you need other container, add another resource to create that container
variable "flink_job_action_flag" {
  type        = bool
  description = "Create/update/delete Flink job"
}

variable "flink_job_name" {
  type        = string
  description = "Flink Job Name"
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
  description = "Flink job main entry class name"
}

variable "flink_job_args" {
  type        = string
  description = <<-EOT
      Flink job arguments, like --<<var name1>> <<var value1>> --<<var name2>> <<var value2>>
    EOT
}

variable "flink_job_action" {
  type        = string
  description = "Job action can be NEW, UPDATE or DELETE."
  validation {
    condition     = contains(["NEW", "UPDATE", "DELETE"], var.flink_job_action)
    error_message = "Valid values for flink_job_action are (NEW, UPDATE, DELETE, CANCEL, STOP)"
  }
}