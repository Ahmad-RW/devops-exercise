resource "aws_vpc" "main" {
    cidr_block = var.cidr_block
    tags = merge(var.tags)      
}

data "aws_caller_identity" "current" {}

locals {
  region     = "us-east-1"
  name       = "network-firewall-ex-${basename(path.cwd)}"
  account_id = data.aws_caller_identity.current.account_id
  private_nlb_ip = "10.0.32.32"
}



## Public subnet
resource "aws_subnet" "public-1a" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.16.0/20"
    availability_zone_id = element(var.azs, 0)
    tags = merge(var.tags)
    
}

# resource "aws_subnet" "public-1b" {
#     vpc_id = aws_vpc.main.id
#     cidr_block = "10.0.64.0/20"
#     availability_zone_id = element(var.azs, 1)
#     tags = merge(var.tags)      

# }

# resource "aws_subnet" "public-1c" {
#     vpc_id = aws_vpc.main.id
#     cidr_block = "10.0.112.0/20"
#     availability_zone_id = element(var.azs, 2)
#     tags = merge(var.tags)      
# }

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
    tags = merge(var.tags)
}

resource "aws_route_table" "public-rtb" {
    vpc_id = aws_vpc.main.id
}

resource "aws_route" "outbound"{
    route_table_id = aws_route_table.public-rtb.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public-rtb-subnet-association-1a" {
    subnet_id = aws_subnet.public-1a.id
    route_table_id = aws_route_table.public-rtb.id
}

# resource "aws_route_table_association" "public-rtb-subnet-association-1b" {
#     subnet_id = aws_subnet.public-1b.id
#     route_table_id = aws_route_table.public-rtb.id
# }

# resource "aws_route_table_association" "public-rtb-subnet-association-1c" {
#     subnet_id = aws_subnet.public-1c.id
#     route_table_id = aws_route_table.public-rtb.id
# }

resource "aws_network_acl" "public-subnets-nacl" {
    vpc_id = aws_vpc.main.id
    egress {
        protocol   = "-1"
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port = 0
        to_port = 0
    }

    ingress {
        protocol   = "tcp"
        rule_no    = 101
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 443
        to_port    = 443
    }

}

resource "aws_network_acl_association" "public-subnets-nacl-association-1a" {
    network_acl_id = aws_network_acl.public-subnets-nacl.id
    subnet_id = aws_subnet.public-1a.id
  
}

# resource "aws_network_acl_association" "public-subnets-nacl-association-1b" {
#     network_acl_id = aws_network_acl.public-subnets-nacl.id
#     subnet_id = aws_subnet.public-1b.id
  
# }

# resource "aws_network_acl_association" "public-subnets-nacl-association-1c" {
#     network_acl_id = aws_network_acl.public-subnets-nacl.id
#     subnet_id = aws_subnet.public-1c.id
  
# }


## DMZ and Private Subnets 
resource "aws_subnet" "dmz-1a" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.160.0/20"
    availability_zone_id = element(var.azs, 0)
    tags = merge(var.tags)      
    
}

# resource "aws_subnet" "dmz-1b" {
#     vpc_id = aws_vpc.main.id
#     cidr_block = "10.0.176.0/20"
#     availability_zone_id = element(var.azs, 1)
#     tags = merge(var.tags)      

# }

# resource "aws_subnet" "dmz-1c" {
#     vpc_id = aws_vpc.main.id
#     cidr_block = "10.0.192.0/20"
#     availability_zone_id = element(var.azs, 2)
#     tags = merge(var.tags)      
# }

resource "aws_subnet" "private-1a" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.32.0/20"
    availability_zone_id = element(var.azs, 0)
    tags = merge(var.tags)      
    
}

# resource "aws_subnet" "private-1b" {
#     vpc_id = aws_vpc.main.id
#     cidr_block = "10.0.80.0/20"
#     availability_zone_id = element(var.azs, 1)
#     tags = merge(var.tags)     

# }

# resource "aws_subnet" "private-1c" {
#     vpc_id = aws_vpc.main.id
#     cidr_block = "10.0.128.0/20"
#     availability_zone_id = element(var.azs, 2)
#     tags = merge(var.tags)      
# }

#isolated Subnets

resource "aws_subnet" "isolated-1a" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.48.0/20"
    availability_zone_id = element(var.azs, 0)
    tags = merge(var.tags)      
    
}

# resource "aws_subnet" "isolated-1b" {
#     vpc_id = aws_vpc.main.id
#     cidr_block = "10.0.96.0/20"
#     availability_zone_id = element(var.azs, 1)
#     tags = merge(var.tags)     

# }

# resource "aws_subnet" "isolated-1c" {
#     vpc_id = aws_vpc.main.id
#     cidr_block = "10.0.144.0/20"
#     availability_zone_id = element(var.azs, 2)
#     tags = merge(var.tags)      
# }



resource "aws_eip" "nat_ip" {
    tags = merge(var.tags)      
    
}


resource "aws_nat_gateway" "nat-gw" {
    subnet_id = aws_subnet.public-1a.id
    allocation_id = aws_eip.nat_ip.id
}

resource "aws_route_table" "private-rtb" {
    vpc_id = aws_vpc.main.id
}

resource "aws_route" "private-rtb-outbound" {
    route_table_id = aws_route_table.private-rtb.id
    destination_cidr_block = "0.0.0.0/0" 
    nat_gateway_id = aws_nat_gateway.nat-gw.id
}


resource "aws_route_table" "isolated-rtb" {
    vpc_id = aws_vpc.main.id
}

resource "aws_route" "isolated-rtb-outbound" {
    route_table_id = aws_route_table.isolated-rtb.id
}


resource "aws_route_table_association" "private-rtb-subnet-association-1a" {
    subnet_id = aws_subnet.private-1a.id
    route_table_id = aws_route_table.private-rtb.id
}

# resource "aws_route_table_association" "private-rtb-subnet-association-1b" {
#     subnet_id = aws_subnet.private-1b.id
#     route_table_id = aws_route_table.private-rtb.id
# }

# resource "aws_route_table_association" "private-rtb-subnet-association-1c" {
#     subnet_id = aws_subnet.isolated-1c.id
#     route_table_id = aws_route_table.isolated-rtb.id
# }

resource "aws_route_table_association" "isolated-rtb-subnet-association-1a" {
    subnet_id = aws_subnet.isolated-1a.id
    route_table_id = aws_route_table.isolated-rtb.id
}

# resource "aws_route_table_association" "isolated-rtb-subnet-association-1b" {
#     subnet_id = aws_subnet.isolated-1b.id
#     route_table_id = aws_route_table.isolated-rtb.id
# }

# resource "aws_route_table_association" "isolated-rtb-subnet-association-1c" {
#     subnet_id = aws_subnet.isolated-1c.id
#     route_table_id = aws_route_table.isolated-rtb.id
# }

resource "aws_route_table" "dmz-rtb" {
    vpc_id = aws_vpc.main.id
}

resource "aws_route" "dmz-rtb-outbound" {
    route_table_id = aws_route_table.dmz-rtb.id
    destination_cidr_block = "0.0.0.0/0" 
    nat_gateway_id = aws_nat_gateway.nat-gw.id
}

resource "aws_route_table_association" "dmz-rtb-subnet-association-1a" {
    subnet_id = aws_subnet.dmz-1a.id
    route_table_id = aws_route_table.dmz-rtb.id
}

# resource "aws_route_table_association" "dmz-rtb-subnet-association-1b" {
#     subnet_id = aws_subnet.dmz-1b.id
#     route_table_id = aws_route_table.dmz-rtb.id
# }

# resource "aws_route_table_association" "dmz-rtb-subnet-association-1c" {
#     subnet_id = aws_subnet.dmz-1c.id
#     route_table_id = aws_route_table.dmz-rtb.id
# }

## Setup Internal LB


resource "aws_security_group" "lb-sg" {
  vpc_id = aws_vpc.main.id

}

resource "aws_vpc_security_group_egress_rule" "lb-sg-allow-all" {

  security_group_id = aws_security_group.lb-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_ingress_rule" "lb-sg-allow-80" {

  security_group_id = aws_security_group.lb-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port = "443"
  to_port = "443"
}



resource "aws_vpc_security_group_ingress_rule" "lb-sg-allow-443" {

  security_group_id = aws_security_group.lb-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port = "80"
  to_port = "80"
}

resource "aws_lb" "private-nlb" {
  name               = "private-nlb"
  internal           = true
  load_balancer_type = "network"
    subnet_mapping {
        subnet_id = aws_subnet.private-1a.id
        private_ipv4_address = local.private_nlb_ip
    }
  enable_deletion_protection = false
  tags = var.tags
  security_groups = [ aws_security_group.lb-sg.id ]
}

resource "aws_lb_target_group" "eks-target-group" {
  name        = "eks-nlb-target-group"
  port        = 80
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id
}

resource "aws_lb_listener" "private-nlb-listener" {
  load_balancer_arn = aws_lb.private-nlb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.eks-target-group.arn
  }
}

## Setup External LB
resource "aws_eip" "nlb_eip" {
    tags = var.tags
}

resource "aws_lb" "public-nlb" {
  name               = "public-nlb"
  internal           = false
  load_balancer_type = "network"
#   subnets            = [aws_subnet.public-1a.id]
    subnet_mapping {
        subnet_id = aws_subnet.public-1a.id
        allocation_id = aws_eip.nlb_eip.id
    }
  enable_deletion_protection = false
  tags = var.tags
  security_groups = [ aws_security_group.lb-sg.id ]

}
resource "aws_lb_target_group" "private-nlb-target-group" {
  name        = "private-nlb-target"
  port        = 80
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id
}

resource "aws_lb_target_group_attachment" "private-nlb-registration" {
  target_group_arn = aws_lb_target_group.private-nlb-target-group.arn
  target_id        = local.private_nlb_ip
  port             = 80
}

resource "aws_lb_listener" "public-nlb-listener" {
  load_balancer_arn = aws_lb.public-nlb.arn
  port              = "80"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.private-nlb-target-group.arn
  }
}