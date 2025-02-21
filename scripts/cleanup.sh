#!/bin/bash

# スクリプトが失敗した場合即座に終了
set -e

echo "🧹 クリーンアップを開始します..."

# 実行中のプロセスの終了
echo "📝 負荷テストプロセスを終了しています..."
pkill -f "load-test.sh" || true

# kindクラスターの削除
echo "📝 kindクラスターを削除しています..."
if kind get clusters | grep -q "sre-dev"; then
    kind delete cluster --name sre-dev
fi

# Dockerコンテナとイメージのクリーンアップ
echo "📝 未使用のDockerリソースを削除しています..."
docker container prune -f
docker image rm sample-app:latest || true

echo "✅ クリーンアップが完了しました！" 