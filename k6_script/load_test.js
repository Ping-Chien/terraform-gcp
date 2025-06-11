import http from 'k6/http';
import { sleep, check } from 'k6';
import { Rate, Counter, Trend } from 'k6/metrics';
import { htmlReport } from "https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js";
import { textSummary } from "https://jslib.k6.io/k6-summary/0.0.1/index.js";

// Custom metrics
const errors = new Rate('errors');
const transactions = Counter('transactions'); // 計算交易總數
const transactionTimes = Trend('transaction_times'); // 交易時間趨勢

// Test configuration
export const options = {
  // We'll use scenarios to control the rate of requests
  scenarios: {
    constant_request_rate: {
      // 設定每秒執行總請求數
      executor: 'constant-arrival-rate',
      rate: 100, // 每秒總共執行1次請求（所有VU共用）
      timeUnit: '1s',
      duration: '5m', // 總共運行1分鐘（60秒），約產生60次請求
      preAllocatedVUs: 10, // 開始時分配10個虛擬用戶（VU）
      maxVUs: 50, // 如有需要，可增加到最多50個VU來維持請求速率
      gracefulStop: '0s'
    }
  },
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests should be below 500ms
    errors: ['rate<0.1'], // Error rate should be less than 10%
    'transaction_times': ['p(95)<500'], // 95% 的交易應在 500ms 內完成
  },
};

// Main test function
export default function () {
  // Target endpoint
  const url = 'http://app1.default.svc.cluster.local:8080/call-other';
  
  // Send request
  const response = http.get(url);
  
  // 記錄交易開始時間
  const startTime = new Date();
  
  // Check if the request was successful
  const success = check(response, {
    'status is 200': (r) => r.status === 200,
  });
  
  // 計算交易時間（毫秒）
  const transactionTime = new Date() - startTime;
  transactionTimes.add(transactionTime);
  
  // 無論成功失敗，都計算為一次交易嘗試
  transactions.add(1);
  
  if (success) {
    // 請求成功處理
  } else {
    // 錯誤處理
    errors.add(1);
    console.log(`Error: ${response.status} - ${response.body}`);
  }
  
  // No sleep is needed as the constant-arrival-rate executor handles timing
}

// 生成 HTML 報告的函數
export function handleSummary(data) {
  return {
    "/scripts/summary.html": htmlReport(data),
    "/scripts/summary.json": JSON.stringify(data)
  };
}
