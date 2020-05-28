variable "key_name" {
  description = "Desired name of AWS key pair"
}
variable "aws_vpc_cidr" {
}
variable "aws_external1_subnet_cidr" {
}
variable "aws_external2_subnet_cidr" {
}
variable "aws_internal1_subnet_cidr" {
}
variable "aws_webserver1_subnet_cidr" {
}
variable "aws_webserver2_subnet_cidr" {
}
variable "aws_externallb1_subnet_cidr" {
}
variable "aws_externallb2_subnet_cidr" {
}
variable "aws_internallb1_subnet_cidr" {
}
variable "aws_internallb2_subnet_cidr" {
}
variable "my_user_data" {
}
variable "perimeter_user_data" {
}
variable "ubuntu_user_data" {
}
variable "externaldnshost" {
}
variable "cg_size" {
}
variable "ws_size" {
}
variable "r53zone" {
}
variable "SICKey" {
}
variable "AllowUploadDownload" {
}
variable "pwd_hash" {
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-2"
}
variable "primary_az" {
  description = "primary AZ"
  default     = "us-east-2a"
}
variable "secondary_az" {
  description = "secondary AZ"
  default     = "us-east-2b"
}

# Check Point R80 BYOL
data "aws_ami" "chkp_ami" {
  most_recent      = true
  filter {
    name   = "name"
    values = ["Check Point CloudGuard IaaS GW BYOL R80.40-*"]
  }
  owners = ["679593333241"]
}

# Ubuntu Image
data "aws_ami" "ubuntu_ami" {
  most_recent      = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}

# Specify the provider and access details
provider "aws" {
  region = var.aws_region
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = var.aws_vpc_cidr
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

# Grant the VPC internet access on its main route table
#resource "aws_route" "internet_access" {
#  route_table_id         = aws_vpc.default.main_route_table_id
#  destination_cidr_block = "0.0.0.0/0"
#  gateway_id             = aws_internet_gateway.default.id
#}

# Define an external subnet for the security layer facing internet in the primary availability zone
resource "aws_subnet" "external1" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.aws_external1_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.primary_az
  tags = {
    Name = "Terraform_external1"
  }
}

# Define an external subnet for the security layer facing internet in the secondary availability zone
resource "aws_subnet" "external2" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.aws_external2_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.secondary_az
  tags = {
    Name = "Terraform_external2"
  }
}

# Define an internal subnet for the security layer facing internet in the primary availability zone
resource "aws_subnet" "internal1" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.aws_internal1_subnet_cidr
  map_public_ip_on_launch = false
  availability_zone       = var.primary_az
  tags = {
    Name = "Terraform_internal1"
  }
}

# Define a subnet for the web servers in the primary availability zone
resource "aws_subnet" "web1" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.aws_webserver1_subnet_cidr
  availability_zone       = var.primary_az
  tags = {
    Name = "Terraform_web1"
  }
}
# Define a subnet for the web servers in the secondary availability zone
resource "aws_subnet" "web2" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.aws_webserver2_subnet_cidr
  availability_zone       = var.secondary_az
  tags = {
    Name = "Terraform_web2"
  }
}

# Define a subnet for the external load balancers in the primary availability zone
resource "aws_subnet" "externallb1" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.aws_externallb1_subnet_cidr
  availability_zone       = var.primary_az
  tags = {
    Name = "ExternalLB_web1"
  }
}

# Define a subnet for the external load balancers in the secondary availability zone
resource "aws_subnet" "externallb2" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.aws_externallb2_subnet_cidr
  availability_zone       = var.secondary_az
  tags = {
    Name = "ExternalLB_web2"
  }
}

# Define a subnet for the internal load balancers in the primary availability zone
resource "aws_subnet" "internallb1" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.aws_internallb1_subnet_cidr
  availability_zone       = var.primary_az
  tags = {
    Name = "InternalLB_web1"
  }
}

# Define a subnet for the internal load balancers in the secondary availability zone
resource "aws_subnet" "internallb2" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.aws_internallb2_subnet_cidr
  availability_zone       = var.secondary_az
  tags = {
    Name = "InternalLB_web2"
  }
}


# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "permissive" {
  name        = "terraform_permissive_sg"
  description = "Used in the terraform"
  vpc_id      = aws_vpc.default.id


  # access from the internet
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route_table" "defaultrt" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
   }
  }

resource "aws_route_table_association" "external1association" {
    subnet_id      = aws_subnet.external1.id
    route_table_id = aws_route_table.defaultrt.id
  }

resource "aws_route_table_association" "external2association" {
    subnet_id      = aws_subnet.external2.id
    route_table_id = aws_route_table.defaultrt.id
  }

resource "aws_route_table_association" "externallb1association" {
    subnet_id      = aws_subnet.externallb1.id
    route_table_id = aws_route_table.defaultrt.id
  }
resource "aws_route_table_association" "externallb2association" {
    subnet_id      = aws_subnet.externallb2.id
    route_table_id = aws_route_table.defaultrt.id
  }

resource "aws_route_table" "webrt" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    network_interface_id = aws_network_interface.gateway_nic2.id
   }
  lifecycle {
    ignore_changes = [route]
  }
  }

resource "aws_route_table_association" "web1rgassociation" {
    subnet_id      = aws_subnet.web1.id
    route_table_id = aws_route_table.webrt.id
  }

resource "aws_route_table_association" "web2rgassociation" {
      subnet_id      = aws_subnet.web2.id
      route_table_id = aws_route_table.webrt.id
  }

resource "aws_launch_configuration" "sgw_conf" {
  name          = "sgw_config"
  image_id      = data.aws_ami.chkp_ami.id
  instance_type = var.cg_size 
  key_name      = var.key_name
  security_groups = [aws_security_group.permissive.id]
  user_data     = var.my_user_data
  associate_public_ip_address = true
}

resource "aws_launch_configuration" "web_conf" {
  name          = "web_config"
  image_id      = data.aws_ami.ubuntu_ami.id
  instance_type = var.ws_size
  key_name      = var.key_name
  security_groups = [aws_security_group.permissive.id]
  user_data     = var.ubuntu_user_data
  associate_public_ip_address = false
}

resource "aws_lb" "sgw" {
  name = "terraform-external-lb"
  load_balancer_type = "network"
  subnets         = [aws_subnet.external1.id,aws_subnet.external2.id]
  #security_groups = [aws_security_group.permissive.id]
}

resource "aws_lb_target_group" "sgwtarget" {
  name     = "securitygateways"
  port     = 8090
  protocol = "TCP"
  vpc_id   = aws_vpc.default.id
}

resource "aws_lb_listener" "sgwlb" {
  load_balancer_arn = aws_lb.sgw.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sgwtarget.arn
  }
}

resource "aws_autoscaling_group" "sgw_asg" {
  name = "cloudguard-layer-autoscale"
  launch_configuration = aws_launch_configuration.sgw_conf.id
  max_size = 4
  min_size = 4
  desired_capacity = 4
  target_group_arns = [aws_lb_target_group.sgwtarget.arn]
  vpc_zone_identifier = [aws_subnet.external1.id,aws_subnet.external2.id]
  tag {
      key = "Name"
      value = "CHKP-AutoScale"
      propagate_at_launch = true
  }
  tag {
      key = "x-chkp-tags"
      value = "management=r80dot40mgmt:template=AWS_East_AutoScale"
      propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "web_asg" {
  name = "web-layer-autoscale"
  launch_configuration = aws_launch_configuration.web_conf.id
  max_size = 5
  min_size = 3
  desired_capacity = 3
  health_check_grace_period = 5
  target_group_arns = [aws_lb_target_group.webtarget.arn]
  vpc_zone_identifier = [aws_subnet.web1.id,aws_subnet.web2.id]
  tag {
      key = "Name"
      value = "web-AutoScale"
      propagate_at_launch = true
  }
  tag {
      key = "data-profile"
      value = "PCI"
      propagate_at_launch = true
  }
}
resource "aws_lb" "web" {
  name = "terraform-web-lb"
  load_balancer_type = "network"
  subnets         = [aws_subnet.web1.id,aws_subnet.web2.id]
  #security_groups = [aws_security_group.permissive.id]
  internal        = true
  tags = {
    x-chkp-tags = "management=r80dot40mgmt:template=AWS_East_AutoScale"
  }            
}

resource "aws_lb_target_group" "webtarget" {
  name     = "webservers"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.default.id
}

resource "aws_lb_listener" "weblb" {
  load_balancer_arn = aws_lb.web.arn
  port              = "8090"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webtarget.arn
  }
}

data "aws_route53_zone" "selected" {
  name         = var.r53zone
}

resource "aws_route53_record" "cg-demo" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.externaldnshost}.${var.r53zone}"
  type    = "A"
  alias {
    name                   = aws_lb.sgw.dns_name
    zone_id                = aws_lb.sgw.zone_id
    evaluate_target_health = true
  }
}

# Start Stand Alone Gateway

resource "aws_network_interface" "gateway_nic1" {
  subnet_id   = aws_subnet.external1.id
  private_ips = ["10.30.1.10"]
  security_groups = [aws_security_group.permissive.id]
  source_dest_check = false
  tags = {
    Name = "external_network_interface"
  }
}

resource "aws_network_interface" "gateway_nic2" {
  subnet_id   = aws_subnet.internal1.id
  private_ips = ["10.30.3.10"]
  security_groups = [aws_security_group.permissive.id]
  source_dest_check = false
  tags = {
    Name = "internal_network_interface"
    x-chkp-topology = "specific:test"
  }
}

#Create EIP for the Check Point Gateway Server
resource "aws_eip" "CHKP_Gateway_EIP" {
  network_interface = aws_network_interface.gateway_nic1.id
  vpc      = true
}

# Create Check Point Gateway
resource "aws_instance" "CHKP_Gateway_Server" {
  tags = {
      Name = "CHKP-Perimeter-GW"
      x-chkp-tags = "management=r80dot40mgmt:template=AWS_East_Perimeter" 
  }
  ami           = data.aws_ami.chkp_ami.id
  instance_type = var.cg_size
  key_name      = var.key_name
  user_data     = var.perimeter_user_data
  network_interface {
      network_interface_id = aws_network_interface.gateway_nic1.id
      device_index = 0
      }
      network_interface {
          network_interface_id = aws_network_interface.gateway_nic2.id
          device_index = 1
          }
}
