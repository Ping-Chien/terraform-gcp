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
      rate: 1, // 每秒總共執行N次請求（所有VU共用）
      timeUnit: '1s',
      duration: '5m', // 總共運行1分鐘（60秒），約產生60次請求
      preAllocatedVUs: 10, // 開始時分配10個虛擬用戶（VU）
      maxVUs: 50, // 如有需要，可增加到最多50個VU來維持請求速率
      gracefulStop: '0s'
    }
  },
  thresholds: {
    // http_req_duration: ['p(95)<500'], // 95% of requests should be below 500ms
    // errors: ['rate<0.1'], // Error rate should be less than 10%
    // 'transaction_times': ['p(95)<500'], // 95% 的交易應在 500ms 內完成
  },
};

let baseId = 3;

// Main test function
export default function () {
  let id = baseId + __ITER;
    let url = 'http://dotnet-frontend-4znqw.default.svc.cluster.local:8080/submit';
    let payload = JSON.stringify({
        url: "http://dotnet-backend-service.default.svc.cluster.local:8080/employees",
        name: "chen",
        tel: "0987654321",
        id: id
    });

    let params = {
        headers: {
            'Content-Type': 'application/json',
        },
    };

    let res = http.post(url, payload, params);x
  
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
  // 從 data 獲取測試開始時間
  // data.state 包含測試的狀態信息，其中 testRunDuration 是測試的統計信息
  let timestamp;
  
  try {
    // 嘗試從 data 中獲取測試開始時間
    // 我們可以從當前時間減去測試持續時間來獲取開始時間
    if (data && data.state && data.state.testRunDuration) {
      const testDurationMs = data.state.testRunDuration;
      const testStartTimeMs = Date.now() - testDurationMs;
      const testStartTime = new Date(testStartTimeMs);
      
      // 產生 yyyy_mm_dd_hh_mi_ss 格式的時間戳記
      const year = testStartTime.getFullYear();
      const month = String(testStartTime.getMonth() + 1).padStart(2, '0');
      const day = String(testStartTime.getDate()).padStart(2, '0');
      const hours = String(testStartTime.getHours()).padStart(2, '0');
      const minutes = String(testStartTime.getMinutes()).padStart(2, '0');
      const seconds = String(testStartTime.getSeconds()).padStart(2, '0');
      
      timestamp = `${year}_${month}_${day}_${hours}_${minutes}_${seconds}`;
    } else {
      // 如果無法取得測試開始時間，則使用當前時間
      console.log('警告：無法取得測試開始時間，使用當前時間作為代替');
      const now = new Date();
      const year = now.getFullYear();
      const month = String(now.getMonth() + 1).padStart(2, '0');
      const day = String(now.getDate()).padStart(2, '0');
      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      
      timestamp = `${year}_${month}_${day}_${hours}_${minutes}_${seconds}`;
    }
  } catch (error) {
    // 如果發生任何錯誤，使用當前時間作為備用
    console.log(`錯誤：${error.message}，使用當前時間作為代替`);
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');
    
    timestamp = `${year}_${month}_${day}_${hours}_${minutes}_${seconds}`;
  }
  
  return {
    [`/scripts/summary_${timestamp}.html`]: htmlReport(data),
    [`/scripts/summary_${timestamp}.json`]: JSON.stringify(data)
  };
}
