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
- MongoDB credentials Secret
- MongoDB Deployment, Service, and seed Job
- Two app replicas
- ClusterIP app Service
- ALB Ingress

Install AWS Load Balancer Controller after Terraform completes:

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks

helm upgrade --install aws-load-balancer-controller \
  eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName=solar-system-eks \
  --set region=ap-southeast-1 \
  --set vpcId=$(cd terraform && terraform output -raw vpc_id) \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$(cd terraform && terraform output -raw aws_load_balancer_controller_role_arn)
```

The legacy direct deployment path is:

```bash
kubectl apply -f kubernetes/eks/
kubectl get all -n solar-system
kubectl get pvc,pv -A
kubectl get ingress -n solar-system
```

Open the Ingress hostname shown under `ADDRESS`.

## Argo CD GitOps

GitOps manifests are split into shared platform resources, reusable app base
resources, and dev/prod overlays:

```text
kubernetes/platform
kubernetes/base
kubernetes/overlays/dev
kubernetes/overlays/prod
argocd/projects
argocd/applications
```

Install Argo CD after the EKS cluster exists:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl rollout status deployment/argocd-server -n argocd --timeout=5m
```

Create the Argo CD project and applications:

```bash
kubectl apply -f argocd/projects/
kubectl apply -f argocd/applications/
```

Applications:

- `solar-system-platform` syncs shared cluster resources such as `gp3`.
- `solar-system-dev` syncs `kubernetes/overlays/dev` automatically.
- `solar-system-prod` syncs `kubernetes/overlays/prod` after promotion.

Recommended promotion flow:

```text
GitHub Actions updates dev image tag
Argo CD auto-syncs dev
Copy tested dev tag to prod overlay
Merge PR
Argo CD syncs prod
```

## CI/CD

GitHub Actions:

1. Runs tests and coverage
2. Builds and smoke-tests the Docker image
3. Pushes commit SHA and `latest` tags to Docker Hub
4. Optionally updates the dev Kustomize overlay image tag
5. Argo CD syncs Kubernetes from Git

Required GitHub configuration:

- Secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`
- Variables: `ENABLE_GITOPS_UPDATE=true`

See [docs/CI.md](docs/CI.md) for a short workflow reference.

## Domain And HTTPS

The root domain `aunghtetlwin.com` is registered in Cloudflare. Terraform
creates a delegated Route 53 hosted zone for:

```text
solar-system.aunghtetlwin.com
```

After `terraform apply`, copy the Route 53 nameservers into Cloudflare DNS as
`NS` records:

```bash
cd terraform
terraform output app_route53_name_servers
```

In Cloudflare, add one record for each output value:

```text
Type: NS
Name: solar-system
Content: <Route 53 nameserver>
Proxy: DNS only
```

Then verify delegation:

```bash
dig NS solar-system.aunghtetlwin.com
```

Terraform also creates the ACM certificate and DNS validation records in the
delegated Route 53 zone. ACM becomes `Issued` after Cloudflare delegation
propagates.

After the ALB Ingress exists, set the ALB DNS name and hosted zone ID in
Terraform variables so Route 53 can create the app alias record:

```hcl
app_alb_dns_name = "solar-system-dev-alb-..."
app_alb_zone_id  = "Z1LMS91P8CMLE5"
```

Then apply Terraform again and use:

```text
https://solar-system.aunghtetlwin.com
```

## Verify EKS

```bash
kubectl get pods -n solar-system
kubectl get svc -n solar-system
kubectl get pvc -n solar-system
kubectl get pv
kubectl get storageclass
```

The expected result is one running MongoDB pod, one completed seed Job, two
running application pods, and a bound `mongo-data` PVC/PV. The seed Job exits
after inserting the initial planet data, so `Completed` is normal.

MongoDB authentication is enabled through the `mongo-credentials` Secret. The
example password is for learning only; change it before using this outside a
temporary lab cluster.

If you enable MongoDB auth on an existing unauthenticated MongoDB volume,
recreate the lab PVC so MongoDB initializes with credentials:

```bash
kubectl delete pvc mongo-data -n solar-system
kubectl apply -f kubernetes/eks/
```

## Autoscaling

Terraform installs the EKS Metrics Server add-on. It supplies current pod CPU
and memory usage to Kubernetes. The HPA scales the app between 2 and 6 replicas
using these targets:

- CPU: 60% of the `100m` request
- Memory: 75% of the `128Mi` request, approximately `96Mi`

Kubernetes calculates a replica recommendation for each metric and uses the
larger value. Node.js may retain allocated memory after traffic falls, so
memory-based scale-down can be slower than CPU-based scale-down.

After applying Terraform and the Kubernetes manifests, verify:

```bash
kubectl get deployment metrics-server -n kube-system
kubectl top nodes
kubectl top pods -n solar-system
kubectl get hpa -n solar-system
```

Load test the external application:

```bash
ADDRESS=$(kubectl get ingress solar-system-app -n solar-system \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

hey -z 5m -c 100 "http://$ADDRESS/os"
```

Watch scaling in another terminal:

```bash
kubectl get hpa -n solar-system -w
kubectl get pods -n solar-system -w
```

The HPA may take a few minutes to scale down after traffic stops because it has
a five-minute scale-down stabilization window.

## Test CD

Make a small application change, commit it, and push it to `main`. Then run:

```bash
kubectl get pods -n solar-system -w
kubectl rollout status deployment/solar-system-app -n solar-system
kubectl get deployment solar-system-app -n solar-system \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

No manual rollout restart is needed. The workflow changes the Deployment image
to the new Git commit SHA, and Kubernetes automatically performs a rolling
update.

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

### Ingress does not get an ADDRESS

Check the controller:

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller
kubectl describe ingress solar-system-app -n solar-system
```

Confirm the controller service account has the Terraform-created IAM role:

```bash
kubectl get sa aws-load-balancer-controller -n kube-system -o yaml
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

1. Verify ALB Ingress routing.
2. Re-test HPA through the Ingress address.
3. Add Route 53 and ACM TLS for HTTPS.
