#!/bin/bash

# 同時実行数
CONCURRENT=10
# 実行時間（秒）
DURATION=300

echo "負荷テストを開始します（同時${CONCURRENT}接続、${DURATION}秒間）"

# 指定時間後にプロセスを終了するための関数
cleanup() {
    echo "テストを終了します..."
    pkill -P $$
    exit 0
}

# DURATION秒後にcleanupを実行
(sleep $DURATION && cleanup) &

# 並列でリクエストを送信
for i in $(seq 1 $CONCURRENT); do
    (
        while true; do
            curl -s http://localhost:30002 > /dev/null
            sleep 0.1
        done
    ) &
done

wait 