# Operations Runbook

Use this runbook to install, deploy, observe, test, and safely destroy the Solar System EKS environment.

## 1. Create Infrastructure

```bash
terraform -chdir=terraform init
terraform -chdir=terraform validate
terraform -chdir=terraform plan -out=tfplan
terraform -chdir=terraform apply tfplan
```

Configure `kubectl`:

```bash
aws eks update-kubeconfig \
  --region ap-southeast-1 \
  --name solar-system-eks \
  --profile master-programmatic-admin
```

Check:

```bash
kubectl get nodes
```

## 2. Install AWS Load Balancer Controller

Terraform creates the IAM role. Helm installs the controller.

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks

helm upgrade --install aws-load-balancer-controller \
  eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName=solar-system-eks \
  --set region=ap-southeast-1 \
  --set vpcId=$(terraform -chdir=terraform output -raw vpc_id) \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set-string 'serviceAccount.annotations.eks\.amazonaws\.com/role-arn'=$(terraform -chdir=terraform output -raw aws_load_balancer_controller_role_arn)
```

Check:

```bash
kubectl get pods -n kube-system | grep aws-load-balancer-controller
kubectl get sa aws-load-balancer-controller -n kube-system -o yaml
```

## 3. Install Argo CD And Apps

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl rollout status deployment/argocd-server -n argocd --timeout=5m
```

Apply project and applications:

```bash
kubectl apply -f argocd/projects/
kubectl apply -f argocd/applications/
```

Prod is manual sync:

```bash
kubectl patch application solar-system-prod \
  -n argocd \
  --type merge \
  -p '{"operation":{"sync":{}}}'
```

Or:

```bash
argocd app sync solar-system-prod
```

Check:

```bash
kubectl get applications -n argocd
kubectl get pods -n solar-system-dev
kubectl get pods -n solar-system-prod
kubectl get ingress -A
```

## 4. Configure DNS Alias Records

After Argo CD creates Ingress resources, get the ALB names:

```bash
kubectl get ingress -A
```

Update `terraform/terraform.tfvars`:

```hcl
prod_alb_dns_name = "solar-system-prod-alb-xxxx.ap-southeast-1.elb.amazonaws.com"
dev_alb_dns_name  = "solar-system-dev-alb-xxxx.ap-southeast-1.elb.amazonaws.com"
alb_zone_id       = "Z1LMS91P8CMLE5"
```

Apply DNS records:

```bash
terraform -chdir=terraform plan -out=tfplan
terraform -chdir=terraform apply tfplan
```

Test:

```bash
curl -I https://solar-system.aunghtetlwin.com
curl -I http://dev.solar-system.aunghtetlwin.com
```

## 5. Install Observability

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

helm upgrade --install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring
```

Check:

```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

Access Grafana:

```bash
kubectl port-forward svc/kube-prometheus-stack-grafana \
  -n monitoring 3001:80
```

Get Grafana password:

```bash
kubectl get secret kube-prometheus-stack-grafana \
  -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 -d
echo
```

Open:

```text
http://localhost:3001
```

Useful dashboards:

- `Kubernetes / Compute Resources / Namespace (Workloads)`
- `Kubernetes / Compute Resources / Pod`
- `Kubernetes / Compute Resources / Workload`
- `Kubernetes / Networking / Namespace (Pods)`

## 6. Load Test

```bash
ADDRESS=$(kubectl get ingress solar-system-app -n solar-system-dev \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

hey -z 5m -c 1000 "http://$ADDRESS/os"
```

Watch:

```bash
kubectl get hpa -n solar-system-dev -w
kubectl get pods -n solar-system-dev -w
watch -n 2 kubectl top pods -n solar-system-dev
```

Note: `/os` is lightweight, so it may show network traffic without triggering HPA scaling. A CPU-heavy endpoint would be needed for a stronger HPA demo.

## 7. Local Development

```bash
cp .env.example .env
npm ci
docker compose up -d mongo
npm run db:seed
npm test
npm start
```

Open:

```text
http://localhost:3000
```

## 8. Docker

Run with published image:

```bash
docker compose up -d
```

Build locally:

```bash
docker compose -f docker-compose.yml -f docker-compose.build.yml up -d --build
```

## 9. Safe Destroy

Before Terraform destroy, let Kubernetes and AWS Load Balancer Controller remove ALBs:

```bash
./scripts/cleanup-eks-apps.sh
```

Confirm no project ALBs remain:

```bash
aws elbv2 describe-load-balancers \
  --region ap-southeast-1 \
  --profile master-programmatic-admin
```

Destroy:

```bash
terraform -chdir=terraform plan -destroy -out=destroy.tfplan
terraform -chdir=terraform apply destroy.tfplan
```

Remove local plan files:

```bash
rm -f terraform/tfplan terraform/destroy.tfplan
```
