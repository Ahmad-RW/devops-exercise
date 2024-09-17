locals {
  region         = "us-east-1"
  name           = "network-firewall-ex-${basename(path.cwd)}"
  account_id     = data.aws_caller_identity.current.account_id
  private_nlb_ip = "10.0.32.32"
  cluster_name   = "devops-exercise"
  repo_url       = "ssh://git@github.com/Ahmad-RW/devops-exercise.git"
}


resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags       = merge(var.tags)
}

data "aws_caller_identity" "current" {}




## Public subnet
resource "aws_subnet" "public-1a" {
  vpc_id               = aws_vpc.main.id
  cidr_block           = "10.0.16.0/20"
  availability_zone_id = element(var.azs, 0)
  tags = merge({
    Name = "public-1a"
  }, var.tags)

}

# # resource "aws_subnet" "public-1b" {
# #     vpc_id = aws_vpc.main.id
# #     cidr_block = "10.0.64.0/20"
# #     availability_zone_id = element(var.azs, 1)
# #     tags = merge(var.tags)      

# # }

# # resource "aws_subnet" "public-1c" {
# #     vpc_id = aws_vpc.main.id
# #     cidr_block = "10.0.112.0/20"
# #     availability_zone_id = element(var.azs, 2)
# #     tags = merge(var.tags)      
# # }

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags)
}

resource "aws_route_table" "public-rtb" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "outbound" {
  route_table_id         = aws_route_table.public-rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public-rtb-subnet-association-1a" {
  subnet_id      = aws_subnet.public-1a.id
  route_table_id = aws_route_table.public-rtb.id
}

# # resource "aws_route_table_association" "public-rtb-subnet-association-1b" {
# #     subnet_id = aws_subnet.public-1b.id
# #     route_table_id = aws_route_table.public-rtb.id
# # }

# # resource "aws_route_table_association" "public-rtb-subnet-association-1c" {
# #     subnet_id = aws_subnet.public-1c.id
# #     route_table_id = aws_route_table.public-rtb.id
# # }

resource "aws_network_acl" "public-subnets-nacl" {
  vpc_id = aws_vpc.main.id
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol        = "-1"
    rule_no         = 101
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol        = "-1"
    rule_no         = 101
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }

}

resource "aws_network_acl_association" "public-subnets-nacl-association-1a" {
  network_acl_id = aws_network_acl.public-subnets-nacl.id
  subnet_id      = aws_subnet.public-1a.id

}

# # resource "aws_network_acl_association" "public-subnets-nacl-association-1b" {
# #     network_acl_id = aws_network_acl.public-subnets-nacl.id
# #     subnet_id = aws_subnet.public-1b.id

# # }

# # resource "aws_network_acl_association" "public-subnets-nacl-association-1c" {
# #     network_acl_id = aws_network_acl.public-subnets-nacl.id
# #     subnet_id = aws_subnet.public-1c.id

# # }


## DMZ and Private Subnets 

resource "aws_eip" "nat_ip" {
  tags = merge(var.tags)

}


resource "aws_nat_gateway" "nat-gw" {
  subnet_id     = aws_subnet.public-1a.id
  allocation_id = aws_eip.nat_ip.id
}



resource "aws_subnet" "dmz-1a" {
  vpc_id               = aws_vpc.main.id
  cidr_block           = "10.0.160.0/20"
  availability_zone_id = element(var.azs, 0)
  tags = merge({
    Name = "dmz-1a"
  }, var.tags)

}


resource "aws_subnet" "private-1a" {
  vpc_id               = aws_vpc.main.id
  cidr_block           = "10.0.32.0/20"
  availability_zone_id = element(var.azs, 0)
  tags = merge({
    Name = "private-1a"
  }, var.tags)

}

resource "aws_subnet" "private-1b" {
  vpc_id               = aws_vpc.main.id
  cidr_block           = "10.0.80.0/20"
  availability_zone_id = element(var.azs, 1)
  tags = merge({
    Name = "private-1b"
  }, var.tags)

}

resource "aws_route_table" "private-rtb" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "private-rtb-outbound" {
  route_table_id         = aws_route_table.private-rtb.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat-gw.id
}

resource "aws_route_table_association" "private-rtb-subnet-association-1a" {
  subnet_id      = aws_subnet.private-1a.id
  route_table_id = aws_route_table.private-rtb.id
}

resource "aws_route_table_association" "private-rtb-subnet-association-1b" {
  subnet_id      = aws_subnet.private-1b.id
  route_table_id = aws_route_table.private-rtb.id
}


resource "aws_network_acl" "private-subnets-nacl" {
  vpc_id = aws_vpc.main.id
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol        = "-1"
    rule_no         = 101
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol        = "-1"
    rule_no         = 101
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }

}

resource "aws_network_acl_association" "private-subnets-nacl-association-1a" {
  network_acl_id = aws_network_acl.private-subnets-nacl.id
  subnet_id      = aws_subnet.private-1a.id
}


resource "aws_network_acl_association" "private-subnets-nacl-association-1b" {
  network_acl_id = aws_network_acl.private-subnets-nacl.id
  subnet_id      = aws_subnet.private-1b.id
}


# # resource "aws_subnet" "private-1c" {
# #     vpc_id = aws_vpc.main.id
# #     cidr_block = "10.0.128.0/20"
# #     availability_zone_id = element(var.azs, 2)
# #     tags = merge(var.tags)      
# # }

# #isolated Subnets

resource "aws_subnet" "isolated-1a" {
  vpc_id               = aws_vpc.main.id
  cidr_block           = "10.0.48.0/20"
  availability_zone_id = element(var.azs, 0)
  tags = merge({
    Name = "isolated-1a"
  }, var.tags)

}




resource "aws_route_table" "isolated-rtb" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table_association" "isolated-rtb-subnet-association-1a" {
  subnet_id      = aws_subnet.isolated-1a.id
  route_table_id = aws_route_table.isolated-rtb.id
}

# # resource "aws_route_table_association" "private-rtb-subnet-association-1c" {
# #     subnet_id = aws_subnet.isolated-1c.id
# #     route_table_id = aws_route_table.isolated-rtb.id
# # }


# # resource "aws_route_table_association" "isolated-rtb-subnet-association-1b" {
# #     subnet_id = aws_subnet.isolated-1b.id
# #     route_table_id = aws_route_table.isolated-rtb.id
# # }

# # resource "aws_route_table_association" "isolated-rtb-subnet-association-1c" {
# #     subnet_id = aws_subnet.isolated-1c.id
# #     route_table_id = aws_route_table.isolated-rtb.id
# # }

resource "aws_route_table" "dmz-rtb" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "dmz-rtb-outbound" {
  route_table_id         = aws_route_table.dmz-rtb.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat-gw.id
}

resource "aws_route_table_association" "dmz-rtb-subnet-association-1a" {
  subnet_id      = aws_subnet.dmz-1a.id
  route_table_id = aws_route_table.dmz-rtb.id
}

# # resource "aws_route_table_association" "dmz-rtb-subnet-association-1b" {
# #     subnet_id = aws_subnet.dmz-1b.id
# #     route_table_id = aws_route_table.dmz-rtb.id
# # }

# # resource "aws_route_table_association" "dmz-rtb-subnet-association-1c" {
# #     subnet_id = aws_subnet.dmz-1c.id
# #     route_table_id = aws_route_table.dmz-rtb.id
# # }

# ## Setup Internal LB


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
  from_port         = "80"
  to_port           = "80"
}



resource "aws_vpc_security_group_ingress_rule" "lb-sg-allow-443" {

  security_group_id = aws_security_group.lb-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = "443"
  to_port           = "443"
}

# # resource "aws_lb" "private-nlb" {
# #   name               = "private-nlb"
# #   internal           = true
# #   load_balancer_type = "network"
# #     subnet_mapping {
# #         subnet_id = aws_subnet.private-1a.id
# #         private_ipv4_address = local.private_nlb_ip
# #     }
# #   enable_deletion_protection = false
# #   tags = var.tags
# #   security_groups = [ aws_security_group.lb-sg.id ]
# # }

# # resource "aws_lb_target_group" "eks-target-group" {
# #   name        = "eks-nlb-target-group"
# #   port        = 80
# #   protocol    = "TCP"
# #   target_type = "instance"
# #   vpc_id      = aws_vpc.main.id
# # }

# # resource "aws_lb_listener" "private-nlb-listener" {
# #   load_balancer_arn = aws_lb.private-nlb.arn
# #   port              = "80"
# #   protocol          = "TCP"

# #   default_action {
# #     type             = "forward"
# #     target_group_arn = aws_lb_target_group.eks-target-group.arn
# #   }
# # }

# # ## Setup External LB

# # resource "aws_eip" "nlb_eip" {
# #     tags = var.tags
# # }

# # resource "aws_lb" "public-nlb" {
# #   name               = "public-nlb"
# #   internal           = false
# #   load_balancer_type = "network"
# # #   subnets            = [aws_subnet.public-1a.id]
# #     subnet_mapping {
# #         subnet_id = aws_subnet.public-1a.id
# #         allocation_id = aws_eip.nlb_eip.id
# #     }
# #   enable_deletion_protection = false
# #   tags = var.tags
# #   security_groups = [ aws_security_group.lb-sg.id ]

# # }
# # resource "aws_lb_target_group" "private-nlb-target-group" {
# #   name        = "private-nlb-target"
# #   port        = 80
# #   protocol    = "TCP"
# #   target_type = "ip"
# #   vpc_id      = aws_vpc.main.id
# # }

# # resource "aws_lb_target_group_attachment" "private-nlb-registration" {
# #   target_group_arn = aws_lb_target_group.private-nlb-target-group.arn
# #   target_id        = local.private_nlb_ip
# #   port             = 80
# # }

# # resource "aws_lb_listener" "public-nlb-listener" {
# #   load_balancer_arn = aws_lb.public-nlb.arn
# #   port              = "80"
# #   protocol          = "TCP"
# #   default_action {
# #     type             = "forward"
# #     target_group_arn = aws_lb_target_group.private-nlb-target-group.arn
# #   }
# # }

# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "19.15.1"

#   cluster_name                   = "devops-exercise"
#   cluster_endpoint_public_access = true

#   cluster_addons = {
#     coredns = {
#       most_recent = true
#     }
#     kube-proxy = {
#       most_recent = true
#     }
#     vpc-cni = {
#       most_recent = true
#     }
#   }

#   vpc_id                   = aws_vpc.main.id
#   subnet_ids               = [aws_subnet.private-1a.id, aws_subnet.private-1b.id]
#   control_plane_subnet_ids = [aws_subnet.private-1a.id, aws_subnet.private-1b.id]

#   # EKS Managed Node Group(s)
#   eks_managed_node_group_defaults = {
#     ami_type       = "AL2_x86_64"
#     instance_types = ["t3.small"]

#     attach_cluster_primary_security_group = true
#   }

#   eks_managed_node_groups = {
#     ng3 = {
#       min_size     = 1
#       max_size     = 2
#       desired_size = 1

#       instance_types = ["t3.small"]

#     }
#   }
# }



####### TEST

# locals {
#   name   = "ascode-cluster"
#   region = "us-east-1"

#   vpc_cidr = "10.123.0.0/16"
#   azs      = ["us-east-1a", "us-east-1b"]

#   public_subnets  = ["10.123.1.0/24", "10.123.2.0/24"]
#   private_subnets = ["10.123.3.0/24", "10.123.4.0/24"]
#   intra_subnets   = ["10.123.5.0/24", "10.123.6.0/24"]

#   tags = {
#     Example = local.name
#   }
# }

# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "~> 4.0"

#   name = "test"
#   cidr = "10.123.0.0/16"

#   azs             = ["us-east-1a", "us-east-1b"]
#   private_subnets = ["10.123.1.0/24", "10.123.2.0/24"]
#   public_subnets  = ["10.123.3.0/24", "10.123.4.0/24"]
#   intra_subnets   = ["10.123.5.0/24", "10.123.6.0/24"]

#   enable_nat_gateway = true

#   # public_subnet_tags = {
#   #   "kubernetes.io/role/elb" = 1
#   # }

#   # private_subnet_tags = {
#   #   "kubernetes.io/role/internal-elb" = 1
#   # }
# }

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.1"

  cluster_name                   = local.cluster_name
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = aws_vpc.main.id
  subnet_ids               = [aws_subnet.private-1a.id, aws_subnet.private-1b.id]
  control_plane_subnet_ids = [aws_subnet.private-1a.id, aws_subnet.private-1b.id]

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["m5.large"]

    attach_cluster_primary_security_group = true
  }

  eks_managed_node_groups = {
    ng-1 = {
      min_size     = 1
      max_size     = 2
      desired_size = 2

      instance_types = ["t3.large"]
    }
  }
}


resource "kubernetes_namespace" "flux_system" {
  metadata {
    name = "flux-system"
  }
}

resource "helm_release" "flux2" {
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2"
  version    = "2.12.4"

  name      = "flux2"
  namespace = "flux-system"

  depends_on = [kubernetes_namespace.flux_system]
}

resource "kubernetes_secret" "ssh_keypair" {
  metadata {
    name      = "ssh-keypair"
    namespace = "flux-system"
  }

  type = "Opaque"

  data = {
    "identity.pub" = var.public_key
    "identity"     = var.private_key_pem
    "known_hosts"  = "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg="
  }

  depends_on = [kubernetes_namespace.flux_system]
}

resource "helm_release" "flux2_sync" {
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2-sync"
  version    = "1.8.2"

  # Note: Do not change the name or namespace of this resource. The below mimics the behaviour of "flux bootstrap".
  name      = "flux-system"
  namespace = "flux-system"

  set {
    name  = "gitRepository.spec.url"
    value = local.repo_url
  }

  set {
    name  = "gitRepository.spec.ref.branch"
    value = "main"
  }

  set {
    name  = "gitRepository.spec.secretRef.name"
    value = kubernetes_secret.ssh_keypair.metadata[0].name
  }

  set {
    name  = "gitRepository.spec.interval"
    value = "1m"
  }

  depends_on = [helm_release.flux2]
}