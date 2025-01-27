variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}


variable "tags" {
  type = map(string)
  default = {
    "created-by"  = "tf"
    "managed-by"  = "tf"
    "environment" = "exercise"
  }
}



/*
id ==> region name
use1-az6 ==> us-east-1a
use1-az1 ==> us-east-1b
use1-az2 ==> us-east-1c
*/
variable "azs" {
  description = "availability zones"
  type        = list(string)
  default     = ["use1-az6", "use1-az1", "use1-az2"]
}


variable "private_key_pem" {
  description = "github deploy private key"
  sensitive   = true
  type        = string
  default     = ""
}


variable "public_key" {
  description = "github deploy private key"
  sensitive   = false
  type        = string
  default     = ""
}

variable "network-vpce" {
  description = "endpoint for aws network firewall endpoint to route traffic to"
  sensitive   = false
  type        = string
  default     = ""
}