#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-ap-southeast-1}"
AWS_PROFILE="${AWS_PROFILE:-master-programmatic-admin}"
CLUSTER_NAME="${CLUSTER_NAME:-solar-system-eks}"

echo "Using cluster: ${CLUSTER_NAME}"
echo "Using AWS region: ${AWS_REGION}"
echo "Using AWS profile: ${AWS_PROFILE}"

echo
echo "Checking kubectl access..."
kubectl cluster-info >/dev/null

echo
echo "Deleting Argo CD Applications..."
kubectl delete -f argocd/applications/ --ignore-not-found=true

echo
echo "Waiting for application namespaces to terminate resources..."
kubectl delete namespace solar-system-dev solar-system-prod --ignore-not-found=true --wait=false

echo
echo "Waiting for ALBs created by Kubernetes Ingress to disappear..."
for i in {1..40}; do
  ALB_COUNT=$(aws elbv2 describe-load-balancers \
    --region "${AWS_REGION}" \
    --profile "${AWS_PROFILE}" \
    --query "length(LoadBalancers[?contains(LoadBalancerName, 'solar-system')])" \
    --output text)

  if [ "${ALB_COUNT}" = "0" ]; then
    echo "No solar-system ALBs remain."
    break
  fi

  echo "Still waiting for ${ALB_COUNT} solar-system ALB(s) to be deleted..."
  sleep 15
done

echo
echo "Current solar-system ALBs:"
aws elbv2 describe-load-balancers \
  --region "${AWS_REGION}" \
  --profile "${AWS_PROFILE}" \
  --query "LoadBalancers[?contains(LoadBalancerName, 'solar-system')].{Name:LoadBalancerName,DNS:DNSName,State:State.Code}" \
  --output table

echo
echo "Delete Argo CD project and namespace..."
kubectl delete -f argocd/projects/ --ignore-not-found=true
kubectl delete namespace argocd --ignore-not-found=true --wait=false

echo
echo "Cleanup request complete."
echo "Before terraform destroy, confirm no ALBs remain:"
echo "aws elbv2 describe-load-balancers --region ${AWS_REGION} --profile ${AWS_PROFILE}"
