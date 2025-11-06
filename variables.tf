variable "instance_list" {
    type = string
    description = "aws instance type"
}

variable "s3" {
   type = string
   description = "creating S3 bucket"
}

variable "subnet" {
  type = list(string)
  description = "for creating in multi az"
}

variable "ami" {
  type = list(string)
}


variable "security" {
   type = list(string)
}

