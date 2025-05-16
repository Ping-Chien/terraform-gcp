#!/bin/bash
# 將本地 docker.io/library/tracing-test:latest 推送到 Google Artifact Registry
# 使用前請先將 <YOUR_PROJECT_ID> 與 <REGION> 替換為你的實際專案與區域

PROJECT_ID="cloud-sre-poc-447001"
REGION="asia-east1"
REPO="app-image-repo"
IMAGE_NAME_app="tracing-test"
TAG_app="latest"
IMAGE_NAME_javaagent="javaagent"
TAG_javaagent="2.16.0"

# 登入 Artifact Registry
 gcloud auth configure-docker $REGION-docker.pkg.dev

# 重新 tag 本地映像檔
 docker tag docker.io/library/$IMAGE_NAME_app:$TAG_app $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE_NAME_app:$TAG_app
 docker tag docker.io/library/$IMAGE_NAME_javaagent:$TAG_javaagent $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE_NAME_javaagent:$TAG_javaagent

# 推送到 Artifact Registry
 docker push $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE_NAME_app:$TAG_app
 docker push $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE_NAME_javaagent:$TAG_javaagent

echo "\n推送完成"
