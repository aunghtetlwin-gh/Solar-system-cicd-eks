# Solar System CI/CD EKS Project
  
This project is a Node.js, Express, HTML, and MongoDB Solar System application being converted into a DevOps portfolio project.

Current stack:

- Node.js and Express
- MongoDB
- Docker and Docker Compose
- Docker Hub
- Terraform for AWS EKS infrastructure
- Kubernetes on AWS EKS
- GitHub Actions CI

## Application

The app displays Solar System planet data in a browser.

Important routes:

- `GET /` - web page
- `POST /planet` - fetch planet data by ID
- `GET /os` - runtime hostname and environment
- `GET /live` - liveness endpoint
- `GET /ready` - readiness endpoint

The app listens on port `3000` by default. You can override it with `PORT`.

## Requirements

Install these tools locally:

- Node.js 22 LTS or newer
- npm
- Docker
- Docker Compose
- Git
- AWS CLI
- Terraform
- kubectl

## Environment Variables

Create a local `.env` file from the example:

```bash
cp .env.example .env
```

Local development values:

```env
PORT=3000
MONGO_URI=mongodb://localhost:27017/solar-system
MONGO_USERNAME=
MONGO_PASSWORD=
```

For local Docker Compose, the app container uses this MongoDB URI:

```env
MONGO_URI=mongodb://mongo:27017/solar-system
```

Inside Docker Compose, `mongo` is the MongoDB service name.

## npm Scripts

Install dependencies:

```bash
npm ci
```

Run tests:

```bash
npm test
```

Run coverage:

```bash
npm run coverage
```

Seed MongoDB with planet data:

```bash
npm run db:seed
```

Start the app locally:

```bash
npm start
```

## Run Locally With Node.js

Start MongoDB:

```bash
docker compose up -d mongo
```

Install dependencies:

```bash
npm ci
```

Seed the database:

```bash
npm run db:seed
```

Start the app:

```bash
npm start
```

Open:

```text
http://localhost:3000
```

## Run With Docker Compose

By default, Docker Compose uses the Docker Hub image:

```text
aunghtetlwin/solar-system-app:v1
```

Start the app and MongoDB:

```bash
docker compose up -d
```

Seed MongoDB:

```bash
npm run db:seed
```

Open:

```text
http://localhost:3000
```

Check container status:

```bash
docker compose ps
```

Stop containers:

```bash
docker compose down
```

## Build The App Image Locally

Use the local build override:

```bash
docker compose -f docker-compose.yml -f docker-compose.build.yml up -d --build
```

Or build manually:

```bash
docker build -t solar-system-app:local .
```

Tag for Docker Hub:

```bash
docker tag solar-system-app:local aunghtetlwin/solar-system-app:v1
docker tag solar-system-app:local aunghtetlwin/solar-system-app:latest
```

Push to Docker Hub:

```bash
docker push aunghtetlwin/solar-system-app:v1
docker push aunghtetlwin/solar-system-app:latest
```

## MongoDB

Local MongoDB runs in Docker on:

```text
localhost:27017
```

Database:

```text
solar-system
```

Collection:

```text
planets
```

Seed data file:

```text
seed/planets.json
```

Seed script:

```text
scripts/seed-mongo.js
```

For local development, MongoDB currently has no username or password.

## Terraform EKS Infrastructure

Terraform code is in:

```text
terraform/
```

It is designed to create:

- VPC
- public and private subnets
- Internet Gateway
- NAT Gateway
- EKS cluster
- EKS managed node group
- IAM roles and policies
- EKS add-ons: VPC CNI, kube-proxy, CoreDNS, and EBS CSI driver
- IAM OIDC provider and IRSA role for the EBS CSI driver

Create local Terraform variables:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Current local AWS profile:

```text
master-programmatic-admin
```

Check AWS credentials:

```bash
aws sts get-caller-identity --profile master-programmatic-admin
```

Initialize and validate Terraform:

```bash
terraform init
terraform validate
terraform plan
```

Do not run `terraform apply` until you have reviewed the plan and accepted the AWS cost.

Create the EKS infrastructure:

```bash
terraform apply
```

After the EKS cluster exists, configure kubectl:

```bash
aws eks update-kubeconfig \
  --region ap-southeast-1 \
  --name solar-system-eks \
  --profile master-programmatic-admin
```

Verify nodes:

```bash
kubectl get nodes
```

## Deploy To EKS

Kubernetes manifests are in:

```text
kubernetes/eks/
```

They create:

- `solar-system` namespace
- `gp3` StorageClass using the AWS EBS CSI driver
- MongoDB PVC backed by an EBS volume
- MongoDB Deployment and internal Service
- ConfigMap for app environment variables
- ConfigMap with planet seed data
- MongoDB seed Job
- Solar System app Deployment
- LoadBalancer Service for external access

Apply the manifests:

```bash
kubectl apply -f kubernetes/eks/
```

Check resources:

```bash
kubectl get all -n solar-system
kubectl get pvc -n solar-system
kubectl get pv
kubectl get svc -n solar-system
```

Get the external LoadBalancer hostname:

```bash
kubectl get svc solar-system-app -n solar-system
```

Open the `EXTERNAL-IP` hostname in a browser:

```text
http://<load-balancer-hostname>
```

The app image used by EKS is:

```text
aunghtetlwin/solar-system-app:latest
```

## Troubleshooting: MongoDB PVC Pending

Problem seen during deployment:

```text
mongo pod Pending
mongo-data PVC Pending
UnauthorizedOperation: not authorized to perform ec2:CreateVolume
```

The PVC event showed the EBS CSI controller initially tried to create an EBS volume using the node group role:

```text
arn:aws:sts::<account-id>:assumed-role/solar-system-eks-node-group-role/...
```

Expected role:

```text
arn:aws:iam::<account-id>:role/solar-system-eks-ebs-csi-driver-role
```

Terraform creates the proper EBS CSI IRSA setup:

- IAM OIDC provider for the EKS cluster
- IAM role for `kube-system/ebs-csi-controller-sa`
- `AmazonEBSCSIDriverPolicy` attached to that role
- EBS CSI add-on configured with `service_account_role_arn`

Verify the service account annotation:

```bash
kubectl get sa ebs-csi-controller-sa -n kube-system -o yaml
```

Expected annotation:

```yaml
eks.amazonaws.com/role-arn: arn:aws:iam::<account-id>:role/solar-system-eks-ebs-csi-driver-role
```

Verify the EKS add-on role:

```bash
aws eks describe-addon \
  --cluster-name solar-system-eks \
  --addon-name aws-ebs-csi-driver \
  --region ap-southeast-1 \
  --profile master-programmatic-admin \
  --query 'addon.serviceAccountRoleArn'
```

If the role is correct but the PVC is still pending, restart the EBS CSI controller and recreate the stuck MongoDB pod:

```bash
kubectl rollout restart deployment ebs-csi-controller -n kube-system
kubectl rollout status deployment ebs-csi-controller -n kube-system
kubectl delete pod -n solar-system -l app.kubernetes.io/name=mongo
```

Then check the volume:

```bash
kubectl get pvc -n solar-system
kubectl get pv
```

Expected result:

```text
mongo-data PVC Bound
PV Bound to solar-system/mongo-data
```

Why this happened:

The EBS CSI add-on had the correct IRSA configuration after Terraform, but the existing controller pods needed to restart before volume provisioning retried with the service account IAM role.

## Cleanup

Delete the app resources but keep the EKS cluster:

```bash
kubectl delete -f kubernetes/eks/
```

Destroy all AWS infrastructure created by Terraform:

```bash
cd terraform
terraform destroy
```

Use `terraform destroy` when you are finished testing to avoid ongoing EKS, NAT Gateway, EC2, EBS, and LoadBalancer costs.

## Current Project Phase

Completed:

- Local app cleanup
- Local MongoDB with Docker Compose
- MongoDB seed data and seed script
- Production-style Dockerfile
- Docker Hub image push
- GitHub Actions CI for test, coverage, Docker build, and Docker Hub push
- Terraform EKS infrastructure
- EBS CSI driver with IRSA
- Kubernetes manifests for EKS

Next:

- Verify app through the AWS LoadBalancer
- Commit Kubernetes manifests
- Add GitHub Actions deployment to EKS
