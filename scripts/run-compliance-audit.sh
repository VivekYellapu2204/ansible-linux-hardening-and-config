#!/usr/bin/env bash
set -euo pipefail

INVENTORY="${1:-inventories/dynamic-aws-ec2.yml}"

echo "=========================================================="
echo " Starting Fleet CIS Compliance & Security Baseline Audit"
echo " Target Inventory: ${INVENTORY}"
echo "=========================================================="

echo "[1/3] Validating syntax and configuration drift..."
ansible-playbook -i "${INVENTORY}" playbooks/site.yml --syntax-check

echo "[2/3] Performing dry-run check with diff tracking..."
ansible-playbook -i "${INVENTORY}" playbooks/site.yml --check --diff

echo "[3/3] Executing runtime post-rehydration assertions..."
ansible-playbook -i "${INVENTORY}" playbooks/post-rehydration-verify.yml

echo "=========================================================="
echo " Security Baseline Audit Complete: All checks verified."
echo "=========================================================="
