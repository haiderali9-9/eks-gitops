variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs used by the EKS cluster"
  type        = list(string)
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to access the EKS public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_admin_iam_arn" {
  description = "IAM user or role ARN that gets EKS cluster administrator access"
  type        = string
}
