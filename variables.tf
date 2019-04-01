variable "cluster_identifier" {
  description = "Name of the cluster"
}

variable "cluster_node_type" {
  description = "Node Type of Redshift cluster"
  default     = "dc2.large"
}

variable "cluster_number_of_nodes" {
  description = "Number of Node in the cluster"
}

variable "cluster_database_name" {
  description = "The name of the database to create"
}

variable "cluster_master_username" {}

variable "clustertags" {
  type = "map"
}

variable "bucket_name" {}
