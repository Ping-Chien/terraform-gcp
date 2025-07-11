#!/bin/bash

# 部署 k6 到 GKE 集群的腳本
set -e

# 變數設置 - 請根據實際情況修改
PROJECT_ID="cloud-sre-poc-465509"  # GCP 項目 ID
REGION="asia-east1"                # GKE 集群所在區域
CLUSTER_NAME="tracing-gke-cluster"         # GKE 集群名稱
SERVICE_ACCOUNT="k6-gcp-sa"        # GCP 服務帳號名稱
K6_YAML_PATH="./yaml/k6-deployment.yaml"  # k6 部署清單相對路徑

# 顏色設置
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}開始部署 k6 到 GKE 集群...${NC}"

# 確保已連接到正確的 GKE 集群
echo -e "${YELLOW}連接到 GKE 集群...${NC}"
gcloud container clusters get-credentials ${CLUSTER_NAME} --region ${REGION} --project ${PROJECT_ID}

# 檢查是否需要創建 GCP 服務帳號
if ! gcloud iam service-accounts describe ${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com --project ${PROJECT_ID} &> /dev/null; then
  echo -e "${YELLOW}創建 GCP 服務帳號...${NC}"
  gcloud iam service-accounts create ${SERVICE_ACCOUNT} \
    --display-name "K6 Load Testing Service Account" \
    --project ${PROJECT_ID}
  
  # 添加必要的 IAM 權限
  echo -e "${YELLOW}添加 IAM 權限...${NC}"
  gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/logging.logWriter"
fi

# 設置 Workload Identity
echo -e "${YELLOW}設置 Workload Identity 綁定...${NC}"
gcloud iam service-accounts add-iam-policy-binding \
  ${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:${PROJECT_ID}.svc.id.goog[default/k6-sa]" \
  --project ${PROJECT_ID}

# 設置基本變數
export K6_NAME="k6"
# 應用 k6 部署
echo -e "${YELLOW}部署 k6 到集群...${NC}"
envsubst < ${K6_YAML_PATH} | kubectl apply -f -

echo -e "${GREEN}部署完成!${NC}"
echo -e "${GREEN}提示: 您可以使用以下命令查看 k6 日誌:${NC}"
echo -e "kubectl logs -f \$(kubectl get pod -l app=k6 -o jsonpath='{.items[0].metadata.name}') k6"
