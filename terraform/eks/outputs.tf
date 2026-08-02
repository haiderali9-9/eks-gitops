output "eks_cluster_role_arn" {
  description = "EKS cluster IAM role ARN"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_cluster_role_name" {
  description = "EKS cluster IAM role name"
  value       = aws_iam_role.eks_cluster.name
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.this.name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "eks_cluster_log_group_name" {
  description = "EKS cluster CloudWatch log group name"
  value       = aws_cloudwatch_log_group.eks_cluster.name
}

output "cluster_admin_iam_arn" {
  description = "IAM user or role ARN with EKS cluster administrator access"
  value       = var.cluster_admin_iam_arn
}
