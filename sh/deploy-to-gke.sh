#!/bin/bash
# 透過 gcloud 取得 GKE 認證並部署 yaml 到 GKE
# 請先設定下方三個變數

PROJECT_ID="cloud-sre-poc-465509"
REGION="asia-east1"
CLUSTER_NAME="tracing-gke-cluster"

# 取得 GKE 認證
 gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID"

# 自動建立最新 cloudsql-sa-key secret（每次都覆蓋）
# kubectl delete secret cloudsql-sa-key --ignore-not-found
# kubectl create secret generic cloudsql-sa-key --from-file=credentials.json=cloudsql-sa-key.json

# 設置基本變數
export APP_NAME="app1"
export IMAGE_NAME="asia-east1-docker.pkg.dev/cloud-sre-poc-465509/app-image-repo/tracing-test:ori"
# 部署 Deployment & Service yaml
envsubst < yaml/app-deployment.yaml | kubectl apply -f -
kubectl rollout restart deployment ${APP_NAME}

# 設置基本變數
export APP_NAME="app2"
export IMAGE_NAME="asia-east1-docker.pkg.dev/cloud-sre-poc-465509/app-image-repo/tracing-test:ori"
# 部署 Deployment & Service yaml
envsubst < yaml/app-deployment.yaml | kubectl apply -f -
kubectl rollout restart deployment ${APP_NAME}


echo "\n已完成 GKE 部署！可用 kubectl get pods, kubectl get svc 檢查狀態。"
