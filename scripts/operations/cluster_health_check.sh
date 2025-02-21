#!/bin/bash

# クラスタ健全性チェックスクリプト
# 使用方法: ./cluster_health_check.sh [namespace]

set -e

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 引数チェック
NAMESPACE=${1:-"all"}

echo "=== クラスタ健全性チェック開始 ==="
echo "対象名前空間: ${NAMESPACE}"
echo

# ノード状態チェック
echo "=== ノード状態チェック ==="
kubectl get nodes -o wide
echo

# Pod状態チェック
echo "=== Pod状態チェック ==="
if [ "${NAMESPACE}" = "all" ]; then
    kubectl get pods --all-namespaces | grep -v "Running\|Completed"
else
    kubectl get pods -n "${NAMESPACE}" | grep -v "Running\|Completed"
fi
echo

# リソース使用状況チェック
echo "=== リソース使用状況チェック ==="
echo "--- ノードリソース使用状況 ---"
kubectl top nodes
echo
echo "--- Podリソース使用状況 ---"
if [ "${NAMESPACE}" = "all" ]; then
    kubectl top pods --all-namespaces
else
    kubectl top pods -n "${NAMESPACE}"
fi
echo

# イベントチェック
echo "=== 最近のイベントチェック ==="
if [ "${NAMESPACE}" = "all" ]; then
    kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -n 10
else
    kubectl get events -n "${NAMESPACE}" --sort-by='.lastTimestamp' | tail -n 10
fi
echo

# PVC状態チェック
echo "=== PVC状態チェック ==="
if [ "${NAMESPACE}" = "all" ]; then
    kubectl get pvc --all-namespaces
else
    kubectl get pvc -n "${NAMESPACE}"
fi
echo

# サービス状態チェック
echo "=== サービス状態チェック ==="
if [ "${NAMESPACE}" = "all" ]; then
    kubectl get svc --all-namespaces
else
    kubectl get svc -n "${NAMESPACE}"
fi
echo

# HPA状態チェック
echo "=== HPA状態チェック ==="
if [ "${NAMESPACE}" = "all" ]; then
    kubectl get hpa --all-namespaces
else
    kubectl get hpa -n "${NAMESPACE}"
fi
echo

# 結果の集計
echo "=== 健全性チェック結果 ==="
FAILED_PODS=$(kubectl get pods --all-namespaces | grep -v "Running\|Completed" | wc -l)
if [ "${FAILED_PODS}" -gt 0 ]; then
    echo -e "${RED}警告: ${FAILED_PODS}個の異常Podが検出されました${NC}"
else
    echo -e "${GREEN}正常: すべてのPodが正常に動作しています${NC}"
fi

NODE_ISSUES=$(kubectl get nodes | grep -v "Ready" | wc -l)
if [ "${NODE_ISSUES}" -gt 0 ]; then
    echo -e "${RED}警告: ${NODE_ISSUES}個のノードに問題が検出されました${NC}"
else
    echo -e "${GREEN}正常: すべてのノードが正常です${NC}"
fi

# 終了
echo
echo "=== クラスタ健全性チェック完了 ===" 