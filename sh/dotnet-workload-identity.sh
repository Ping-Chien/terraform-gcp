PROJECT_ID="cloud-sre-poc-447001"
SERVICEACCOUNT="dotnet-backend"
NAMESPACE="default"

kubectl create serviceaccount $SERVICEACCOUNT --namespace=$NAMESPACE

gcloud iam service-accounts add-iam-policy-binding $SERVICEACCOUNT@$PROJECT_ID.iam.gserviceaccount.com --role roles/iam.workloadIdentityUser --member "serviceAccount:$PROJECT_ID.svc.id.goog[$NAMESPACE/$SERVICEACCOUNT]"

kubectl annotate serviceaccount $SERVICEACCOUNT --namespace $NAMESPACE iam.gke.io/gcp-service-account=$SERVICEACCOUNT@$PROJECT_ID.iam.gserviceaccount.com