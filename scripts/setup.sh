#!/bin/bash

# スクリプトが失敗した場合即座に終了
set -e

echo "🚀 SRE環境のセットアップを開始します..."

# Dockerグループ権限のチェックと設定
check_docker_permissions() {
    echo "📝 Dockerの権限を確認しています..."
    if ! groups | grep -q docker; then
        echo "📝 Dockerグループに権限を追加しています..."
        echo ubuntu | sudo -S usermod -aG docker ubuntu
        echo "✅ Dockerグループに追加しました。新しいシェルセッションを開始します..."
        exec newgrp docker
    else
        echo "✅ Dockerの権限は正しく設定されています"
    fi
}

# 必要なツールのバージョンチェック
check_tool_version() {
    local tool=$1
    local min_version=$2
    local version_cmd=$3
    
    echo "📝 ${tool}のバージョンを確認しています..."
    if ! command -v $tool &> /dev/null; then
        echo "❌ ${tool}がインストールされていません"
        exit 1
    fi
    
    local version=$(eval $version_cmd)
    echo "✓ ${tool} version: ${version}"
}

# kindクラスタの存在確認
check_kind_cluster() {
    local cluster_name=$1
    if ! kind get clusters | grep -q "^${cluster_name}$"; then
        echo "❌ kindクラスタ '${cluster_name}' が見つかりません"
        return 1
    fi
    return 0
}

# メイン処理の開始
check_docker_permissions

# 必要なツールのバージョンチェック
check_tool_version "docker" "20.10" "docker --version | cut -d' ' -f3 | tr -d ','"
check_tool_version "kubectl" "1.20" "kubectl version --client -o json | jq -r '.clientVersion.gitVersion'"
check_tool_version "helm" "3.0.0" "helm version --short | cut -d'+' -f1"
# check_tool_version "terraform" "1.0.0" "terraform version | head -n1 | cut -d'v' -f2"

# kindクラスターのセットアップ
echo "📝 kindクラスターをセットアップしています..."
bash kubernetes/kind/setup.sh

# 監視スタックのセットアップ
echo "📝 監視スタックをセットアップしています..."
bash kubernetes/kind/setup-monitoring.sh

# サンプルアプリケーションのデプロイ
echo "📝 サンプルアプリケーションをデプロイしています..."

# 現在のディレクトリを保存
CURRENT_DIR=$(pwd)

# サンプルアプリケーションのディレクトリに移動
cd sample-app || exit 1

# Dockerイメージのビルド
echo "📝 Dockerイメージをビルドしています..."
if ! docker build -t sample-app:latest .; then
    echo "❌ Dockerイメージのビルドに失敗しました"
    exit 1
fi

# kindクラスタの確認
if check_kind_cluster "sre-dev"; then
    echo "📝 kindクラスタにイメージをロードしています..."
    if ! kind load docker-image sample-app:latest --name sre-dev; then
        echo "❌ イメージのロードに失敗しました"
        exit 1
    fi

    # マニフェストのデプロイ
    echo "📝 Kubernetesマニフェストを適用しています..."
    cd "$CURRENT_DIR" || exit 1
    if ! kubectl apply -f kubernetes/manifests/sample-app/deployment.yaml; then
        echo "❌ マニフェストの適用に失敗しました"
        exit 1
    fi

    # デプロイメントの準備完了を待機
    echo "📝 アプリケーションの準備ができるまで待機しています..."
    if ! kubectl wait --namespace microservices \
        --for=condition=ready pod \
        --selector=app=sample-app \
        --timeout=180s; then
        echo "❌ アプリケーションの準備がタイムアウトしました"
        exit 1
    fi

    # 負荷テストの実行（オプション）
    echo "📝 負荷テストを実行しています..."
    cd "$CURRENT_DIR" || exit 1
    bash kubernetes/manifests/sample-app/load-test.sh &
else
    echo "❌ kindクラスタが見つかりません。セットアップを中止します。"
    exit 1
fi

# 元のディレクトリに戻る
cd $CURRENT_DIR

echo "✅ セットアップが完了しました！"

# クラスタの状態を表示
echo "🔍 クラスターの状態を確認しています..."
kubectl get nodes -o wide
echo
kubectl get pods -A

# 最後にアクセス情報を表示
echo "
📊 アクセス情報:
--------------------
Prometheus:
  URL: http://localhost:30000

Grafana:
  URL: http://localhost:30001
  ユーザー名: admin
  パスワード: strongpassword

サンプルアプリケーション:
  URL: http://localhost:30002
--------------------" 