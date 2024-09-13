resource "aws_vpc" "main" {
    cidr_block = var.cidr_block
    tags = merge(var.tags)      
}



## Public subnet
resource "aws_subnet" "public-1a" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.16.0/20"
    availability_zone_id = element(var.azs, 0)
    tags = merge(var.tags)      
    
}

resource "aws_subnet" "public-1b" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.64.0/20"
    availability_zone_id = element(var.azs, 1)
    tags = merge(var.tags)      

}

resource "aws_subnet" "public-1c" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.112.0/20"
    availability_zone_id = element(var.azs, 2)
    tags = merge(var.tags)      
}

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

resource "aws_route_table_association" "public-rtb-subnet-association-1b" {
    subnet_id = aws_subnet.public-1b.id
    route_table_id = aws_route_table.public-rtb.id
}

resource "aws_route_table_association" "public-rtb-subnet-association-1c" {
    subnet_id = aws_subnet.public-1c.id
    route_table_id = aws_route_table.public-rtb.id
}

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

resource "aws_network_acl_association" "public-subnets-nacl-association-1b" {
    network_acl_id = aws_network_acl.public-subnets-nacl.id
    subnet_id = aws_subnet.public-1b.id
  
}

resource "aws_network_acl_association" "public-subnets-nacl-association-1c" {
    network_acl_id = aws_network_acl.public-subnets-nacl.id
    subnet_id = aws_subnet.public-1c.id
  
}


## DMZ and Private Subnets 
resource "aws_subnet" "dmz-1a" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.160.0/20"
    availability_zone_id = element(var.azs, 0)
    tags = merge(var.tags)      
    
}

resource "aws_subnet" "dmz-1b" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.176.0/20"
    availability_zone_id = element(var.azs, 1)
    tags = merge(var.tags)      

}

resource "aws_subnet" "dmz-1c" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.192.0/20"
    availability_zone_id = element(var.azs, 2)
    tags = merge(var.tags)      
}

resource "aws_subnet" "private-1a" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.32.0/20"
    availability_zone_id = element(var.azs, 0)
    tags = merge(var.tags)      
    
}

resource "aws_subnet" "private-1b" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.80.0/20"
    availability_zone_id = element(var.azs, 1)
    tags = merge(var.tags)     

}

resource "aws_subnet" "private-1c" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.128.0/20"
    availability_zone_id = element(var.azs, 2)
    tags = merge(var.tags)      
}

