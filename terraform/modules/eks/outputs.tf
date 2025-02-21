output "cluster_id" {
  description = "EKSクラスタのID"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "EKSクラスタのARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "EKSクラスタのエンドポイント"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "EKSクラスタのセキュリティグループID"
  value       = aws_security_group.eks_cluster.id
}

output "cluster_iam_role_name" {
  description = "EKSクラスタのIAMロール名"
  value       = aws_iam_role.eks_cluster.name
}

output "cluster_iam_role_arn" {
  description = "EKSクラスタのIAMロールARN"
  value       = aws_iam_role.eks_cluster.arn
}

output "node_group_id" {
  description = "EKSノードグループのID"
  value       = aws_eks_node_group.main.id
}

output "node_group_arn" {
  description = "EKSノードグループのARN"
  value       = aws_eks_node_group.main.arn
}

output "node_group_role_name" {
  description = "EKSノードグループのIAMロール名"
  value       = aws_iam_role.eks_node_group.name
}

output "node_group_role_arn" {
  description = "EKSノードグループのIAMロールARN"
  value       = aws_iam_role.eks_node_group.arn
}

output "kubeconfig_certificate_authority_data" {
  description = "クラスタへの接続に使用する証明書データ"
  value       = aws_eks_cluster.main.certificate_authority[0].data
} 