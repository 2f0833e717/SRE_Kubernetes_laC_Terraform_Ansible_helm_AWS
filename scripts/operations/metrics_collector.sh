#!/bin/bash

# 監視メトリクス収集スクリプト
# 使用方法: ./metrics_collector.sh [出力ディレクトリ]

set -e

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 引数チェック
OUTPUT_DIR=${1:-"/var/log/metrics"}
DATETIME=$(date +%Y%m%d_%H%M%S)
mkdir -p "${OUTPUT_DIR}/${DATETIME}"

echo "=== メトリクス収集開始 ==="
echo "出力ディレクトリ: ${OUTPUT_DIR}/${DATETIME}"
echo

# クラスタメトリクス収集
echo "=== クラスタメトリクス収集 ==="

# ノードメトリクス
echo "--- ノードメトリクス収集 ---"
kubectl top nodes > "${OUTPUT_DIR}/${DATETIME}/node_metrics.txt"
kubectl describe nodes > "${OUTPUT_DIR}/${DATETIME}/node_details.txt"

# Podメトリクス
echo "--- Podメトリクス収集 ---"
kubectl top pods --all-namespaces > "${OUTPUT_DIR}/${DATETIME}/pod_metrics.txt"
kubectl get pods --all-namespaces -o wide > "${OUTPUT_DIR}/${DATETIME}/pod_details.txt"

# Prometheusメトリクス
echo "=== Prometheusメトリクス収集 ==="

# CPU使用率
echo "--- CPU使用率収集 ---"
curl -s "http://prometheus-server:9090/api/v1/query" \
  --data-urlencode 'query=sum(rate(container_cpu_usage_seconds_total{container!=""}[5m])) by (namespace)' \
  > "${OUTPUT_DIR}/${DATETIME}/cpu_usage.json"

# メモリ使用率
echo "--- メモリ使用率収集 ---"
curl -s "http://prometheus-server:9090/api/v1/query" \
  --data-urlencode 'query=sum(container_memory_usage_bytes{container!=""}) by (namespace)' \
  > "${OUTPUT_DIR}/${DATETIME}/memory_usage.json"

# ディスク使用率
echo "--- ディスク使用率収集 ---"
curl -s "http://prometheus-server:9090/api/v1/query" \
  --data-urlencode 'query=sum(container_fs_usage_bytes{container!=""}) by (namespace)' \
  > "${OUTPUT_DIR}/${DATETIME}/disk_usage.json"

# ネットワークトラフィック
echo "--- ネットワークトラフィック収集 ---"
curl -s "http://prometheus-server:9090/api/v1/query" \
  --data-urlencode 'query=sum(rate(container_network_receive_bytes_total[5m])) by (namespace)' \
  > "${OUTPUT_DIR}/${DATETIME}/network_receive.json"
curl -s "http://prometheus-server:9090/api/v1/query" \
  --data-urlencode 'query=sum(rate(container_network_transmit_bytes_total[5m])) by (namespace)' \
  > "${OUTPUT_DIR}/${DATETIME}/network_transmit.json"

# アプリケーションメトリクス
echo "=== アプリケーションメトリクス収集 ==="

# HTTPリクエスト数
echo "--- HTTPリクエスト数収集 ---"
curl -s "http://prometheus-server:9090/api/v1/query" \
  --data-urlencode 'query=sum(rate(http_requests_total[5m])) by (service)' \
  > "${OUTPUT_DIR}/${DATETIME}/http_requests.json"

# エラーレート
echo "--- エラーレート収集 ---"
curl -s "http://prometheus-server:9090/api/v1/query" \
  --data-urlencode 'query=sum(rate(http_requests_total{status=~"5.."}[5m])) by (service) / sum(rate(http_requests_total[5m])) by (service) * 100' \
  > "${OUTPUT_DIR}/${DATETIME}/error_rate.json"

# レスポンスタイム
echo "--- レスポンスタイム収集 ---"
curl -s "http://prometheus-server:9090/api/v1/query" \
  --data-urlencode 'query=histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))' \
  > "${OUTPUT_DIR}/${DATETIME}/response_time.json"

# Elasticsearchメトリクス
echo "=== Elasticsearchメトリクス収集 ==="

# クラスタ健全性
echo "--- クラスタ健全性収集 ---"
curl -s "elasticsearch-master:9200/_cluster/health" \
  > "${OUTPUT_DIR}/${DATETIME}/es_health.json"

# インデックス統計
echo "--- インデックス統計収集 ---"
curl -s "elasticsearch-master:9200/_stats" \
  > "${OUTPUT_DIR}/${DATETIME}/es_stats.json"

# ノード統計
echo "--- ノード統計収集 ---"
curl -s "elasticsearch-master:9200/_nodes/stats" \
  > "${OUTPUT_DIR}/${DATETIME}/es_node_stats.json"

# メトリクスの解析
echo "=== メトリクス解析 ==="

# 結果ファイルの作成
REPORT_FILE="${OUTPUT_DIR}/${DATETIME}/analysis_report.txt"
echo "メトリクス解析レポート - ${DATETIME}" > "${REPORT_FILE}"
echo "=================================" >> "${REPORT_FILE}"
echo >> "${REPORT_FILE}"

# ノードリソース使用率の分析
echo "ノードリソース使用率:" >> "${REPORT_FILE}"
awk 'NR>1 {printf "  %s: CPU: %s, Memory: %s\n", $1, $3, $5}' "${OUTPUT_DIR}/${DATETIME}/node_metrics.txt" >> "${REPORT_FILE}"
echo >> "${REPORT_FILE}"

# 高負荷Podの特定
echo "高負荷Pod (CPU > 80% または Memory > 80%):" >> "${REPORT_FILE}"
awk 'NR>1 && ($3>80 || $7>80) {printf "  %s/%s: CPU: %s, Memory: %s\n", $1, $2, $3, $7}' "${OUTPUT_DIR}/${DATETIME}/pod_metrics.txt" >> "${REPORT_FILE}"
echo >> "${REPORT_FILE}"

# エラーレートの分析
echo "高エラーレート (> 5%) のサービス:" >> "${REPORT_FILE}"
jq -r '.data.result[] | select(.value[1] > "5") | .metric.service + ": " + .value[1] + "%"' "${OUTPUT_DIR}/${DATETIME}/error_rate.json" >> "${REPORT_FILE}"
echo >> "${REPORT_FILE}"

# 結果の圧縮
cd "${OUTPUT_DIR}"
tar czf "metrics_${DATETIME}.tar.gz" "${DATETIME}"
rm -rf "${DATETIME}"

echo
echo "=== メトリクス収集完了 ==="
echo "結果: ${OUTPUT_DIR}/metrics_${DATETIME}.tar.gz"
echo "解析レポート: ${OUTPUT_DIR}/metrics_${DATETIME}.tar.gz内のanalysis_report.txt" 