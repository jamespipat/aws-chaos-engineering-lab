#!/usr/bin/env bash
# Exercises check-sharing-scrub.sh with invented identifiers.
set -euo pipefail

script="$(cd "$(dirname "$0")" && pwd)/check-sharing-scrub.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failures=0

fresh_repo() {
  rm -rf "$work/repo"
  mkdir -p "$work/repo"
  git -C "$work/repo" init -q -b main
  printf 'terraform.tfvars\n' > "$work/repo/.gitignore"
  printf 'region = var.region\naccount = "000000000000"\nexample = "123456789012"\ncontact = "you@example.com"\nhost = "203.0.113.10"\n' > "$work/repo/clean.tf"
}

expect() {
  local want="$1" name="$2"
  shift 2
  if "$@" >/dev/null 2>&1; then got=pass; else got=fail; fi
  if [[ "$got" == "$want" ]]; then
    echo "ok   $name"
  else
    echo "FAIL $name (wanted $want, got $got)"
    failures=$((failures + 1))
  fi
}

fresh_repo
expect pass "clean input with synthetic placeholders" "$script" --root "$work/repo"

fresh_repo
# Fixtures are split so this file holds no matchable literal.
printf 'owner = "%s%s"\n' "111122" "223333" > "$work/repo/leak.tf"
expect fail "concrete account id" "$script" --root "$work/repo"

fresh_repo
printf 'host = "orders.abc123.us-west-2.%s.amazonaws.com"\n' "rds" > "$work/repo/leak.tf"
expect fail "resource endpoint" "$script" --root "$work/repo"

fresh_repo
printf 'mail = "someone%sinvented-corp.test"\n' "@" > "$work/repo/leak.md"
expect fail "real-looking email" "$script" --root "$work/repo"

fresh_repo
printf 'ip = "%s.4.4"\n' "8.8" > "$work/repo/leak.md"
expect fail "public ipv4" "$script" --root "$work/repo"

fresh_repo
printf 'Invented-Corp\n' > "$work/deny"
printf 'brand = "invented-corp lab"\n' > "$work/repo/leak.md"
expect fail "denylisted text, case-insensitive" "$script" --root "$work/repo" --denylist "$work/deny"

fresh_repo
expect fail "missing denylist file" "$script" --root "$work/repo" --denylist "$work/does-not-exist"

fresh_repo
printf 'state_bucket = "x"\n' > "$work/repo/terraform.tfvars"
git -C "$work/repo" add -f terraform.tfvars clean.tf .gitignore
expect fail "ignored tfvars forced into the index" "$script" --root "$work/repo" --scope index

fresh_repo
git -C "$work/repo" add clean.tf .gitignore
expect pass "clean index" "$script" --root "$work/repo" --scope index

if [[ "$failures" -ne 0 ]]; then
  echo "$failures scrub test(s) failed"
  exit 1
fi
echo "scrub tests passed"
