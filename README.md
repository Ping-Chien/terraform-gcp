# Terraform deploy

本專案會在 GCP 建立：
- 一個 GKE (Kubernetes) Cluster
- 一個 Cloud SQL Instance（名稱 tracing-test）
- 一個名為 counter 的資料庫，內有 counter table（欄位：id, number）
- 一個名為 app-image-repo 的 Artifact Registry Repository

---

## 操作端必要安裝項目
請先安裝下列工具：
- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- [gcloud CLI](https://cloud.google.com/sdk/docs/install)（需額外安裝 GKE plugin，可用指令：`gcloud components install gke-gcloud-auth-plugin`）
- [Docker](https://docs.docker.com/get-docker/)
- [MySQL Client](https://dev.mysql.com/downloads/mysql/)（用於連線 Cloud SQL 建立資料表）

---

## GCP 啟用服務API
請至 GCP Console `API & Services`啟用以下 API：
- Artifact Registry API
- Cloud SQL API
- Cloud SQL Admin API
- Compute Engine API
- Kubernetes Engine API
- Service Networking API

## GCP 認證設定
1. 請至 GCP Console 建立具備必要權限的 Service Account，並產生金鑰（JSON 檔）。
service account 必須具備以下role
- Artifact Registry 管理員：roles/artifactregistry.admin
- Cloud SQL 管理員：roles/cloudsql.admin
- Compute 執行個體管理員 (v1)：roles/compute.instanceAdmin.v1
- Kubernetes Engine 管理員：roles/container.admin
- 專案 IAM 管理員：roles/resourcemanager.projectIamAdmin
- 服務帳戶管理員：roles/iam.serviceAccountAdmin
- 服務帳戶金鑰管理員：roles/iam.serviceAccountKeyAdmin
- 服務帳戶使用者：roles/iam.serviceAccountUser
- 網路管理員：roles/compute.networkViewer
2. 將下載的金鑰檔案放置於 `.config/gcloud/` 目錄下，例如：`.config/gcloud/${下載的credentials檔名}.json`
3. 確認 `variables.tf` 內 provider 的 credentials 路徑與檔名一致：
   ```hcl
   variable "gcp_credentials_file" {
     description = "Path to GCP credentials json file"
     type        = string
     default     = ".config/gcloud/${下載的credentials檔名}.json"
   }
   ```

> 若 credentials 設定錯誤或權限不足，Terraform 操作將會失敗，請務必確認。

---

## 步驟說明

### 1. 設定專案參數
檢查`variables.tf`，相關參數皆已設定：
```hcl
project_id = "<你的 GCP 專案 ID>"
db_password = "<你的 Cloud SQL root 密碼>"
region = "<你的 GCP region>"
gcp_credentials_file = "<你的 GCP credentials json file路徑>"
```

### 2. terminal登入gcloud
```bash
gcloud auth login
```
### 3. 初始化與部署基礎設置
```bash
terraform init
terraform apply
```

### 4. 建立資料庫 Table
> 建立資料庫 Table，必須到 Cloud SQL Instance 的Cloud SQL studio 執行
執行 `cloudsql-init.sql` 



### 5. 推送 Docker 映像檔到 Artifact Registry
請直接執行 `push-image-to-artifact-registry.sh` 腳本：
```bash
./sh/push-image-to-artifact-registry.sh
```

此腳本會自動完成以下動作：
- 登入 Artifact Registry
- 重新 tag 本地映像檔
- 推送映像檔到 GCP Artifact Registry

> 請先在腳本內設定好 PROJECT_ID、REGION、REPO、IMAGE_NAME 等參數，或根據需求修改腳本內容。


### 6. 部署應用程式到 GKE，透過cloud shell 執行
> 請先查詢cloud shell ip
`curl ifconfig.me`
>填寫到gke cluster(補圖)
>將相關腳本上傳到cloud shell
請執行 `deploy-to-gke.sh`，內容如下：
```bash
./deploy-to-gke.sh
```

完成後可登入gcloud用 `kubectl get pods`、`kubectl get svc` 指令檢查狀態。

### 7. 發送request
```bash
kubectl get pods
kubectl exec -it ${POD_NAME 進入app1} -- /bin/sh
curl http://127.0.0.1:8080/call-other
```

### 8. 測試完成請刪除執行個體(節費)
```hcl
terraform destroy
```
> 刪除VPC會發生錯誤，需要到GCP Console刪除“虛擬私有雲網路對接”，再執行一次

![錯誤訊息](attachments/Screenshot%202025-05-16%20at%2010.09.51%E2%80%AFPM.png)

![虛擬私有雲網路對接](attachments/Screenshot%202025-05-16%20at%2010.12.19%E2%80%AFPM.png)

---

## 注意事項
- 若遇到權限或認證問題，請確認 gcloud 已正確登入，且有足夠權限操作 GCP 資源。
執行此步驟需要的service account權限

---

## 參考檔案
- `main.tf`、`gke.tf`、`artifact-registry.tf`、`cloudsql.tf`、`vpc.tf`：Terraform 配置
- `yaml/app1-deployment.yaml`、`yaml/app1-service.yaml`、`yaml/app2-deployment.yaml`、`yaml/app2-service.yaml`：Kubernetes 部署檔
- `sh/deploy-to-gke.sh`：自動化部署pod腳本
- `sh/push-image-to-artifact-registry.sh`：推送映像檔腳本
- `cloudsql-init.sql`：初始化資料庫 SQL

---
### 刪除專案
Unable to remove Service Networking Connection ... Failed to delete connection; Producer services (e.g. CloudSQL, Cloud Memstore, etc.) are still using this connection.



