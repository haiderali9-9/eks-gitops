output "europe_vpc_id" {
  description = "Europe VPC ID"
  value       = module.europe_vpc.vpc_id
}

output "us_east_vpc_id" {
  description = "US East VPC ID"
  value       = module.us_east_vpc.vpc_id
}

output "europe_eks_cluster_role_arn" {
  description = "Europe EKS cluster IAM role ARN"
  value       = module.europe_eks.eks_cluster_role_arn
}

output "us_east_eks_cluster_role_arn" {
  description = "Second region EKS cluster IAM role ARN"
  value       = module.us_east_eks.eks_cluster_role_arn
}

output "europe_eks_cluster_endpoint" {
  description = "Europe EKS cluster API endpoint"
  value       = module.europe_eks.eks_cluster_endpoint
}

output "us_east_eks_cluster_endpoint" {
  description = "Second region EKS cluster API endpoint"
  value       = module.us_east_eks.eks_cluster_endpoint
}

output "europe_eks_cluster_log_group_name" {
  description = "Europe EKS cluster CloudWatch log group name"
  value       = module.europe_eks.eks_cluster_log_group_name
}

output "us_east_eks_cluster_log_group_name" {
  description = "Second region EKS cluster CloudWatch log group name"
  value       = module.us_east_eks.eks_cluster_log_group_name
}
