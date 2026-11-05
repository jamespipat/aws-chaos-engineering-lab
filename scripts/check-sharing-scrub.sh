#!/usr/bin/env bash
# Fails if the repository contains identifiers that should not be shared.
#
# Generic mode looks for concrete account IDs, resource endpoints, account ARNs,
# email addresses, public IPv4 addresses, private keys, and forbidden file types.
# Publication mode also matches a private denylist file, one fixed string per line.
# Findings print file paths and categories only, never the matched text.
#
# Usage: check-sharing-scrub.sh [--scope worktree|index|head] [--denylist FILE]
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
scope="worktree"
denylist=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope) scope="${2:-}"; shift 2 ;;
    --denylist) denylist="${2:-}"; shift 2 ;;
    --root) root="${2:-}"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -n "$denylist" && ! -s "$denylist" ]]; then
  echo "denylist file is missing or empty" >&2
  exit 2
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
tree="$work/tree"
mkdir -p "$tree"

list_files() {
  case "$scope" in
    worktree)
      if git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git -C "$root" ls-files --cached --others --exclude-standard
      else
        (cd "$root" && find . -type f -not -path './.git/*' -not -path '*/node_modules/*' | sed 's|^\./||')
      fi
      ;;
    index) git -C "$root" ls-files --cached ;;
    head) git -C "$root" ls-tree -r --name-only HEAD ;;
    *) echo "unknown scope: $scope" >&2; exit 2 ;;
  esac
}

list_files | sort -u > "$work/files"
while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  mkdir -p "$tree/$(dirname "$path")"
  case "$scope" in
    worktree) [[ -f "$root/$path" ]] && cp "$root/$path" "$tree/$path" ;;
    index) git -C "$root" show ":$path" > "$tree/$path" ;;
    head) git -C "$root" show "HEAD:$path" > "$tree/$path" ;;
  esac
done < "$work/files"

failed=0
report() {
  echo "scrub: $1: $2"
  failed=1
}

# Forbidden file classes, checked by path.
while IFS= read -r path; do
  case "$path" in
    *.tfvars|*.tfvars.json|*.tfstate|*.tfstate.*|*.tfplan|backend.hcl|*/backend.hcl|*_override.tf|.plans/*|*/.terraform/*|.terraform/*|evidence/private/*|carousel/*|*/node_modules/*|node_modules/*|*.key|.env|.env.*)
      report "forbidden file" "$path" ;;
    *.pem)
      [[ "$path" == "app/certs/global-bundle.pem" ]] || report "forbidden file" "$path" ;;
  esac
done < "$work/files"

if [[ -f "$tree/app/certs/global-bundle.pem" ]] && grep -q "PRIVATE KEY" "$tree/app/certs/global-bundle.pem"; then
  report "private key" "app/certs/global-bundle.pem"
fi

# Placeholders that are allowed: the synthetic account 000000000000, the AWS
# documentation account 123456789012, example.com addresses, and the documentation
# IPv4 ranges.
scan() {
  local category="$1" pattern="$2"
  local hits
  hits="$(cd "$tree" && rg --hidden -l -P --glob '!**/package-lock.json' --glob '!**/.terraform.lock.hcl' -e "$pattern" . 2>/dev/null || true)"
  while IFS= read -r hit; do
    if [[ -n "$hit" ]]; then report "$category" "${hit#./}"; fi
  done <<< "$hits"
}

scan "account id" '(?<![0-9A-Za-z])(?!000000000000|123456789012)[0-9]{12}(?![0-9A-Za-z])'
scan "account arn" 'arn:aws[a-z-]*:[a-z0-9-]+:[a-z0-9-]*:(?!000000000000|123456789012)[0-9]{12}:'
scan "resource endpoint" '[a-z0-9-]+\.(rds|elb|eks)\.amazonaws\.com|[a-z0-9]+\.gr[0-9]\.[a-z0-9-]+\.eks\.amazonaws\.com|[0-9]{12}\.dkr\.ecr'
scan "email address" '[A-Za-z0-9._%+-]+@(?!example\.(com|org|net)\b)[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}'
scan "public ipv4" '(?<![0-9.])(?!(10|127)\.)(?!172\.(1[6-9]|2[0-9]|3[01])\.)(?!192\.168\.)(?!169\.254\.)(?!0\.0\.0\.0)(?!203\.0\.113\.)(?!198\.51\.100\.)(?!192\.0\.2\.)(25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])){3}(?![0-9.])'
scan "private key" '-----BEGIN [A-Z ]*PRIVATE KEY-----'

if [[ -n "$denylist" ]]; then
  hits="$(cd "$tree" && rg --hidden -l -i -F -f "$denylist" . 2>/dev/null || true)"
  while IFS= read -r hit; do
    if [[ -n "$hit" ]]; then report "denylisted text" "${hit#./}"; fi
  done <<< "$hits"
  if rg -i -F -f "$denylist" "$work/files" >/dev/null 2>&1; then
    report "denylisted path" "(a file path matches the denylist)"
  fi
fi

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi
echo "scrub: clean ($scope$([[ -n "$denylist" ]] && echo ", with denylist"))"
