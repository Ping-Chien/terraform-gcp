#!/bin/bash
# 透過 gcloud 取得 GKE 認證並部署 yaml 到 GKE
# 請先設定下方三個變數

PROJECT_ID="cloud-sre-poc-447001"
REGION="asia-east1"
CLUSTER_NAME="tracing-gke-cluster"

# 取得 GKE 認證
 gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID"

# 部署 Deployment & Service yaml
kubectl apply -f yaml/app-push-mode-deployment.yaml
kubectl rollout restart deployment app-push-mode

echo "\n已完成 GKE 部署！可用 kubectl get pods, kubectl get svc 檢查狀態。"
