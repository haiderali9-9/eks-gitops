variable "europe" {
  description = "Europe VPC configuration"
  type = object({
    region                = string
    vpc_name              = string
    vpc_cidr              = string
    public_subnets        = list(string)
    private_subnets       = list(string)
    availability_zones    = list(string)
    eks_cluster_name      = string
    cluster_admin_iam_arn = string
  })
}

variable "us_east" {
  description = "US East VPC and EKS configuration"
  type = object({
    region                = string
    vpc_name              = string
    vpc_cidr              = string
    public_subnets        = list(string)
    private_subnets       = list(string)
    availability_zones    = list(string)
    eks_cluster_name      = string
    cluster_admin_iam_arn = string
  })
}
