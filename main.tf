resource "aws_vpc" "redshift_vpc" {
  cidr_block = "10.153.0.0/16"

  tags = "${var.clustertags}"
}

resource "aws_subnet" "redshift_subnet1" {
  vpc_id     = "${aws_vpc.redshift_vpc.id}"
  cidr_block = "10.153.1.0/24"

  tags = "${var.clustertags}"
}

resource "aws_subnet" "redshift_subnet2" {
  vpc_id     = "${aws_vpc.redshift_vpc.id}"
  cidr_block = "10.153.2.0/24"
  tags       = "${var.clustertags}"
}

resource "aws_redshift_subnet_group" "main_redshift_subnet_group" {
  name        = "${var.cluster_identifier}-redshift-subnetgrp"
  description = "Redshift subnet group of ${var.cluster_identifier}"
  subnet_ids  = ["${aws_subnet.redshift_subnet1.id}", "${aws_subnet.redshift_subnet2.id}"]
}

resource "aws_security_group" "redshift_clustersecuritygroup" {
  name        = "Redshiftsg"
  description = "Redshift cluster sg"
  vpc_id      = "${aws_vpc.redshift_vpc.id}"
}

resource "aws_security_group_rule" "allow_port_inbound" {
  type = "ingress"

  from_port   = "5439"
  to_port     = "5439"
  protocol    = "tcp"
  cidr_blocks = ["${aws_vpc.redshift_vpc.cidr_block}"]

  security_group_id = "${aws_security_group.redshift_clustersecuritygroup.id}"
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["${aws_vpc.redshift_vpc.cidr_block}"]
  security_group_id = "${aws_security_group.redshift_clustersecuritygroup.id}"
}

data "aws_iam_policy_document" "redshift_s3access_policy_document" {
  statement {
    sid = "201608221701"

    actions = ["s3:*"]

    resources = [
      "${aws_s3_bucket.bucket.arn}",
      "${aws_s3_bucket.bucket.arn}/*",
    ]
  }
}

resource "aws_iam_role" "redshift_role" {
  name = "redshifts3role"

  assume_role_policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
     {
       "Action": "sts:AssumeRole",
       "Principal": {
         "Service": [ "redshift.amazonaws.com" ]
       },
       "Effect": "Allow",
       "Sid": "183030283"
     }
   ]
 }
EOF
}

resource "aws_iam_role_policy" "task_access_policy_attach" {
  role   = "${aws_iam_role.redshift_role.id}"
  policy = "${data.aws_iam_policy_document.redshift_s3access_policy_document.json}"
}

resource "random_string" "password" {
  length           = 16
  special          = true
  override_special = "/@\" "
}

resource "aws_redshift_cluster" "main_redshift_cluster" {
  cluster_identifier        = "${var.cluster_identifier}"
  node_type                 = "${var.cluster_node_type}"
  number_of_nodes           = "${var.cluster_number_of_nodes}"
  database_name             = "${var.cluster_database_name}"
  master_username           = "${var.cluster_master_username}"
  master_password           = "${random_string.password.result}"
  vpc_security_group_ids    = ["${aws_security_group.redshift_clustersecuritygroup.id}"]
  cluster_subnet_group_name = "${aws_redshift_subnet_group.main_redshift_subnet_group.name}"
  publicly_accessible       = "false"
  tags                      = "${var.clustertags}"

  iam_roles           = ["${aws_iam_role.redshift_role.arn}"]
  skip_final_snapshot = "true"
}

# create an s3 bucket
resource "aws_s3_bucket" "bucket" {
  bucket_prefix = "${var.bucket_name}"
  acl           = "private"
  tags          = "${var.clustertags}"
}

# grant user access to the bucket
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = "${aws_s3_bucket.bucket.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
         "AWS":  "${aws_iam_role.redshift_role.arn}"
       },
      "Action": [ "s3:*" ],
      "Resource": [
        "${aws_s3_bucket.bucket.arn}",
        "${aws_s3_bucket.bucket.arn}/*"
      ]
    }
  ]
}
EOF
}
