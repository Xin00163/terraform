variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "AWS_REGION" {
    description = "EC2 Region for the VPC"
    default = "eu-west-1"
}

variable "amis" {
    description = "Selenium hub"
    default = {
        eu-west-1 = "ami-047bb4163c506cd98"
    }
}

variable "vpc_cidr" {
    description = "main vpc"
    default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
    description = "CIDR for the public subnet"
    default = "10.0.0.0/24"
}