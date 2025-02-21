# マイクロサービス基盤 トラブルシューティングガイド

## 目次

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [1. 一般的な問題と対処方法](#1-%E4%B8%80%E8%88%AC%E7%9A%84%E3%81%AA%E5%95%8F%E9%A1%8C%E3%81%A8%E5%AF%BE%E5%87%A6%E6%96%B9%E6%B3%95)
  - [1.1 Kubernetes関連](#11-kubernetes%E9%96%A2%E9%80%A3)
    - [Pod起動失敗](#pod%E8%B5%B7%E5%8B%95%E5%A4%B1%E6%95%97)
  - [1.2 EKS関連](#12-eks%E9%96%A2%E9%80%A3)
    - [クラスタ接続問題](#%E3%82%AF%E3%83%A9%E3%82%B9%E3%82%BF%E6%8E%A5%E7%B6%9A%E5%95%8F%E9%A1%8C)
  - [1.3 監視関連](#13-%E7%9B%A3%E8%A6%96%E9%96%A2%E9%80%A3)
    - [Prometheus/Grafana問題](#prometheusgrafana%E5%95%8F%E9%A1%8C)
  - [1.4 ログ収集関連](#14-%E3%83%AD%E3%82%B0%E5%8F%8E%E9%9B%86%E9%96%A2%E9%80%A3)
    - [Elasticsearch/Kibana問題](#elasticsearchkibana%E5%95%8F%E9%A1%8C)
- [2. 高度な問題解決](#2-%E9%AB%98%E5%BA%A6%E3%81%AA%E5%95%8F%E9%A1%8C%E8%A7%A3%E6%B1%BA)
  - [2.1 パフォーマンス問題](#21-%E3%83%91%E3%83%95%E3%82%A9%E3%83%BC%E3%83%9E%E3%83%B3%E3%82%B9%E5%95%8F%E9%A1%8C)
    - [ノードレベル](#%E3%83%8E%E3%83%BC%E3%83%89%E3%83%AC%E3%83%99%E3%83%AB)
    - [アプリケーションレベル](#%E3%82%A2%E3%83%97%E3%83%AA%E3%82%B1%E3%83%BC%E3%82%B7%E3%83%A7%E3%83%B3%E3%83%AC%E3%83%99%E3%83%AB)
  - [2.2 ネットワーク問題](#22-%E3%83%8D%E3%83%83%E3%83%88%E3%83%AF%E3%83%BC%E3%82%AF%E5%95%8F%E9%A1%8C)
    - [サービス接続](#%E3%82%B5%E3%83%BC%E3%83%93%E3%82%B9%E6%8E%A5%E7%B6%9A)
- [3. 予防的メンテナンス](#3-%E4%BA%88%E9%98%B2%E7%9A%84%E3%83%A1%E3%83%B3%E3%83%86%E3%83%8A%E3%83%B3%E3%82%B9)
  - [3.1 定期チェック項目](#31-%E5%AE%9A%E6%9C%9F%E3%83%81%E3%82%A7%E3%83%83%E3%82%AF%E9%A0%85%E7%9B%AE)
  - [3.2 キャパシティプランニング](#32-%E3%82%AD%E3%83%A3%E3%83%91%E3%82%B7%E3%83%86%E3%82%A3%E3%83%97%E3%83%A9%E3%83%B3%E3%83%8B%E3%83%B3%E3%82%B0)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## 1. 一般的な問題と対処方法

### 1.1 Kubernetes関連

#### Pod起動失敗
**症状**
- Podがペンディング状態
- Podがクラッシュループ
- ImagePullBackOff エラー

**確認手順**
```bash
# Podの状態確認
kubectl get pods -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>

# ノードの状態確認
kubectl get nodes
kubectl describe node <node-name>
```

**一般的な原因と対処**
1. リソース不足
   ```bash
   # ノードのリソース使用状況確認
   kubectl top nodes
   kubectl top pods -n <namespace>
   
   # 必要に応じてリソース制限の調整
   kubectl edit deployment <deployment-name> -n <namespace>
   ```

2. イメージプル失敗
   ```bash
   # イメージ名とタグの確認
   kubectl describe pod <pod-name> -n <namespace> | grep Image
   
   # レジストリの認証確認
   kubectl get secret -n <namespace>
   ```

3. 設定エラー
   ```bash
   # ConfigMapとSecretの確認
   kubectl get configmap -n <namespace>
   kubectl get secret -n <namespace>
   ```

### 1.2 EKS関連

#### クラスタ接続問題
**症状**
- kubectlコマンドがタイムアウト
- 認証エラー

**確認手順**
```bash
# クラスタ状態確認
aws eks describe-cluster --name <cluster-name> --region <region>

# IAM認証確認
aws sts get-caller-identity

# kubeconfig更新
aws eks update-kubeconfig --name <cluster-name> --region <region>
```

**一般的な原因と対処**
1. IAMロール/ポリシー問題
   ```bash
   # IAMロールの確認
   aws iam get-role --role-name <role-name>
   
   # ポリシーの確認
   aws iam list-attached-role-policies --role-name <role-name>
   ```

2. セキュリティグループ問題
   ```bash
   # セキュリティグループ確認
   aws ec2 describe-security-groups --group-ids <security-group-id>
   ```

### 1.3 監視関連

#### Prometheus/Grafana問題
**症状**
- メトリクス収集停止
- ダッシュボード表示エラー
- アラート未発報

**確認手順**
```bash
# Prometheusの状態確認
kubectl get pods -n monitoring | grep prometheus
kubectl logs -n monitoring <prometheus-pod>

# Grafanaの状態確認
kubectl get pods -n monitoring | grep grafana
kubectl logs -n monitoring <grafana-pod>
```

**一般的な原因と対処**
1. ストレージ問題
   ```bash
   # PVC確認
   kubectl get pvc -n monitoring
   
   # ストレージ使用量確認
   kubectl exec -it <prometheus-pod> -n monitoring -- df -h
   ```

2. 設定問題
   ```bash
   # ConfigMap確認
   kubectl get configmap -n monitoring
   kubectl describe configmap <configmap-name> -n monitoring
   ```

### 1.4 ログ収集関連

#### Elasticsearch/Kibana問題
**症状**
- ログ収集停止
- クラスタ状態異常
- 検索機能不具合

**確認手順**
```bash
# Elasticsearchの状態確認
kubectl get pods -n logging | grep elasticsearch
curl -X GET "elasticsearch-master:9200/_cluster/health"

# Kibanaの状態確認
kubectl get pods -n logging | grep kibana
kubectl logs -n logging <kibana-pod>
```

**一般的な原因と対処**
1. クラスタ健全性問題
   ```bash
   # シャード状態確認
   curl -X GET "elasticsearch-master:9200/_cat/shards"
   
   # ノード状態確認
   curl -X GET "elasticsearch-master:9200/_cat/nodes"
   ```

2. リソース問題
   ```bash
   # JVM状態確認
   curl -X GET "elasticsearch-master:9200/_nodes/stats/jvm"
   ```

## 2. 高度な問題解決

### 2.1 パフォーマンス問題

#### ノードレベル
**症状**
- 高CPU使用率
- 高メモリ使用率
- 高ディスクI/O

**診断ツール**
```bash
# システムメトリクス確認
kubectl top nodes
kubectl describe node <node-name>

# コンテナメトリクス確認
kubectl top pods -n <namespace>
```

**対処方法**
1. リソース最適化
   ```bash
   # リソース制限の調整
   kubectl edit deployment <deployment-name> -n <namespace>
   
   # HPA設定
   kubectl autoscale deployment <deployment-name> -n <namespace> --min=2 --max=5 --cpu-percent=80
   ```

#### アプリケーションレベル
**症状**
- レスポンス遅延
- タイムアウト
- メモリリーク

**診断ツール**
```bash
# アプリケーションログ確認
kubectl logs <pod-name> -n <namespace>

# コンテナメトリクス詳細
kubectl exec -it <pod-name> -n <namespace> -- top
```

### 2.2 ネットワーク問題

#### サービス接続
**症状**
- サービス間通信エラー
- DNS解決失敗
- ロードバランサー問題

**診断ツール**
```bash
# サービス確認
kubectl get svc -n <namespace>
kubectl describe svc <service-name> -n <namespace>

# エンドポイント確認
kubectl get endpoints <service-name> -n <namespace>
```

**対処方法**
1. DNS問題
   ```bash
   # CoreDNS確認
   kubectl get pods -n kube-system | grep coredns
   kubectl logs -n kube-system <coredns-pod>
   ```

2. ネットワークポリシー
   ```bash
   # ポリシー確認
   kubectl get networkpolicy -n <namespace>
   kubectl describe networkpolicy <policy-name> -n <namespace>
   ```

## 3. 予防的メンテナンス

### 3.1 定期チェック項目
1. リソース使用状況
   ```bash
   # ノードリソース
   kubectl top nodes
   
   # Podリソース
   kubectl top pods -A
   ```

2. バックアップ状態
   ```bash
   # Veleroバックアップ確認
   velero get backup
   
   # Elasticsearchスナップショット確認
   curl -X GET "elasticsearch-master:9200/_snapshot/_all"
   ```

3. セキュリティ更新
   ```bash
   # EKSバージョン確認
   aws eks describe-cluster --name <cluster-name> --query "cluster.version"
   
   # ノードAMI確認
   aws eks describe-nodegroup --cluster-name <cluster-name> --nodegroup-name <nodegroup-name>
   ```

### 3.2 キャパシティプランニング
1. リソース使用傾向分析
   - Prometheusメトリクス確認
   - 成長予測
   - スケーリング計画

2. コスト最適化
   - 未使用リソースの特定
   - リソース制限の最適化
   - スポットインスタンスの活用 