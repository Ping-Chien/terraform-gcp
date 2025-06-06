import http from 'k6/http';
import { sleep, check } from 'k6';
import { Rate } from 'k6/metrics';
import { htmlReport } from "./bundle.js";

// Custom metric to track errors
const errors = new Rate('errors');

// Test configuration
export const options = {
  // We'll use scenarios to control the rate of requests
  scenarios: {
    constant_request_rate: {
      // Run 10 iterations per second
      executor: 'constant-arrival-rate',
      rate: 1, // 1 iterations per second
      timeUnit: '1s',
      duration: '10s', // This should be enough to reach 10,000 requests (10 req/s * 1000s = 10,000 reqs)
      preAllocatedVUs: 10, // Start with 10 VUs
      maxVUs: 50, // Increase VUs if needed to maintain request rate
      gracefulStop: '0s'
    }
  },
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests should be below 500ms
    errors: ['rate<0.1'], // Error rate should be less than 10%
  },
};

// Main test function
export default function () {
  // Target endpoint
  const url = 'http://app1.default.svc.cluster.local:8080/click';
  
  // Send request
  const response = http.get(url);
  
  // Check if the request was successful
  const success = check(response, {
    'status is 200': (r) => r.status === 200,
  });
  
  // If not successful, increase error rate
  if (!success) {
    errors.add(1);
    console.log(`Error: ${response.status} - ${response.body}`);
  }
  
  // No sleep is needed as the constant-arrival-rate executor handles timing
}

// 生成 HTML 報告的函數
export function handleSummary(data) {
  return {
    "/scripts/summary.html": htmlReport(data),
    "/scripts/summary.json": JSON.stringify(data),
  };
}
