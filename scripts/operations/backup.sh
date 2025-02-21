#!/bin/bash

# バックアップスクリプト
# 使用方法: ./backup.sh [環境名]

set -e

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 引数チェック
ENV=${1:-"dev"}
BACKUP_DATE=$(date +%Y%m%d)
BACKUP_TIME=$(date +%H%M%S)

# バックアップディレクトリの作成
BACKUP_DIR="/backup/${ENV}/${BACKUP_DATE}"
mkdir -p "${BACKUP_DIR}"

echo "=== バックアップ開始 ==="
echo "環境: ${ENV}"
echo "バックアップ日時: ${BACKUP_DATE}_${BACKUP_TIME}"
echo

# Veleroバックアップの実行
echo "=== EKSクラスタバックアップ ==="
velero backup create "eks-${ENV}-${BACKUP_DATE}-${BACKUP_TIME}" \
  --include-namespaces microservices,monitoring,logging \
  --wait

# バックアップ状態の確認
BACKUP_STATUS=$(velero backup get "eks-${ENV}-${BACKUP_DATE}-${BACKUP_TIME}" -o jsonpath='{.status.phase}')
if [ "${BACKUP_STATUS}" = "Completed" ]; then
    echo -e "${GREEN}EKSバックアップ成功${NC}"
else
    echo -e "${RED}EKSバックアップ失敗: ${BACKUP_STATUS}${NC}"
    exit 1
fi
echo

# Elasticsearchスナップショットの作成
echo "=== Elasticsearchスナップショット作成 ==="
curl -X PUT "elasticsearch-master:9200/_snapshot/backup/snapshot-${ENV}-${BACKUP_DATE}-${BACKUP_TIME}" \
  -H 'Content-Type: application/json' \
  -d '{
    "indices": "*",
    "ignore_unavailable": true,
    "include_global_state": true
  }'

# スナップショット状態の確認
sleep 10
SNAPSHOT_STATUS=$(curl -s -X GET "elasticsearch-master:9200/_snapshot/backup/snapshot-${ENV}-${BACKUP_DATE}-${BACKUP_TIME}" | jq -r '.snapshots[0].state')
if [ "${SNAPSHOT_STATUS}" = "SUCCESS" ]; then
    echo -e "${GREEN}Elasticsearchスナップショット成功${NC}"
else
    echo -e "${RED}Elasticsearchスナップショット失敗: ${SNAPSHOT_STATUS}${NC}"
    exit 1
fi
echo

# Kubernetesリソース設定のエクスポート
echo "=== Kubernetesリソース設定のエクスポート ==="
RESOURCES=(
    "configmaps"
    "secrets"
    "deployments"
    "services"
    "ingresses"
    "horizontalpodautoscalers"
    "prometheusrules"
    "servicemonitors"
)

for RESOURCE in "${RESOURCES[@]}"; do
    echo "エクスポート: ${RESOURCE}"
    kubectl get "${RESOURCE}" --all-namespaces -o yaml > "${BACKUP_DIR}/${RESOURCE}.yaml"
done

# バックアップの圧縮
echo "=== バックアップファイルの圧縮 ==="
cd /backup
tar czf "${ENV}-${BACKUP_DATE}-${BACKUP_TIME}.tar.gz" "${ENV}/${BACKUP_DATE}"

# S3へのアップロード
echo "=== S3へのアップロード ==="
aws s3 cp "${ENV}-${BACKUP_DATE}-${BACKUP_TIME}.tar.gz" \
  "s3://microservices-backup/${ENV}/backups/"

# クリーンアップ
echo "=== クリーンアップ ==="
rm -rf "${BACKUP_DIR}"
rm "${ENV}-${BACKUP_DATE}-${BACKUP_TIME}.tar.gz"

# 古いバックアップの削除
echo "=== 古いバックアップの削除 ==="
# Veleroバックアップ（7日以上前）
velero backup delete --confirm \
  $(velero backup get | grep "eks-${ENV}" | awk '{if ($3 > "168h0m0s") print $1}')

# Elasticsearchスナップショット（7日以上前）
curl -X GET "elasticsearch-master:9200/_snapshot/backup/_all" | \
  jq -r ".snapshots[] | select(.snapshot | startswith(\"snapshot-${ENV}\")) | 
         select((.start_time | fromdateiso8601) < (now - 604800)) | .snapshot" | \
  while read -r snapshot; do
    curl -X DELETE "elasticsearch-master:9200/_snapshot/backup/${snapshot}"
  done

# S3バックアップ（30日以上前）
aws s3 ls "s3://microservices-backup/${ENV}/backups/" | \
  awk '{if ($1 < strftime("%Y-%m-%d", systime() - 2592000)) print $4}' | \
  while read -r file; do
    aws s3 rm "s3://microservices-backup/${ENV}/backups/${file}"
  done

echo
echo "=== バックアップ完了 ===" 