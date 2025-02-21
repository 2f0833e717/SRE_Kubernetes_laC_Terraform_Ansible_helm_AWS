variable "cluster_name" {
  description = "EKSクラスタの名前"
  type        = string
}

variable "environment" {
  description = "環境名（dev/stg/prod）"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetesのバージョン"
  type        = string
  default     = "1.24"
}

variable "vpc_id" {
  description = "EKSクラスタを作成するVPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "EKSクラスタを作成するサブネットIDのリスト"
  type        = list(string)
}

variable "enable_public_access" {
  description = "パブリックエンドポイントへのアクセスを有効にするかどうか"
  type        = bool
  default     = false
}

variable "node_desired_size" {
  description = "ノードグループの希望するノード数"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "ノードグループの最大ノード数"
  type        = number
  default     = 4
}

variable "node_min_size" {
  description = "ノードグループの最小ノード数"
  type        = number
  default     = 1
}

variable "node_instance_types" {
  description = "ノードグループで使用するインスタンスタイプのリスト"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "tags" {
  description = "リソースに付与する追加のタグ"
  type        = map(string)
  default     = {}
} 