terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.2.0, < 7.0.0"
    }
  }
  required_version = ">= 1.4.0"
}


provider "aws" {
  region = "ap-south-1"
}


locals{
  pairs ={
     for index, value in var.subnet: index =>{
              subnet = value
              ami = var.ami[index]
     }
  }
}


resource "aws_instance" "My_EC2" {
  for_each = local.pairs
    security_groups = var.security
    instance_type = var.instance_list
    subnet_id = each.value.subnet
    ami = each.value.ami
     iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  
  tags = { name = "instance=${each.key}" }
}

resource "aws_s3_bucket" "private_bucket" {
  bucket = var.s3
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.private_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "restrict_to_account" {
  bucket = aws_s3_bucket.private_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [
        aws_s3_bucket.private_bucket.arn,
        "${aws_s3_bucket.private_bucket.arn}/*"
      ]
      Condition = {
        StringEquals = {
          "aws:PrincipalAccount" = "689978033779"
        }
      }
    }]
  })
}

resource "aws_iam_role" "ec2_role" {
  name = "EC2RoleForS3Access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }  # allows EC2 to use this role
        Action   = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_access" {
  name = "S3AccessPolicy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [ aws_s3_bucket.private_bucket.arn ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [ "${aws_s3_bucket.private_bucket.arn}/*" ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "my-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}





