resource "aws_security_group" "selenium_grid__hub_sg" {
  vpc_id = "${aws_vpc.main.id}"
  name = "selenium_grid__hub_sg"
  description = "security group for selenium grid hub"
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 0
      to_port = 4444
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  } 
  
  tags {
    Name = "selenium_grid__hub_sg"
  }
}
