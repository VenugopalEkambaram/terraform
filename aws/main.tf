provider "aws"{
    region = "us-east-2"    
}


# output "public_ip" {
#     value = aws_instance.venu.public_ip
#     description = "The public IP address of the web server"
# }

output "alb_dns_name" {
    value = aws_lb.mylb.dns_name
    description = "The domain name of the load balancer"
}

// Creates Launch configuration (Deprecated)
# resource "aws_launch_configuration" "example" {
#     image_id = "ami-0fb653ca2d3203ac1"
#     instance_type = "t2.micro"
#     security_groups = [aws_security_group.awssecuritygroup.id]

#     user_data = <<-EOF
#                     #!/bin/bash
#                     echo "Hello, World" > index.html
#                     nohup busybox httpd -f -p ${var.server_port} &
#                     EOF   
  
#   lifecycle {
#     create_before_destroy = true
#   }
# }

// Creates Launch template
resource "aws_launch_template" "example" {
  image_id = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"
  //security_group_names = [aws_security_group.awssecuritygroup.example]
  vpc_security_group_ids = [aws_security_group.awssecuritygroup.id]
    
    user_data = base64encode(<<-EOF
                    #!/bin/bash
                    echo "Hello, World" > index.html
                    nohup busybox httpd -f -p ${var.server_port} &
                    EOF   
                    )
  
  lifecycle {
    create_before_destroy = true
  }
}


// create auto scaling group
resource "aws_autoscaling_group" "example" {
    launch_template {
      name = aws_launch_template.example.name
    }
    vpc_zone_identifier =  data.aws_subnets.mysubnets.ids

    target_group_arns = [aws_lb_target_group.asg.arn]
    health_check_type = "ELB"

    min_size = 2
    max_size = 10

    tag {
        key = "Name"
        value = "terraform-asg-example"
        propagate_at_launch = true
    }

}

// Create load balancer. Possible types are ALB, NLB, CLB
resource "aws_lb" "mylb" {
  name = "terraform-asg-example"
  load_balancer_type = "application"
  subnets = data.aws_subnets.mysubnets.ids
  security_groups = [aws_security_group.myalb.id]
}

// Creates load balancer listner
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.mylb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
        content_type = "text/plain"
        message_body = "404: page not found"
        status_code = 404
    }
  }
}


resource "aws_lb_target_group" "asg" {
  name = "terraform-asg-example"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.myvpc.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_pattern {
        values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

data "aws_vpc" "myvpc" {
    default = true
}

data "aws_subnets" "mysubnets" {
    filter {
        name = "vpc-id"
        values = [data.aws_vpc.myvpc.id]
    }
}