# Output endpoint (hostname:port) of the Redshift cluster
output "redshift_cluster_endpoint" {
  value = "${aws_redshift_cluster.main_redshift_cluster.endpoint}"
}

output "bucket_arn" {
  value = "${aws_s3_bucket.bucket.arn}"
}

output "redshiftpassword" {
  value = "${random_string.password.result}"
}
