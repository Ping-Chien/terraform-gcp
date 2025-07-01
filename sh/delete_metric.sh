
PROJECT_ID="cloud-sre-poc-447001"

ACCESS_TOKEN=$(gcloud auth print-access-token)

METRICS=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://monitoring.googleapis.com/v3/projects/$PROJECT_ID/metricDescriptors?filter=metric.type=starts_with(\"custom.googleapis.com/\")" \
  | jq -r '.metricDescriptors // [] | .[].type')

if [ -z "$METRICS" ]; then
  echo "找不到任何自訂指標。"
  exit 0
fi

echo "找到以下自訂指標："
echo "$METRICS"

for METRIC in $METRICS; do
  echo "刪除指標：$METRIC"
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    "https://monitoring.googleapis.com/v3/projects/$PROJECT_ID/metricDescriptors/$METRIC")

  if [[ "$HTTP_STATUS" == "200" || "$HTTP_STATUS" == "204" ]]; then
    echo "成功刪除 $METRIC"
  else
    echo "刪除 $METRIC 失敗，HTTP 狀態碼：$HTTP_STATUS"
  fi
done

echo "全部刪除完成。"
