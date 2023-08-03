# resource "aws_instance" "venu" {
#         ami = "ami-0fb653ca2d3203ac1"
#         instance_type = "t2.micro"
#         vpc_security_group_ids = [aws_security_group.awssecuritygroup.id]

#         user_data = <<-EOF
#                     #!/bin/bash
#                     echo "Hello, World" > index.html
#                     nohup busybox httpd -f -p ${var.server_port} &
#                     EOF

#         user_data_replace_on_change = true
        
#         tags = {
#             Name = "terraform-example"
#         }
#     }
