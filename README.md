# Azure AKS GitHub Actions Lab

A practice project for an industry-style CI/CD workflow using GitHub Actions, Terraform, Azure Container Registry (ACR), Azure Kubernetes Service (AKS), Docker, Kubernetes, and Trivy.

## What you will build

1. Terraform provisions a resource group, ACR, AKS, and the AKS kubelet's `AcrPull` role assignment.
2. Pull requests run app smoke tests, Terraform formatting/validation, and Trivy filesystem/IaC scanning.
3. Merges to `main` build a versioned container image, push it to ACR, and deploy it to AKS.
4. Kubernetes uses rolling updates, resource limits, health probes, and a LoadBalancer Service.

> Cost warning: AKS node VMs, disks, public IPs/load balancers, and ACR may incur charges. This is a learning lab, not a hardened production baseline. Delete resources when finished.

## Repository structure

```text
.
├── app/
│   ├── app.py
│   ├── requirements.txt
│   └── Dockerfile
├── terraform/
│   ├── versions.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── dev.tfvars.example
├── k8s/deployment.yaml
└── .github/workflows/
    ├── ci.yml
    └── deploy-dev.yml
```

## Prerequisites

- Azure subscription with permission to create resource groups, AKS, ACR, and role assignments.
- Git, Docker, Terraform >= 1.6, Azure CLI, kubectl, and Python 3.12.
- GitHub repository and GitHub Actions enabled.

## Phase 1: Create the repository and feature branch

```bash
git init
git checkout -b feature/initial-aks-platform
git add .
git commit -m "feat: add Azure AKS GitHub Actions lab"
git remote add origin https://github.com/OWNER/REPO.git
git push -u origin feature/initial-aks-platform
```

Create a pull request to `main`. The CI workflow should run before merge. Protect `main` with required pull-request reviews and required CI checks.

## Phase 2: Provision Azure infrastructure locally

Sign in and select the correct subscription:

```bash
az login
az account list --output table
az account set --subscription "<SUBSCRIPTION_ID>"
az account show --query id -o tsv
```

Create your local variables file:

```bash
cp terraform/dev.tfvars.example terraform/dev.tfvars
# Edit subscription_id in terraform/dev.tfvars
cd terraform
terraform init
terraform fmt -recursive
terraform validate
terraform plan -var-file=dev.tfvars -out=tfplan
terraform apply tfplan
terraform output
```

The AKS Kubernetes version and VM SKU must be available in the selected region. If deployment fails with a version/SKU availability error, check `az aks get-versions --location centralindia -o table` and `az vm list-skus --location centralindia -o table`, then select a supported value.

### Terraform state

For a solo throwaway lab, local state is acceptable. For team use, configure a remote Azure Storage backend with blob state locking/leases, access control, and versioning. Bootstrap the state storage separately, then add a `backend "azurerm" {}` block and migrate with `terraform init -migrate-state`. Do not commit state files or `terraform.tfvars`.

## Phase 3: Configure GitHub OIDC to Azure

Use workload identity federation instead of a long-lived Azure client secret.

1. Create an Entra ID app registration or service principal for GitHub Actions.
2. Add a federated credential whose subject matches your GitHub environment, for example `repo:OWNER/REPO:environment:dev`. The audience is `api://AzureADTokenExchange`.
3. Grant the identity the minimum required permissions. Provisioning Terraform needs permissions to create the resources and role assignments in the target scope. Deployment needs permission to push to ACR and deploy to AKS. Prefer separate identities for infrastructure and deployment in a more mature setup.
4. Add GitHub repository/environment secrets:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`
5. In GitHub, create an environment named `dev` and restrict which branches can deploy to it.

The workflow assumes `terraform/terraform.tfstate` or the configured backend is accessible to the runner. For a remote backend, initialize it with the same backend configuration used when applying Terraform. Do not store state as a repository artifact or commit it.

## Phase 4: Run the deployment pipeline

After Terraform has successfully created the infrastructure and the remote state is configured if applicable:

```bash
git checkout main
git pull
# Make a small change to app/app.py
git checkout -b feature/change-api-message
git add app/app.py
git commit -m "feat: update API response"
git push -u origin feature/change-api-message
```

Open a pull request and confirm the CI workflow passes. Merge to `main` to trigger deployment.

The deploy workflow expects a working Terraform backend and a runner identity with appropriate access. It reads outputs from Terraform state, pushes an image tagged with the commit SHA, then applies the Kubernetes manifest.

## Troubleshooting playbook

### `AADSTS` or Azure login fails
- Check the GitHub OIDC subject exactly matches the federated credential.
- Ensure `permissions: id-token: write` is set.
- Verify tenant, client, and subscription IDs.

### `terraform output` says no state or output
- Run `terraform apply` successfully first.
- Confirm the workflow's backend configuration and working directory match the infrastructure state.

### `unauthorized: authentication required` while pushing to ACR
- Confirm `az acr login` succeeded and the identity has appropriate ACR push permissions, such as `AcrPush` at the registry scope.

### AKS reports `ImagePullBackOff`
- Check image name/tag and `kubectl describe pod -n shop <pod>`.
- Verify the AKS kubelet identity has `AcrPull` on the correct registry.
- Role assignment propagation can take a few minutes.

### Deployment does not become ready
```bash
kubectl get pods -n shop
kubectl describe deployment shop-api -n shop
kubectl logs deployment/shop-api -n shop
kubectl get events -n shop --sort-by=.lastTimestamp
```

### Roll back a failed application release
```bash
kubectl rollout history deployment/shop-api -n shop
kubectl rollout undo deployment/shop-api -n shop
kubectl rollout status deployment/shop-api -n shop
```

## Real-world exercises

1. **Broken build:** deliberately break the health endpoint test. Confirm the pull request fails and no deployment happens.
2. **Security gate:** add a vulnerable or misconfigured test dependency in a disposable branch and observe Trivy results.
3. **Image pull failure:** temporarily deploy a nonexistent image tag in a lab namespace. Diagnose `ImagePullBackOff`, then restore the correct image.
4. **Failed rollout:** deploy a bad readiness-probe path and watch `kubectl rollout status` fail. Restore the previous revision.
5. **Terraform drift:** change a harmless Azure tag manually, run `terraform plan`, and explain the proposed correction.
6. **Branch protection:** verify direct pushes to `main` are blocked and pull requests require CI.
7. **Production approval:** create a separate GitHub `prod` environment with required reviewers and a separate production cluster/state. Never point a production workflow at the dev state.

## Interview questions to practice

- Why use OIDC instead of an Azure client secret?
- What is the difference between Terraform plan and apply?
- How do you prevent concurrent Terraform state changes?
- How does AKS authenticate to pull images from ACR?
- What is the difference between readiness and liveness probes?
- How do rolling updates and `kubectl rollout undo` work?
- How would you secure secrets, state, and deployment permissions?
- How would you promote the same immutable image from dev to staging to production?

## Clean up

When finished, verify you are targeting only the lab subscription and environment:

```bash
cd terraform
terraform destroy -var-file=dev.tfvars
```

Destroying AKS and associated Azure resources may take several minutes. If using remote state, retain the backend storage until Terraform no longer needs it.
