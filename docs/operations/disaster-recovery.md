# マイクロサービス基盤 障害復旧手順書

## 目次

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [1. 初動対応](#1-%E5%88%9D%E5%8B%95%E5%AF%BE%E5%BF%9C)
  - [1.1 状況確認](#11-%E7%8A%B6%E6%B3%81%E7%A2%BA%E8%AA%8D)
  - [1.2 一時対応](#12-%E4%B8%80%E6%99%82%E5%AF%BE%E5%BF%9C)
- [2. システム復旧](#2-%E3%82%B7%E3%82%B9%E3%83%86%E3%83%A0%E5%BE%A9%E6%97%A7)
  - [2.1 EKSクラスタ復旧](#21-eks%E3%82%AF%E3%83%A9%E3%82%B9%E3%82%BF%E5%BE%A9%E6%97%A7)
  - [2.2 データ復旧](#22-%E3%83%87%E3%83%BC%E3%82%BF%E5%BE%A9%E6%97%A7)
  - [2.3 アプリケーション復旧](#23-%E3%82%A2%E3%83%97%E3%83%AA%E3%82%B1%E3%83%BC%E3%82%B7%E3%83%A7%E3%83%B3%E5%BE%A9%E6%97%A7)
- [3. 復旧後の確認](#3-%E5%BE%A9%E6%97%A7%E5%BE%8C%E3%81%AE%E7%A2%BA%E8%AA%8D)
  - [3.1 システム確認](#31-%E3%82%B7%E3%82%B9%E3%83%86%E3%83%A0%E7%A2%BA%E8%AA%8D)
  - [3.2 動作確認](#32-%E5%8B%95%E4%BD%9C%E7%A2%BA%E8%AA%8D)
- [4. 事後対応](#4-%E4%BA%8B%E5%BE%8C%E5%AF%BE%E5%BF%9C)
  - [4.1 報告書作成](#41-%E5%A0%B1%E5%91%8A%E6%9B%B8%E4%BD%9C%E6%88%90)
  - [4.2 改善施策](#42-%E6%94%B9%E5%96%84%E6%96%BD%E7%AD%96)
  - [4.3 訓練計画](#43-%E8%A8%93%E7%B7%B4%E8%A8%88%E7%94%BB)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## 1. 初動対応

### 1.1 状況確認
1. 障害の影響範囲の特定
   - サービス停止の有無
   - データ損失の有無
   - ユーザーへの影響

2. 関係者への通知
   - 運用チーム
   - 開発チーム
   - 経営層
   - 必要に応じて顧客

3. 初期診断
   ```bash
   # クラスタ状態確認
   kubectl get nodes
   kubectl get pods -A
   
   # ログ確認
   kubectl logs -n <namespace> <pod-name>
   ```

### 1.2 一時対応
1. サービス影響の最小化
   - 障害ノードの隔離
   - トラフィックの切り替え
   - 代替システムの起動

2. データ保護
   - 即時バックアップの実行
   - ログの保全
   - 証跡の収集

## 2. システム復旧

### 2.1 EKSクラスタ復旧
1. クラスタ状態確認
   ```bash
   aws eks describe-cluster --name microservices-<env>
   ```

2. ノードグループ復旧
   ```bash
   # 新規ノードグループの作成
   aws eks create-nodegroup \
     --cluster-name microservices-<env> \
     --nodegroup-name <new-nodegroup-name> \
     --scaling-config minSize=2,maxSize=4,desiredSize=2
   
   # 古いノードグループの削除
   aws eks delete-nodegroup \
     --cluster-name microservices-<env> \
     --nodegroup-name <old-nodegroup-name>
   ```

3. クラスタアドオンの復旧
   ```bash
   aws eks update-addon \
     --cluster-name microservices-<env> \
     --addon-name <addon-name> \
     --addon-version <version>
   ```

### 2.2 データ復旧
1. Veleroによるバックアップからの復元
   ```bash
   # 利用可能なバックアップの確認
   velero backup get
   
   # バックアップの復元
   velero restore create --from-backup <backup-name>
   ```

2. Elasticsearchスナップショットの復元
   ```bash
   # スナップショットの確認
   curl -X GET "elasticsearch-master:9200/_snapshot/backup/_all"
   
   # スナップショットの復元
   curl -X POST "elasticsearch-master:9200/_snapshot/backup/<snapshot-name>/_restore"
   ```

3. データ整合性の確認
   ```bash
   # インデックスの確認
   curl -X GET "elasticsearch-master:9200/_cat/indices?v"
   
   # シャードの確認
   curl -X GET "elasticsearch-master:9200/_cat/shards?v"
   ```

### 2.3 アプリケーション復旧
1. 依存サービスの復旧
   ```bash
   # 名前空間の作成
   kubectl apply -f kubernetes/manifests/namespace.yaml
   
   # 監視スタックの復旧
   helm upgrade --install monitoring kubernetes/helm/monitoring \
     --namespace monitoring \
     --values kubernetes/helm/monitoring/values.yaml
   
   # ログ収集スタックの復旧
   helm upgrade --install logging kubernetes/helm/logging \
     --namespace logging \
     --values kubernetes/helm/logging/values.yaml
   ```

2. アプリケーションのデプロイ
   ```bash
   # ConfigMapとSecretの復旧
   kubectl apply -f <config-files>
   
   # アプリケーションのデプロイ
   kubectl apply -f <application-manifests>
   ```

## 3. 復旧後の確認

### 3.1 システム確認
1. コンポーネント状態の確認
   ```bash
   # Pod状態確認
   kubectl get pods -A
   
   # サービス状態確認
   kubectl get svc -A
   
   # イングレス状態確認
   kubectl get ingress -A
   ```

2. 監視システムの確認
   - Prometheusメトリクスの収集状態
   - Grafanaダッシュボードの表示
   - アラートの設定

3. ログ収集システムの確認
   - Elasticsearchクラスタの状態
   - Kibanaでのログ表示
   - ログ収集の継続性

### 3.2 動作確認
1. 基本機能の確認
   - エンドポイントの疎通確認
   - API機能の動作確認
   - データの整合性確認

2. パフォーマンス確認
   - レスポンスタイムの測定
   - スループットの確認
   - リソース使用状況の確認

3. セキュリティ確認
   - 認証・認可の動作確認
   - 証明書の有効性確認
   - セキュリティグループの設定確認

## 4. 事後対応

### 4.1 報告書作成
1. インシデントの詳細
   - 発生日時
   - 影響範囲
   - 原因分析
   - 復旧手順
   - 復旧時間

2. 再発防止策
   - システム改善案
   - 運用改善案
   - モニタリング強化案

### 4.2 改善施策
1. システム強化
   - 冗長性の強化
   - バックアップ体制の見直し
   - 監視項目の追加

2. 運用強化
   - 手順書の更新
   - 訓練計画の策定
   - チーム体制の見直し

### 4.3 訓練計画
1. 定期的な復旧訓練
   - シナリオの作成
   - 訓練の実施
   - 結果の評価

2. 手順書の更新
   - 新しい知見の反映
   - チェックリストの改善
   - 連絡体制の更新 