# Solar System CI/CD EKS Project

This project is a Node.js, Express, HTML, and MongoDB Solar System application being converted into a DevOps portfolio project.

Current stack:

- Node.js and Express
- MongoDB
- Docker and Docker Compose
- Docker Hub
- Terraform for AWS EKS infrastructure
- Kubernetes and GitHub Actions planned for the next phases

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

## Current Project Phase

Completed:

- Local app cleanup
- Local MongoDB with Docker Compose
- MongoDB seed data and seed script
- Production-style Dockerfile
- Docker Hub image push
- Terraform EKS infrastructure scaffold

Next:

- Run Terraform plan
- Create EKS cluster
- Add Kubernetes manifests for the Solar System app
- Add GitHub Actions CI/CD
