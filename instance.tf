provider "aws" {
  access_key = "${var.AWS_ACCESS_KEY}"
  secret_key = "${var.AWS_SECRET_KEY}"
  region = "${var.AWS_REGION}"
}

resource "aws_instance" "terraform_demo" {
  ami           = "ami-047bb4163c506cd98"
  instance_type = "t2.micro"
  tags = {
    Name = "Terraform_Demo"
    Owner = "Xin Wang"
    Role = "Demo"
  }
}
