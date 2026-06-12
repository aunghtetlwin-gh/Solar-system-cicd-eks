# Solar System CI/CD on AWS EKS

DevOps portfolio project for a Node.js, Express, and MongoDB Solar System application.

## Stack

- Node.js 22 and Express
- MongoDB 7
- Docker and Docker Compose
- Docker Hub: `aunghtetlwin/solar-system-app`
- GitHub Actions CI
- Terraform
- AWS EKS and Kubernetes

## Application

Routes:

- `GET /` - web UI
- `POST /planet` - planet lookup
- `GET /live` - liveness check
- `GET /ready` - readiness check
- `GET /os` - pod hostname and environment

## Local Development

```bash
cp .env.example .env
npm ci
docker compose up -d mongo
npm run db:seed
npm test
npm start
```

Open `http://localhost:3000`.

Useful commands:

```bash
npm test
npm run coverage
npm run db:seed
docker compose down
```

## Docker

Run the published image with MongoDB:

```bash
docker compose up -d
```

Build from local source:

```bash
docker compose -f docker-compose.yml -f docker-compose.build.yml up -d --build
```

Published image:

```text
aunghtetlwin/solar-system-app:latest
```

## Terraform And EKS

Terraform in `terraform/` creates:

- VPC with three public and three private subnets
- Internet Gateway, NAT Gateway, and routing
- EKS cluster and managed worker node group
- IAM roles and EKS add-ons
- EBS CSI driver with OIDC/IRSA

Configure and create infrastructure:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform plan
terraform apply
```

Configure `kubectl`:

```bash
aws eks update-kubeconfig \
  --region ap-southeast-1 \
  --name solar-system-eks \
  --profile master-programmatic-admin

kubectl get nodes
```

## Deploy To EKS

The manifests in `kubernetes/eks/` create:

- `solar-system` namespace
- `gp3` StorageClass and MongoDB PVC
- MongoDB Deployment, Service, and seed Job
- Two app replicas
- AWS LoadBalancer Service

Deploy:

```bash
kubectl apply -f kubernetes/eks/
kubectl get all -n solar-system
kubectl get pvc,pv -A
kubectl get svc solar-system-app -n solar-system
```

Open the LoadBalancer hostname shown under `EXTERNAL-IP`.

## CI

GitHub Actions currently:

1. Installs dependencies with `npm ci`
2. Runs tests and coverage
3. Builds and smoke-tests the Docker image
4. Pushes the commit SHA and `latest` tags to Docker Hub

Required GitHub secrets:

```text
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
```

## Troubleshooting

### MongoDB PVC remains Pending

Check the PVC:

```bash
kubectl describe pvc mongo-data -n solar-system
```

If EBS volume creation uses the node role instead of the EBS CSI IRSA role, verify:

```bash
kubectl get sa ebs-csi-controller-sa -n kube-system -o yaml

aws eks describe-addon \
  --cluster-name solar-system-eks \
  --addon-name aws-ebs-csi-driver \
  --region ap-southeast-1 \
  --profile master-programmatic-admin \
  --query 'addon.serviceAccountRoleArn'
```

Restart the controller and retry the Mongo pod:

```bash
kubectl rollout restart deployment ebs-csi-controller -n kube-system
kubectl rollout status deployment ebs-csi-controller -n kube-system
kubectl delete pod -n solar-system -l app.kubernetes.io/name=mongo
```

Verify:

```bash
kubectl get pvc -n solar-system
kubectl get pv
```

## Cleanup

Delete only the Kubernetes application:

```bash
kubectl delete -f kubernetes/eks/
```

Destroy all Terraform-managed AWS infrastructure:

```bash
cd terraform
terraform destroy
```

Destroy unused resources to avoid EKS, EC2, NAT Gateway, EBS, and LoadBalancer charges.

## Next Phase

- Add GitHub Actions AWS OIDC role using Terraform
- Deploy to EKS automatically from GitHub Actions
- Replace the LoadBalancer Service with AWS Load Balancer Controller and Ingress
