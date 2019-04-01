module "taskredsfhitcluster" {
  source = "github.com/arunkumarc4484/terraformtask.git"

  clustertags = {
    "billingcode" = "testtask"
  }

  cluster_identifier      = "redshifttestcluster"
  node_type               = "dc2.large"
  cluster_number_of_nodes = "1"
  cluster_database_name   = "tasktest"
  cluster_master_username = "testmaster"
  bucket_name             = "redshifttestbucket"
}
provider "aws" {
  access_key = "XXXXXXXXXXXXXXXXXXXXXx"
  secret_key = "XXXXXXXXXXXXXXXXXXXXXXXx"
  region     = "us-east-1"
}
