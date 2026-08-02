variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "Name to tag the VPC and its resources with"
  type        = string
  default     = "main-vpc"
}

variable "azs" {
  description = "List of Availability Zones to spread subnets across (e.g. [\"us-east-1a\", \"us-east-1b\"])"
  type        = list(string)
}

variable "eks_cluster_name" {
  description = "EKS cluster name used for Kubernetes subnet discovery tags"
  type        = string
}

variable "public_subnets" {
  description = "List of CIDR blocks for public subnets. Must be same length as var.azs (index i -> azs[i])."
  type        = list(string)
}

variable "private_subnets" {
  description = "List of CIDR blocks for private subnets. Must be same length as var.azs (index i -> azs[i])."
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT gateways for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "If true, creates only ONE NAT gateway (in the first AZ) shared by all private subnets, instead of one per AZ. Cheaper but not highly available."
  type        = bool
  default     = false
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "map_public_ip_on_launch" {
  description = "Auto-assign public IPs to instances launched in public subnets"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
