# Solar System CI/CD on AWS EKS

DevOps portfolio project for a Node.js, Express, and MongoDB Solar System app deployed to AWS EKS with Docker, Terraform, Kubernetes, GitHub Actions, Argo CD, Route 53, ACM, and Cloudflare DNS delegation.

## Stack

- Node.js 22, Express, MongoDB 7
- Docker and Docker Hub: `aunghtetlwin/solar-system-app`
- Terraform modules for VPC, EKS, IAM, and DNS
- AWS EKS, EBS CSI, Metrics Server, AWS Load Balancer Controller
- Kubernetes, Kustomize, Argo CD GitOps
- GitHub Actions CI/CD
- Route 53, ACM HTTPS, Cloudflare delegated DNS

## App Routes

- `GET /` - web UI
- `POST /planet` - planet lookup
- `GET /live` - liveness check
- `GET /ready` - readiness check
- `GET /os` - pod hostname and runtime info

## Local Development

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

Useful commands:

```bash
npm test
npm run coverage
npm run db:seed
docker compose down
```

## Docker

Run with the published Docker Hub image:

```bash
docker compose up -d
```

Build locally:

```bash
docker compose -f docker-compose.yml -f docker-compose.build.yml up -d --build
```

Image:

```text
aunghtetlwin/solar-system-app:latest
```

## Terraform

Terraform lives in:

```text
terraform/
```

Current module structure:

```text
terraform/modules/vpc  - VPC, subnets, NAT, routes
terraform/modules/eks  - EKS cluster, node group, addons, IRSA roles
terraform/modules/iam  - GitHub Actions OIDC access to EKS
terraform/modules/dns  - Route 53, ACM, dev/prod DNS records
```

Create infrastructure:

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

## AWS Load Balancer Controller

Terraform creates the IAM role for the controller. Helm installs the controller into EKS.

From repo root:

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

If running from inside `terraform/`, use `terraform output -raw ...` without `-chdir`.

## Argo CD GitOps

Install Argo CD:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl rollout status deployment/argocd-server -n argocd --timeout=5m
```

Apply the GitOps project and apps:

```bash
kubectl apply -f argocd/projects/
kubectl apply -f argocd/applications/
```

Applications:

- `solar-system-platform` - shared platform resources such as `gp3` StorageClass
- `solar-system-dev` - dev overlay with auto-sync enabled
- `solar-system-prod` - prod overlay with manual sync/promotion

Check:

```bash
kubectl get applications -n argocd
kubectl get pods -n solar-system-dev
kubectl get pods -n solar-system-prod
kubectl get ingress -A
```

Manual prod sync with Argo CD CLI:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443

argocd login localhost:8080 \
  --username admin \
  --password '<password>' \
  --insecure

argocd app sync solar-system-prod
```

Without Argo CD CLI:

```bash
kubectl patch application solar-system-prod \
  -n argocd \
  --type merge \
  -p '{"operation":{"sync":{}}}'
```

## CI/CD Flow

On push to `main`, GitHub Actions:

1. Runs unit tests
2. Runs coverage
3. Builds and smoke-tests the Docker image
4. Pushes Docker image tags to Docker Hub:
   - `<git-commit-sha>`
   - `latest`
5. Updates `kubernetes/overlays/dev/kustomization.yaml` with the new commit SHA
6. Commits the dev image tag update with `[skip ci]`
7. Argo CD auto-syncs dev

Required GitHub configuration:

- Secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`
- Variable: `ENABLE_GITOPS_UPDATE=true`

Manual prod promotion:

```text
GitHub -> Actions -> promote-prod -> Run workflow
```

The promotion workflow copies the current dev image tag into the prod overlay. Argo CD then syncs prod from Git.

See [docs/CI.md](docs/CI.md).

## Domain And HTTPS

Cloudflare manages the root domain:

```text
aunghtetlwin.com
```

Terraform creates a delegated Route 53 zone for:

```text
solar-system.aunghtetlwin.com
```

After Terraform creates the zone, copy the Route 53 nameservers into Cloudflare as `NS` records:

```bash
terraform -chdir=terraform output app_route53_name_servers
dig NS solar-system.aunghtetlwin.com +short
```

ACM certificate validation is handled by Terraform in Route 53. After Cloudflare delegation works, ACM becomes `ISSUED`.

Important flow:

```text
Terraform creates EKS + Route 53 + ACM
Argo CD creates Ingress
AWS Load Balancer Controller creates ALBs
Update terraform.tfvars with ALB DNS names
Terraform creates Route 53 alias records
```

Example `terraform/terraform.tfvars` ALB values:

```hcl
prod_alb_dns_name = "solar-system-prod-alb-xxxx.ap-southeast-1.elb.amazonaws.com"
dev_alb_dns_name  = "solar-system-dev-alb-xxxx.ap-southeast-1.elb.amazonaws.com"
alb_zone_id       = "Z1LMS91P8CMLE5"
```

Apply DNS aliases:

```bash
terraform -chdir=terraform plan -out=tfplan
terraform -chdir=terraform apply tfplan
```

URLs:

```text
https://solar-system.aunghtetlwin.com
http://dev.solar-system.aunghtetlwin.com
```

## Autoscaling

Terraform installs the EKS Metrics Server add-on. Kubernetes HPA scales the app between 2 and 6 replicas by CPU and memory.

Check:

```bash
kubectl top nodes
kubectl top pods -n solar-system-dev
kubectl get hpa -n solar-system-dev
```

Load test:

```bash
ADDRESS=$(kubectl get ingress solar-system-app -n solar-system-dev \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

hey -z 5m -c 100 "http://$ADDRESS/os"
```

Watch scaling:

```bash
kubectl get hpa -n solar-system-dev -w
kubectl get pods -n solar-system-dev -w
```

## Test Argo CD Sync

Watch dev pods:

```bash
kubectl get pods -n solar-system-dev -w
```

Push a small app change to `main`. After GitHub Actions finishes, the workflow commits a new dev image tag. Argo CD then rolls out dev automatically.

Check the running image:

```bash
kubectl get deployment solar-system-app \
  -n solar-system-dev \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

Pull the GitHub Actions bot commit locally:

```bash
git fetch origin
git pull --rebase origin main
grep newTag kubernetes/overlays/dev/kustomization.yaml
```

## Safe Cleanup

Before `terraform destroy`, delete Argo CD-managed apps first so AWS Load Balancer Controller can remove ALBs and security groups:

```bash
./scripts/cleanup-eks-apps.sh
```

Then confirm no project ALBs remain:

```bash
aws elbv2 describe-load-balancers \
  --region ap-southeast-1 \
  --profile master-programmatic-admin
```

Destroy Terraform infrastructure:

```bash
terraform -chdir=terraform plan -destroy -out=destroy.tfplan
terraform -chdir=terraform apply destroy.tfplan
```

Do not commit `tfplan` or `destroy.tfplan`.

## Notes

- MongoDB runs inside Kubernetes with a PVC backed by EBS. For production, use a managed database such as MongoDB Atlas, DocumentDB, or another managed service.
- Dev is automatic. Prod is manual promotion.
- The legacy direct deployment manifests remain in `kubernetes/eks/`, but the main deployment path is Argo CD.
