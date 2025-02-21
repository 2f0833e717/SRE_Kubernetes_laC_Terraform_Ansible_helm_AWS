#!/bin/bash

# スクリプトが失敗した場合即座に終了
set -e

echo "🚀 監視スタックのセットアップを開始します..."

# Helm repoの追加と更新
echo "📝 Helm repositoryを更新しています..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Prometheusのインストール
echo "📝 Prometheusをインストールしています..."
helm upgrade --install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --values kubernetes/helm/monitoring/prometheus-values.yaml \
  --wait

# Grafanaのインストール
echo "📝 Grafanaをインストールしています..."
helm upgrade --install grafana grafana/grafana \
  --namespace monitoring \
  --values kubernetes/helm/monitoring/grafana-values.yaml \
  --wait

# デプロイされたリソースの確認
echo "🔍 デプロイされたリソースを確認しています..."
kubectl get pods,svc,daemonset,deployment,replicaset,statefulset -n monitoring

echo "✅ 監視スタックのセットアップが完了しました！" 