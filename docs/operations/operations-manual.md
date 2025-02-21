<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [マイクロサービス基盤 運用手順書](#%E3%83%9E%E3%82%A4%E3%82%AF%E3%83%AD%E3%82%B5%E3%83%BC%E3%83%93%E3%82%B9%E5%9F%BA%E7%9B%A4-%E9%81%8B%E7%94%A8%E6%89%8B%E9%A0%86%E6%9B%B8)
  - [1. 概要](#1-%E6%A6%82%E8%A6%81)
  - [2. 環境情報](#2-%E7%92%B0%E5%A2%83%E6%83%85%E5%A0%B1)
    - [2.1 環境一覧](#21-%E7%92%B0%E5%A2%83%E4%B8%80%E8%A6%A7)
    - [2.2 アクセス情報](#22-%E3%82%A2%E3%82%AF%E3%82%BB%E3%82%B9%E6%83%85%E5%A0%B1)
  - [3. 日常運用手順](#3-%E6%97%A5%E5%B8%B8%E9%81%8B%E7%94%A8%E6%89%8B%E9%A0%86)
    - [3.1 監視確認](#31-%E7%9B%A3%E8%A6%96%E7%A2%BA%E8%AA%8D)
    - [3.2 バックアップ](#32-%E3%83%90%E3%83%83%E3%82%AF%E3%82%A2%E3%83%83%E3%83%97)
    - [3.3 パッチ適用](#33-%E3%83%91%E3%83%83%E3%83%81%E9%81%A9%E7%94%A8)
  - [4. 障害対応手順](#4-%E9%9A%9C%E5%AE%B3%E5%AF%BE%E5%BF%9C%E6%89%8B%E9%A0%86)
    - [4.1 Pod障害](#41-pod%E9%9A%9C%E5%AE%B3)
    - [4.2 ノード障害](#42-%E3%83%8E%E3%83%BC%E3%83%89%E9%9A%9C%E5%AE%B3)
    - [4.3 監視アラート対応](#43-%E7%9B%A3%E8%A6%96%E3%82%A2%E3%83%A9%E3%83%BC%E3%83%88%E5%AF%BE%E5%BF%9C)
  - [5. メンテナンス手順](#5-%E3%83%A1%E3%83%B3%E3%83%86%E3%83%8A%E3%83%B3%E3%82%B9%E6%89%8B%E9%A0%86)
    - [5.1 計画メンテナンス](#51-%E8%A8%88%E7%94%BB%E3%83%A1%E3%83%B3%E3%83%86%E3%83%8A%E3%83%B3%E3%82%B9)
    - [5.2 緊急メンテナンス](#52-%E7%B7%8A%E6%80%A5%E3%83%A1%E3%83%B3%E3%83%86%E3%83%8A%E3%83%B3%E3%82%B9)
  - [6. セキュリティ運用](#6-%E3%82%BB%E3%82%AD%E3%83%A5%E3%83%AA%E3%83%86%E3%82%A3%E9%81%8B%E7%94%A8)
    - [6.1 脆弱性対応](#61-%E8%84%86%E5%BC%B1%E6%80%A7%E5%AF%BE%E5%BF%9C)
    - [6.2 セキュリティ監査](#62-%E3%82%BB%E3%82%AD%E3%83%A5%E3%83%AA%E3%83%86%E3%82%A3%E7%9B%A3%E6%9F%BB)
  - [7. 問い合わせ対応](#7-%E5%95%8F%E3%81%84%E5%90%88%E3%82%8F%E3%81%9B%E5%AF%BE%E5%BF%9C)
    - [7.1 一般的な問い合わせ](#71-%E4%B8%80%E8%88%AC%E7%9A%84%E3%81%AA%E5%95%8F%E3%81%84%E5%90%88%E3%82%8F%E3%81%9B)
    - [7.2 障害報告](#72-%E9%9A%9C%E5%AE%B3%E5%A0%B1%E5%91%8A)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# マイクロサービス基盤 運用手順書

## 1. 概要
このドキュメントは、マイクロサービス基盤の運用管理に関する手順書です。

## 2. 環境情報

### 2.1 環境一覧
- 開発環境（dev）
- ステージング環境（stg）
- 本番環境（prod）

### 2.2 アクセス情報
- AWS Console: https://console.aws.amazon.com/
- Kibana: https://kibana.microservices.example.com
- Grafana: https://grafana.microservices.example.com

## 3. 日常運用手順

### 3.1 監視確認
1. Grafanaダッシュボードの確認
   - クラスタリソース使用状況
   - アプリケーションメトリクス
   - エラーレート

2. Prometheusアラートの確認
   ```bash
   kubectl -n monitoring get prometheusrules
   kubectl -n monitoring get alertmanager
   ```

3. ログの確認
   - Kibanaダッシュボードでエラーログの確認
   - 異常パターンの検知

### 3.2 バックアップ
1. EKSクラスタのバックアップ
   ```bash
   velero backup create eks-backup-$(date +%Y%m%d)
   ```

2. Elasticsearchのスナップショット
   ```bash
   curl -X PUT "elasticsearch-master:9200/_snapshot/backup/snapshot-$(date +%Y%m%d)"
   ```

### 3.3 パッチ適用
1. セキュリティパッチの確認
   ```bash
   aws eks describe-addon-versions
   ```

2. Kubernetesバージョンアップ
   ```bash
   cd terraform/environments/<env>
   terraform plan -var kubernetes_version=<new_version>
   terraform apply
   ```

## 4. 障害対応手順

### 4.1 Pod障害
1. 状態確認
   ```bash
   kubectl get pods -A | grep -v Running
   kubectl describe pod <pod-name> -n <namespace>
   kubectl logs <pod-name> -n <namespace>
   ```

2. 再起動
   ```bash
   kubectl delete pod <pod-name> -n <namespace>
   ```

### 4.2 ノード障害
1. 状態確認
   ```bash
   kubectl get nodes
   kubectl describe node <node-name>
   ```

2. ノードの隔離
   ```bash
   kubectl cordon <node-name>
   kubectl drain <node-name> --ignore-daemonsets
   ```

### 4.3 監視アラート対応
1. CPU高使用率
   - プロセス確認
   - リソース制限の見直し
   - スケールアウトの検討

2. メモリ高使用率
   - メモリリーク調査
   - ヒープダンプ取得
   - リソース制限の見直し

3. ディスク高使用率
   - 不要ファイルの削除
   - ログローテーションの確認
   - ボリューム拡張の検討

## 5. メンテナンス手順

### 5.1 計画メンテナンス
1. 事前準備
   - 変更計画書の作成
   - バックアップの取得
   - 影響範囲の特定

2. 実施手順
   - 変更内容の確認
   - 変更の実施
   - 動作確認

3. 事後確認
   - 監視の確認
   - ログの確認
   - 利用者への通知

### 5.2 緊急メンテナンス
1. 初動対応
   - 状況の把握
   - 影響範囲の特定
   - 関係者への通知

2. 対応手順
   - 原因の特定
   - 対策の実施
   - 動作確認

3. 事後対応
   - 報告書の作成
   - 再発防止策の検討
   - 監視項目の見直し

## 6. セキュリティ運用

### 6.1 脆弱性対応
1. 脆弱性情報の収集
   - AWS Security Bulletins
   - Kubernetes Security Announcements
   - OSベンダーのセキュリティ情報

2. 影響度の評価
   - CVSSスコアの確認
   - 影響範囲の特定
   - 対応優先度の決定

3. 対策の実施
   - パッチの適用
   - 設定変更
   - 代替策の実施

### 6.2 セキュリティ監査
1. 定期監査
   - アクセスログの確認
   - 権限設定の確認
   - セキュリティグループの確認

2. コンプライアンス対応
   - 監査ログの保管
   - 証跡の管理
   - レポートの作成

## 7. 問い合わせ対応

### 7.1 一般的な問い合わせ
1. 情報収集
   - 問い合わせ内容の確認
   - 環境情報の確認
   - 再現手順の確認

2. 調査
   - ログの確認
   - 設定の確認
   - 類似事例の確認

3. 回答
   - 原因の説明
   - 対処方法の説明
   - 再発防止策の提案

### 7.2 障害報告
1. 一次対応
   - 状況の確認
   - 暫定対処
   - 報告の準備

2. 原因調査
   - ログ解析
   - 環境調査
   - 再現確認

3. 恒久対応
   - 対策の実施
   - 検証
   - 報告書作成 