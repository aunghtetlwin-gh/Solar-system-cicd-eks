# Architecture Diagram Prompt

Use this prompt with ChatGPT or another diagram tool to generate a clean architecture diagram for this project.

```text
Create a professional cloud architecture diagram for my DevOps portfolio project named "Solar System CI/CD on AWS EKS".

Show this as an end-to-end three-tier containerized application.

Include these main sections:

1. Developer and source control
- Developer laptop
- GitHub repository
- GitHub Actions CI/CD
- GitHub Actions OIDC authentication to AWS

2. CI/CD and image registry
- GitHub Actions runs unit tests and coverage
- GitHub Actions builds Docker image
- GitHub Actions pushes image to Docker Hub repository: aunghtetlwin/solar-system-app
- GitHub Actions updates only the dev Kustomize image tag automatically
- Manual promote-prod workflow copies the tested dev image tag into the prod overlay

3. Infrastructure as Code
- Terraform modules:
  - VPC module
  - EKS module
  - IAM module
  - DNS module
- Terraform creates VPC, public/private subnets, NAT Gateway, EKS, node group, IAM roles, Route 53 hosted zone, and ACM certificate

4. AWS networking and DNS
- Cloudflare manages root domain: aunghtetlwin.com
- Cloudflare delegates solar-system.aunghtetlwin.com to Route 53 using NS records
- Route 53 manages:
  - solar-system.aunghtetlwin.com
  - dev.solar-system.aunghtetlwin.com
- ACM provides TLS certificate for HTTPS
- AWS Load Balancer Controller creates ALBs from Kubernetes Ingress resources

5. AWS EKS cluster
- EKS cluster inside VPC
- Public subnets contain internet-facing ALBs
- Private subnets contain EKS worker nodes
- NAT Gateway allows private nodes outbound internet access
- EBS CSI driver provisions EBS volumes for MongoDB PVC
- Metrics Server supports HPA

6. Kubernetes GitOps
- Argo CD installed in argocd namespace
- Argo CD applications:
  - solar-system-platform
  - solar-system-dev
  - solar-system-prod
- Dev namespace auto-syncs from kubernetes/overlays/dev
- Prod namespace is manually promoted/synced from kubernetes/overlays/prod

7. Application tier
- Node.js Express Solar System app
- Two replicas by default
- Kubernetes Deployment, Service, Ingress, HPA
- Health endpoints:
  - /live
  - /ready
  - /os

8. Data tier
- MongoDB pod in Kubernetes
- MongoDB Service
- MongoDB Secret for credentials
- MongoDB seed Job
- EBS-backed PVC for /data/db

9. Observability
- kube-prometheus-stack
- Prometheus
- Grafana
- Kubernetes workload dashboards
- HPA and pod metrics
- Load testing with hey against dev ALB

Show the request flow:
User browser -> Cloudflare DNS -> Route 53 -> ALB Ingress -> Kubernetes Service -> Node.js pods -> MongoDB Service -> MongoDB pod/PVC

Show the deployment flow:
Developer push -> GitHub Actions -> Docker Hub -> dev Kustomize tag update -> Argo CD dev auto-sync -> manual promote-prod workflow -> Argo CD prod sync

Design style:
- Use AWS official-style icons where possible
- Group AWS resources inside an AWS Cloud boundary
- Group Kubernetes resources inside an EKS cluster boundary
- Show separate namespaces for argocd, solar-system-dev, solar-system-prod, and monitoring
- Use arrows for both traffic flow and CI/CD flow
- Keep the diagram clean enough for a portfolio presentation and screen sharing
```
