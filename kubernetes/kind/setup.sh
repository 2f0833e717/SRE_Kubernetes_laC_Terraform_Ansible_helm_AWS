#!/bin/bash

# スクリプトが失敗した場合即座に終了
set -e

echo "🚀 SRE開発環境のセットアップを開始します..."

# 既存のクラスターを削除（存在する場合）
if kind get clusters | grep -q "sre-dev"; then
    echo "📝 既存のクラスターを削除しています..."
    kind delete cluster --name sre-dev
fi

# 新しいクラスターを作成
echo "📝 新しいクラスターを作成しています..."
if ! kind create cluster --config kubernetes/kind/config.yaml; then
    echo "❌ クラスターの作成に失敗しました"
    exit 1
fi

# クラスター情報の取得を待機
echo "📝 クラスターの準備ができるまで待機しています..."
if ! kubectl wait --for=condition=Ready nodes --all --timeout=300s; then
    echo "❌ クラスターの準備がタイムアウトしました"
    exit 1
fi

# 必要な名前空間を作成
echo "📝 名前空間を作成しています..."
if ! kubectl apply -f kubernetes/manifests/namespace.yaml; then
    echo "❌ 名前空間の作成に失敗しました"
    exit 1
fi

# Ingressコントローラーのインストール
echo "📝 Nginx Ingressコントローラーをインストールしています..."
if ! kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml; then
    echo "❌ Ingressコントローラーのインストールに失敗しました"
    exit 1
fi

# Ingressコントローラーの準備ができるまで待機（リトライ付き）
echo "📝 Ingressコントローラーの準備ができるまで待機しています..."
max_retries=3
retry_count=0
while [ $retry_count -lt $max_retries ]; do
    if kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=300s; then
        break
    fi
    retry_count=$((retry_count + 1))
    if [ $retry_count -lt $max_retries ]; then
        echo "📝 Ingressコントローラーの準備を再試行しています... (試行 $retry_count/$max_retries)"
        sleep 30
    else
        echo "❌ Ingressコントローラーの準備が最大試行回数を超えました"
        exit 1
    fi
done

# Ingressコントローラーの状態を確認
echo "📝 Ingressコントローラーの状態を確認しています..."
kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller

echo "✅ セットアップが完了しました！"
echo "🔍 クラスターの状態を確認しています..."
kubectl get nodes -o wide
echo
kubectl get pods -A 