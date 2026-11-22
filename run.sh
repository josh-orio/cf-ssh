#!/usr/bin/env bash
# Usage: ./run.sh [terraform args...]   e.g. ./run.sh plan, ./run.sh apply, ./run.sh output -raw tunnel_token
# Defaults to "apply" when no args are given.
set -euo pipefail
cd "$(dirname "$0")"

[ -f .env ] || { echo "Missing .env" >&2; exit 1; }

# Export every variable defined in .env so Terraform can see it
set -a
source .env
set +a

[ -d .terraform ] || terraform init

if [ $# -eq 0 ]; then set -- apply; fi
exec terraform "$@"
