#!/bin/bash
# 此腳本用於從檔案讀取 k6 測試腳本並發送到 Cloud Run 服務

# 設定 Cloud Run 服務 URL
CLOUD_RUN_URL="https://k6-load-test-aue6fattfa-de.a.run.app"

# 確保腳本在錯誤時停止執行
set -e

# 檢查參數
SCRIPT_FILE="${1:-load_test.js}"
VUS="${2:-10}"
DURATION="${3:-30s}"

# 檢查腳本文件是否存在
if [ ! -f "$SCRIPT_FILE" ]; then
  echo "錯誤: 找不到測試腳本文件: $SCRIPT_FILE"
  echo "用法: $0 [腳本文件路徑] [虛擬用戶數] [持續時間]"
  echo "例如: $0 ../k6_script/load_test.js 10 30s"
  exit 1
fi

echo "正在讀取測試腳本: $SCRIPT_FILE"
# 讀取測試腳本內容
TEST_SCRIPT=$(cat "$SCRIPT_FILE")

echo "正在向 Cloud Run 服務發送測試請求..."
echo "服務 URL: $CLOUD_RUN_URL"
echo "虛擬用戶數: $VUS"
echo "測試持續時間: $DURATION"

# 發送請求到 Cloud Run 服務
curl -H "Content-Type: application/json" \
  -X POST \
  -d "{\"test_script\":\"$TEST_SCRIPT\", \"vus\":$VUS, \"duration\":\"$DURATION\"}" \
  "$CLOUD_RUN_URL"

echo -e "\n測試請求已發送!"
