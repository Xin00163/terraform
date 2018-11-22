data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags {
    Name = "Fargate"
  }
}

resource "aws_subnet" "main" {
  count                   = 2
  cidr_block              = "${cidrsubnet(aws_vpc.main.cidr_block, 8, 2 + count.index)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id                  = "${aws_vpc.main.id}"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route" "internet-gateway-route" {
  route_table_id         = "${aws_route_table.public.id}"
  gateway_id             = "${aws_internet_gateway.gateway.id}"
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = "${element(aws_subnet.main.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_security_group" "loadbalancer_security_group" {
  name        = "tf-ecs-alb"
  description = "controls access to the ALB"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_security_group" {
  name        = "fargate-security-group"
  description = "allow inbound access from the ALB only"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = ["${aws_security_group.loadbalancer_security_group.id}"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "main" {
  name            = "fargate-application"
  subnets         = ["${aws_subnet.main.*.id}"]
  security_groups = ["${aws_security_group.loadbalancer_security_group.id}"]
}

resource "aws_alb_target_group" "app_one" {
  name        = "hub"
  port        = 4444
  protocol    = "HTTP"
  vpc_id      = "${aws_vpc.main.id}"
  target_type = "ip"
}

resource "aws_alb_listener" "listener" {
  load_balancer_arn = "${aws_alb.main.id}"
  port              = "4444"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.app_one.id}"
    type             = "forward"
  }
}

resource "aws_ecs_cluster" "main" {
  name = "selenium-cluster"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"

  container_definitions = <<DEFINITION
[
  {
    "cpu": 256,
    "image": "selenium/hub:latest",
    "memory": 512,
    "name": "selenium",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 4444,
        "hostPort": 4444
      }
    ],
    "environment": [
      {
          "name": "GRID_MAX_SESSION",
          "value": "20"
      },
      {
          "name": "TIMEOUT",
          "value": "1200000"
      },
      {
          "name": "GRID_TIMEOUT",
          "value": "0"
      },
      {
          "name": "GRID_NEW_SESSION_WAIT_TIMEOUT",
          "value": "1"
      }
    ]
  },
  {
    "cpu": 256,
    "image": "selenium/node-firefox:latest",
    "memory": 512,
    "name": "firefox-node",
    "networkMode": "awsvpc",
    "environment": [
      {
          "name": "NODE_MAX_SESSION",
          "value": "10"
      },
      {
          "name": "NODE_MAX_INSTANCES",
          "value": "10"
      },
      {
          "name": "HUB_PORT_4444_TCP_ADDR",
          "value": "selenium"
      },
      {
          "name": "HUB_PORT_4444_TCP_PORT",
          "value": "4444"
      }
    ],
    "privileged" : false,
    "volumes": [
        {
            "name": "/dev/shm",
            "host": {
                "sourcePath": "/dev/shm"
            },
            "dockerVolumeConfiguration": {
                "scope": "shared",
                "autoprovision": true,
                "driver": "",
                "driverOpts": {
                    "KeyName": ""
                },
                "labels": {
                    "KeyName": ""
                }
            }
        }
    ]
  },
  {
    "cpu": 256,
    "image": "selenium/node-chrome:latest",
    "memory": 512,
    "name": "chrome-node",
    "networkMode": "awsvpc",
    "environment": [
      {
          "name": "NODE_MAX_SESSION",
          "value": "10"
      },
      {
          "name": "NODE_MAX_INSTANCES",
          "value": "10"
      },
      {
          "name": "HUB_PORT_4444_TCP_ADDR",
          "value": "selenium"
      },
      {
          "name": "HUB_PORT_4444_TCP_PORT",
          "value": "4444"
      }
    ],
    "privileged" : false,
    "volumes": [
        {
            "name": "/dev/shm",
            "host": {
                "sourcePath": "/dev/shm"
            },
            "dockerVolumeConfiguration": {
                "scope": "shared",
                "autoprovision": true,
                "driver": "",
                "driverOpts": {
                    "KeyName": ""
                },
                "labels": {
                    "KeyName": ""
                }
            }
        }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "ecs-service" {
  name            = "selenium-service"
  cluster         = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.app.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = ["${aws_security_group.ecs_security_group.id}"]
    subnets          = ["${aws_subnet.main.*.id}"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.app_one.id}"
    container_name   = "selenium"
    container_port   = 4444
  }

  depends_on = [
    "aws_alb_listener.listener",
  ]
}
