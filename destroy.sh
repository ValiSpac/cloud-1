#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "WARNING: This will remove ALL deployed resources!"


read -p "Are you sure? (yes/no)" confirm

if [[ "$confirm" != "yes" ]]; then
    echo "Cancelled"
    exit 0
fi

cd "${SCRIPT_DIR}"
ansible-playbook playbooks/destroy.yml -i inventory/hosts.yml
