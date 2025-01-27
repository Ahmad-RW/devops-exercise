locals {
  region       = "us-east-1"
  name         = "network-firewall-ex-${basename(path.cwd)}"
  account_id   = data.aws_caller_identity.current.account_id
  cluster_name = "devops-exercise"
  repo_url     = "ssh://git@github.com/Ahmad-RW/devops-exercise.git"
  fw_name      = "devOps-exercise-firewall"
}


resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags       = merge(var.tags)
}

data "aws_caller_identity" "current" {}

## Internet Gateway 

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags)
}

resource "aws_route_table" "igw-rtb" {
  vpc_id = aws_vpc.main.id
}


resource "aws_route_table_association" "b" {
  gateway_id     = aws_internet_gateway.igw.id
  route_table_id = aws_route_table.igw-rtb.id
}

## NAT Gateway 

resource "aws_eip" "nat_ip" {
  tags = merge(var.tags)
}


resource "aws_nat_gateway" "nat-gw" {
  subnet_id     = aws_subnet.public-1a.id
  allocation_id = aws_eip.nat_ip.id
}


## Public subnet
resource "aws_subnet" "public-1a" {
  vpc_id               = aws_vpc.main.id
  cidr_block           = "10.0.16.0/20"
  availability_zone_id = element(var.azs, 0)
  tags = merge({
    Name                     = "public-1a",
    "kubernetes.io/role/elb" = "1"
  }, var.tags)

}

resource "aws_route_table" "public-rtb" {
  vpc_id = aws_vpc.main.id
}
resource "aws_route" "outbound" {
  route_table_id         = aws_route_table.public-rtb.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = tolist(element(module.network_firewall.status, 1).sync_states)[0].attachment[0].endpoint_id
}

resource "aws_route_table_association" "public-rtb-subnet-association-1a" {
  subnet_id      = aws_subnet.public-1a.id
  route_table_id = aws_route_table.public-rtb.id
}

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



## DMZ  


resource "aws_subnet" "dmz-1a" {
  vpc_id               = aws_vpc.main.id
  cidr_block           = "10.0.160.0/20"
  availability_zone_id = element(var.azs, 0)
  tags = merge({
    Name = "dmz-1a"
  }, var.tags)

}

resource "aws_route_table" "dmz-rtb" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "dmz-rtb-outbound" {
  route_table_id         = aws_route_table.dmz-rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id

}

resource "aws_route_table_association" "dmz-rtb-subnet-association-1a" {
  subnet_id      = aws_subnet.dmz-1a.id
  route_table_id = aws_route_table.dmz-rtb.id
}


## Private Subnet

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


resource "aws_route_table_association" "private-rtb-subnet-association-1a" {
  subnet_id      = aws_subnet.private-1a.id
  route_table_id = aws_route_table.private-rtb.id
}


resource "aws_route_table_association" "private-rtb-subnet-association-1b" {
  subnet_id      = aws_subnet.private-1b.id
  route_table_id = aws_route_table.private-rtb.id
}

resource "aws_route" "private-rtb-outbound" {
  route_table_id         = aws_route_table.private-rtb.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat-gw.id
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


## Isolated Subnets

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


## EKS 

module "ebs_csi_controller_role" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.11.1"
  create_role                   = true
  role_name                     = "${local.cluster_name}-ebs-csi-controller"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.ebs_csi_controller.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

resource "aws_iam_policy" "ebs_csi_controller" {
  name_prefix = "ebs-csi-controller"
  description = "EKS ebs-csi-controller policy for cluster ${local.cluster_name}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyVolume",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications",
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:CreateTags"]
        Resource = ["arn:aws:ec2:*:*:volume/*", "arn:aws:ec2:*:*:snapshot/*"]
        Condition = {
          StringEquals = {
            "ec2:CreateAction" : ["CreateVolume", "CreateSnapshot"]
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:DeleteTags"]
        Resource = ["arn:aws:ec2:*:*:volume/*", "arn:aws:ec2:*:*:snapshot/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:CreateVolume"]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:RequestTag/ebs.csi.aws.com/cluster" : "true"
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:CreateVolume"]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:RequestTag/CSIVolumeName" : "*"
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:CreateVolume"]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:RequestTag/kubernetes.io/cluster/*" : "owned"
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:DeleteVolume"]
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/ebs.csi.aws.com/cluster" : "true"
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:DeleteVolume"]
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/CSIVolumeName" : "*"
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:DeleteVolume"]
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/kubernetes.io/cluster/*" : "owned"
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:DeleteSnapshot"]
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/CSIVolumeSnapshotName" : "*"
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:DeleteSnapshot"]
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/ebs.csi.aws.com/cluster" : "true"
          }
        }
      }
  ] })
}

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
    aws-ebs-csi-driver = {
      service_account_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.cluster_name}-ebs-csi-controller"
    }
  }

  vpc_id                   = aws_vpc.main.id
  subnet_ids               = [aws_subnet.private-1a.id, aws_subnet.private-1b.id]
  control_plane_subnet_ids = [aws_subnet.private-1a.id, aws_subnet.private-1b.id]

  ### EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["m5.large"]

    attach_cluster_primary_security_group = true
  }
  node_security_group_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = null
  }
  eks_managed_node_groups = {
    ng-1 = {
      min_size     = 1
      max_size     = 5
      desired_size = 5

      instance_types = ["t3.large"]
      subnet_ids     = [aws_subnet.private-1a.id]
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


## Network Firewall - Amazon Network Firewall


resource "aws_cloudwatch_log_group" "logs" {
  name              = "${local.fw_name}-logs"
  retention_in_days = 1

  tags = var.tags
}

resource "aws_s3_bucket" "network_firewall_logs" {
  bucket        = "devopsexercisefwlogs"
  force_destroy = true

  tags = var.tags
}

### Logging configuration automatically adds this policy if not present
resource "aws_s3_bucket_policy" "network_firewall_logs" {
  bucket = aws_s3_bucket.network_firewall_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "s3:PutObject"
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:logs:${local.region}:${local.account_id}:*"
          }
          StringEquals = {
            "aws:SourceAccount" = local.account_id
            "s3:x-amz-acl"      = "bucket-owner-full-control"
          }
        }
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Resource = "${aws_s3_bucket.network_firewall_logs.arn}/${local.fw_name}/AWSLogs/${local.account_id}/*"
        Sid      = "AWSLogDeliveryWrite"
      },
      {
        Action = "s3:GetBucketAcl"
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:logs:${local.region}:${local.account_id}:*"
          }
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Resource = aws_s3_bucket.network_firewall_logs.arn
        Sid      = "AWSLogDeliveryAclCheck"
      },
    ]
  })
}

module "network_firewall" {
  source = "terraform-aws-modules/network-firewall/aws"

  # Firewall
  name        = local.fw_name
  description = local.fw_name

  # Only for example
  delete_protection                 = false
  firewall_policy_change_protection = false
  subnet_change_protection          = false

  vpc_id = aws_vpc.main.id
  subnet_mapping = {
    subnet-1 = {
      subnet_id = aws_subnet.dmz-1a.id
    }
  }

  # Logging configuration
  create_logging_configuration = true
  logging_configuration_destination_config = [
    {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.logs.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    },
    {
      log_destination = {
        bucketName = aws_s3_bucket.network_firewall_logs.id
        prefix     = local.name
      }
      log_destination_type = "S3"
      log_type             = "FLOW"
    }
  ]

  # Policy
  # policy_name        = local.fw_name
  # policy_description = "Example network firewall policy"

  # policy_stateful_rule_group_reference = {
  #   one = { resource_arn = module.network_firewall_rule_group_stateful.arn }
  # }

  # policy_stateless_default_actions          = ["aws:pass"]
  # policy_stateless_fragment_default_actions = ["aws:drop"]
  # policy_stateless_rule_group_reference = {
  #   one = {
  #     priority     = 1
  #     resource_arn = module.network_firewall_rule_group_stateless.arn
  #   }
  # }

  tags = var.tags
}
