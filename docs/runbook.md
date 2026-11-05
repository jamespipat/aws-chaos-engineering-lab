# Runbook

Run every command from the repository root unless a step says otherwise. Save every plan under the gitignored `.plans/` directory and read it before you apply it.

## 0. Inputs

Set the variables from the README. Then confirm the account:

```bash
aws sts get-caller-identity --query Account --output text
```

It must equal `TF_VAR_allowed_account_id`. Every provider refuses any other account.

Pick a VPC CIDR that does not overlap networks you may connect later. The example catalog uses `10.0.0.0/16`.

## 1. State bucket

Terraform will not plan a root with an unconfigured S3 backend, so bootstrap starts on local state. Create the gitignored file `infra/bootstrap/backend_override.tf`:

```hcl
terraform {
  backend "local" {}
}
```

```bash
mkdir -p .plans
terraform -chdir=infra/bootstrap init
terraform -chdir=infra/bootstrap plan -out=../../.plans/bootstrap.tfplan
terraform -chdir=infra/bootstrap apply ../../.plans/bootstrap.tfplan
terraform -chdir=infra/bootstrap output -raw state_bucket_name
```

Copy `backend.hcl.example` to the gitignored `backend.hcl`, then fill in the bucket name and Region. Delete `backend_override.tf`, then migrate:

```bash
terraform -chdir=infra/bootstrap init -migrate-state -backend-config=../../backend.hcl
```

Keep a private copy of the local state until you have confirmed the object exists in the bucket. Then export the bucket name for the later roots:

```bash
export TF_VAR_state_bucket=<bucket name from the output>
```

## 2. Evidence and foundation

```bash
for root in evidence foundation; do
  terraform -chdir=infra/envs/lab/$root init -backend-config=../../../../backend.hcl
  terraform -chdir=infra/envs/lab/$root plan -out=../../../../.plans/$root.tfplan
done
```

Review each plan, then apply it with `terraform apply <plan>`. Foundation takes about 15 minutes, mostly for EKS and RDS. The hourly cost starts here.

## 3. Image and workloads

Read the repository URL from `terraform -chdir=infra/envs/lab/foundation output -json platform`. Build for `linux/amd64`, push the image, and record its digest:

```bash
aws ecr get-login-password | docker login --username AWS --password-stdin <registry>
docker build --platform linux/amd64 -t <repository>:v1 app
docker push <repository>:v1
aws ecr describe-images --repository-name aws-chaos-lab --image-ids imageTag=v1 --query 'imageDetails[0].imageDigest' --output text
export TF_VAR_app_image=<repository>@<digest>
```

Point kubectl at the new cluster (this only writes your local kubeconfig):

```bash
aws eks update-kubeconfig --name aws-chaos-lab --alias aws-chaos-lab
```

Plan and apply `infra/envs/lab/workloads` with the default `load_replicas=0`. The migration job must finish before the API starts:

```bash
kubectl --context aws-chaos-lab -n aws-chaos-lab get jobs,pods
```

## 4. Baseline

Choose a run id, then turn on load:

```bash
export TF_VAR_run_id=run-001
export TF_VAR_evidence_prefix=journal/run-001
export TF_VAR_load_replicas=1
```

Plan and apply workloads again. Wait 10 minutes of warmup, then keep at least 15 minutes of steady state. Set `TF_VAR_detection_p95_ms` to the baseline p95 plus 50, then plan and apply foundation so the detection alarm uses it. That alarm is a signal only. The FIS stop conditions are error rate above 5 percent, p95 above 2 seconds, and a missing heartbeat.

## 5. Experiments

Get the current API pod and the database host:

```bash
kubectl --context aws-chaos-lab -n aws-chaos-lab get pods -l app.kubernetes.io/name=api
terraform -chdir=infra/envs/lab/foundation output -json platform | jq -r .database_host
export TF_VAR_pod_name=<one api pod>
export TF_VAR_latency_sources=<database host>
```

Plan and apply `infra/envs/lab/experiments`. The plan must show `podName` and `COUNT(1)`.

In the FIS console, run a target preview of the pod-delete template. It must resolve to exactly the pod you named. Then start the experiment there. A preview skips the actions, and targets can change between the preview and the real run, so check again right before you start.

After the pod-delete experiment, that pod name is gone. Set `TF_VAR_pod_name` to a current pod, plan and apply experiments again, preview the latency template, and start it.

Stopping an experiment does not bring back a deleted pod or undo writes.

## 6. Evidence

Download the journal for your run id from the evidence bucket into a gitignored folder such as `evidence/private/`. Then summarize your time windows:

```bash
python3 scripts/summarize_evidence.py evidence/private/journal windows.json
```

`windows.json` maps a window name to UTC `start` and `end` values. The script prints counts and percentiles. It does not build the full results file, so write your own sanitized results by hand.

Turn on the verifier with `TF_VAR_enable_verify_job=true` and the same evidence prefix, then apply workloads. Read its log:

```bash
kubectl --context aws-chaos-lab -n aws-chaos-lab logs job/verify
```

## 7. Destroy

Set `TF_VAR_load_replicas=0`, then destroy in this order, reviewing each destroy plan:

```bash
for root in experiments workloads foundation; do
  terraform -chdir=infra/envs/lab/$root plan -destroy -out=../../../../.plans/destroy-$root.tfplan
done
```

Apply each destroy plan with `terraform apply <plan>`.

The evidence bucket has `force_destroy = false` and versioning on. Export what you want to keep, delete every object version and delete marker, then destroy `infra/envs/lab/evidence`.

The state bucket holds its own state. Migrate bootstrap state back to a local backend first, then destroy bootstrap. Keep that local state until the bucket is gone.
