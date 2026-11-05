#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
failed=0

while IFS= read -r file; do
  if grep -Eq '^[[:space:]]*resource[[:space:]]+"(aws_|kubernetes_|helm_)' "$file"; then
    echo "root contains a raw cloud resource: $file"
    failed=1
  fi
done < <(find "$root/infra/bootstrap" "$root/infra/envs" -path '*/.terraform' -prune -o -name '*.tf' -print)

grep -Eq 'publicly_accessible[[:space:]]*=[[:space:]]*false' "$root/infra/modules/database/main.tf" \
  || { echo "database module must keep publicly_accessible false"; failed=1; }
grep -Eq 'internal[[:space:]]*=[[:space:]]*true' "$root/infra/modules/edge/main.tf" \
  || { echo "edge module must keep the ALB internal"; failed=1; }
grep -Eq 'podName' "$root/infra/modules/fis-experiment/variables.tf" \
  || { echo "FIS pod experiments must require podName"; failed=1; }
grep -Eq 'COUNT\(1\)' "$root/infra/modules/fis-experiment/variables.tf" \
  || { echo "FIS pod experiments must require COUNT(1)"; failed=1; }

for key in name_prefix vpc_id cluster_name database_host queue_url alb_dns_name workload_identities stop_condition_alarm_arns fis_execution_role_arn evidence_bucket_name; do
  grep -Eq "$key" "$root/infra/envs/lab/foundation/outputs.tf" \
    || { echo "platform output is missing $key"; failed=1; }
done

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "terraform structure checks passed"
