# CI Workflow Reference

  Use uses when calling an existing reusable GitHub Action:

  uses: actions/checkout@v6
  uses: docker/setup-buildx-action@v4

  Use run when executing commands:

  run: npm test
  run: docker run ...
  run: sed -i ...
  run: git commit ...

  A single step cannot normally use both uses and run. Each step chooses either a reusable action or shell commands.

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
                                   optional dev GitOps tag update
```

The Docker job runs only when tests and coverage pass.

The dev GitOps update job runs only when `ENABLE_GITOPS_UPDATE` is set to `true`.

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

## GitOps Deployment

The `update-gitops-dev` job:

```text
Updates kubernetes/overlays/dev/kustomization.yaml
Sets the dev image tag to the Git commit SHA
Commits the dev overlay update back to main with [skip ci]
Argo CD detects the Git change
Argo CD syncs the dev application to EKS
```

Required GitHub repository variables:

```text
ENABLE_GITOPS_UPDATE
```

Keep this disabled until Argo CD is installed and the dev Application exists:

```text
ENABLE_GITOPS_UPDATE=false
```

Set:

```text
ENABLE_GITOPS_UPDATE=true
```

The Docker image still uses:

```text
aunghtetlwin/solar-system-app:<git-commit-sha>
```

This deploys the exact image built by the same workflow after Argo CD syncs.

## Dev And Prod Promotion

Dev is updated automatically by CI:

```text
main push -> image build -> dev overlay image tag commit -> Argo CD dev auto-sync
```

Prod is promoted by Git:

```text
copy tested dev image tag into kubernetes/overlays/prod/kustomization.yaml
open PR
merge PR
Argo CD prod syncs from Git
```

## Current Limitation

Argo CD must be installed in the cluster before GitOps sync can happen. The job is skipped when GitOps image updates are disabled.

```text
ENABLE_GITOPS_UPDATE=false -> CI and Docker publishing only
ENABLE_GITOPS_UPDATE=true  -> CI, Docker publishing, and dev overlay updates
```
