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

---

## GCP 啟用服務API(GCP Lab已啟用)
請至 GCP Console `API & Services`啟用以下 API：
- Artifact Registry API
- Cloud SQL API
- Cloud SQL Admin API
- Compute Engine API
- Kubernetes Engine API
- Service Networking API
- Serverless VPC Access API
- Cloud Run Admin API

## GCP 認證設定(GCP Lab已設定，service account= terraform-tracing-creator@cloud-sre-poc-447001.iam.gserviceaccount.com，請下載新的金鑰)
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
- 網路安全管理員：roles/compute.securityAdmin

2. 將下載的金鑰檔案放置於此專案 `.config/gcloud/` 目錄下，例如：`.config/gcloud/${下載的credentials檔名}.json`

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

### 4. 推送 Docker 映像檔到 Artifact Registry(必須先將tracing-test專案的image打包好)
請在此專案跟目錄直接執行 `push-image-to-artifact-registry.sh` 腳本：
```bash
./sh/push-image-to-artifact-registry.sh
```

此腳本會自動完成以下動作：
- 登入 Artifact Registry
- 重新 tag 本地映像檔
- 推送映像檔到 GCP Artifact Registry

> 請先在腳本內設定好 PROJECT_ID、REGION、REPO、IMAGE_NAME 等參數，或根據需求修改腳本內容。


### 5. 部署應用程式到 GKE，透過cloud shell 執行
> 請先到web console 查詢 cloud shell ip

`curl ifconfig.me`

<img src="attachments/Screenshot%202025-05-19%20at%207.23.14%E2%80%AFAM.png" alt="cloud shell ip" width="700" />

>填寫到gke cluster，讓GKE允許來自cloud shell的ip

<img src="attachments/Screenshot%202025-05-19%20at%207.26.55%E2%80%AFAM.png" alt="gke cluster" width="700" />
<img src="attachments/Screenshot%202025-05-19%20at%207.27.05%E2%80%AFAM.png" alt="cloud shell ip" width="700" />

>將以下相關腳本上傳到cloud shell

>.config/gcloudsql/cloudsql-sa-key.json

>sh/deploy-to-gke.sh

>yaml/*

>在 cloud shell執行 `deploy-to-gke.sh`，內容如下：
```bash
./deploy-to-gke.sh
```
<img src="attachments/Screenshot%202025-05-19%20at%207.54.47%E2%80%AFAM.png" alt="cloud shell ip" width="700" />

完成後可登入gcloud用 `kubectl get pods`、`kubectl get svc` 指令檢查狀態。

### 6.1 部署collector到 GKE，透過cloud shell 執行
>sh/deploy-to-gke-collector.sh


### 7. 測試
>gke會部署兩個workload，一個app1，一個app2，

>測試方式為進入app1，呼叫app1的api /call-other，

>然後 app1 會呼叫 app2 的 api /counter，寫入一筆記錄到cloud >sql，

>目的要確認 app1 -> app2 -> cloud sql 的流程是否正常，被正常記錄到gcp tracing 
```bash
kubectl get pods
kubectl exec -it ${POD_NAME 進入app1} -- /bin/sh
curl 'http://127.0.0.1:8080/call-other?podUrl=http://${下一個被呼叫的APP_NAME}:8080'
```

### 8. 測試完成請刪除執行個體(節費)
```hcl
terraform destroy
```
> 刪除VPC會發生錯誤，需要到GCP Console刪除“虛擬私有雲網路對接"，再執行一次

![錯誤訊息](attachments/Screenshot%202025-05-16%20at%2010.09.51%E2%80%AFPM.png)

![虛擬私有雲網路對接](attachments/Screenshot%202025-05-16%20at%2010.12.19%E2%80%AFPM.png)

---

## 注意事項
- 若遇到權限或認證問題，請確認 gcloud 已正確登入，且有足夠權限操作 GCP 資源。
執行此步驟需要的service account權限

---

## 參考檔案
- `main.tf`、`gke.tf`、`artifact-registry.tf`、`cloudsql.tf`、`vpc.tf`、`cloud_run.tf`：Terraform 配置
- `yaml/app1-deployment.yaml`、`yaml/app1-service.yaml`、`yaml/app2-deployment.yaml`、`yaml/app2-service.yaml`：Kubernetes 部署檔
- `sh/deploy-to-gke.sh`：自動化部署pod腳本
- `sh/push-image-to-artifact-registry.sh`：推送映像檔腳本
- `cloudsql-init.sql`：初始化資料庫 SQL



