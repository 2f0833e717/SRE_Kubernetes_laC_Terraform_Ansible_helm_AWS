package main

import (
	"fmt"
	"math/rand"
	"net/http"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	// リクエスト数のカウンター
	httpRequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"path", "status"},
	)

	// レスポンスタイムのヒストグラム
	httpRequestDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "HTTP request duration in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"path"},
	)

	// アプリケーションの状態を示すゲージ
	appStatus = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "app_status",
			Help: "Application status (1 for healthy, 0 for unhealthy)",
		},
	)
)

func recordMetrics() {
	go func() {
		for {
			// ランダムなアプリケーションの状態を設定
			appStatus.Set(float64(rand.Intn(2)))
			time.Sleep(30 * time.Second)
		}
	}()
}

func handleRoot(w http.ResponseWriter, r *http.Request) {
	start := time.Now()
	defer func() {
		duration := time.Since(start).Seconds()
		httpRequestDuration.WithLabelValues("/").Observe(duration)
	}()

	// ランダムなレイテンシーを追加
	time.Sleep(time.Duration(rand.Intn(100)) * time.Millisecond)

	httpRequestsTotal.WithLabelValues("/", "200").Inc()
	fmt.Fprintf(w, "Hello, World!")
}

func main() {
	rand.Seed(time.Now().UnixNano())
	recordMetrics()

	http.HandleFunc("/", handleRoot)
	http.Handle("/metrics", promhttp.Handler())

	fmt.Println("Server starting on :8080")
	http.ListenAndServe(":8080", nil)
} 