# CI Workflow Reference

Workflow file:

```text
.github/workflows/ci.yml
```

## When It Runs

- Push to `main`
- Pull request targeting `main`

## Workflow Order

```text
unit-testing ──┐
               ├──> docker build -> smoke test -> Docker Hub push
code-coverage ─┘
                                             |
                                             v
                                   optional EKS deployment
```

The Docker job runs only when tests and coverage pass.

The EKS deployment job runs only when `ENABLE_EKS_DEPLOY` is set to `true`.

## Jobs

### Unit Testing

```text
Checkout code
Set up Node.js 22
npm ci
npm test
Upload test-results.xml
```

Purpose: verify application routes and behavior.

### Code Coverage

```text
Checkout code
Set up Node.js 22
npm ci
npm run coverage
Upload coverage report
```

Purpose: measure how much application code is exercised by tests.

### Docker

```text
Build app image
Run app container
Call GET /live
Log in to Docker Hub
Push image
```

The smoke test verifies that the new image starts and responds to HTTP requests.

MongoDB is not included in the app image. The CI smoke test uses the app's fallback planet data.

## Docker Tags

Each push to `main` publishes:

```text
aunghtetlwin/solar-system-app:<git-commit-sha>
aunghtetlwin/solar-system-app:latest
```

The commit SHA tag identifies the exact source revision. `latest` identifies the newest successful `main` build.

## GitHub Secrets

Required repository secrets:

```text
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
```

The token allows the GitHub runner to push images to Docker Hub.

## Pull Requests

Pull requests run tests, coverage, build, and smoke testing.

They do not log in or push images to Docker Hub.

## EKS Deployment

The `deploy-eks` job:

```text
Gets temporary AWS credentials through GitHub OIDC
Configures kubectl for solar-system-eks
Applies kubernetes/eks manifests
Deploys the commit SHA image
Waits for the Deployment rollout
Calls the external /live endpoint
```

Required GitHub repository variables:

```text
ENABLE_EKS_DEPLOY
AWS_ROLE_ARN
```

Keep this disabled while EKS is destroyed:

```text
ENABLE_EKS_DEPLOY=false
```

After Terraform creates the infrastructure and GitHub OIDC role:

```bash
terraform output -raw github_actions_deploy_role_arn
```

Set:

```text
AWS_ROLE_ARN=<Terraform output>
ENABLE_EKS_DEPLOY=true
```

The deploy job uses:

```text
aunghtetlwin/solar-system-app:<git-commit-sha>
```

This deploys the exact image built by the same workflow.

## Current Limitation

The EKS deployment requires the Terraform infrastructure and OIDC role to exist. The job is skipped when deployment is disabled.

```text
ENABLE_EKS_DEPLOY=false -> CI and Docker publishing only
ENABLE_EKS_DEPLOY=true  -> CI, Docker publishing, and EKS deployment
```
