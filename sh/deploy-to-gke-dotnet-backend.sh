#!/bin/bash
# 透過 gcloud 取得 GKE 認證並部署 yaml 到 GKE
# 請先設定下方三個變數

PROJECT_ID="cloud-sre-poc-447001"
REGION="asia-east1"
CLUSTER_NAME="tracing-gke-cluster"

# 取得 GKE 認證
 gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID"

# 自動建立最新 cloudsql-sa-key secret（每次都覆蓋）
#kubectl delete secret cloudsql-sa-key --ignore-not-found
#kubectl create secret generic cloudsql-sa-key --from-file=credentials.json=cloudsql-sa-key.json


# 部署 Deployment & Service yaml
kubectl apply -f yaml/dotnet-deployment.yaml
kubectl apply -f yaml/dotnet-service.yaml
#kubectl rollout restart deployment app3
#kubectl apply -f yaml/app3-service.yaml
#kubectl apply -f yaml/app4-deployment.yaml
#kubectl rollout restart deployment app4
#kubectl apply -f yaml/app4-service.yaml

echo "\n已完成 dotnet0backend 部署！可用 kubectl get pods, kubectl get svc 檢查狀態。"
