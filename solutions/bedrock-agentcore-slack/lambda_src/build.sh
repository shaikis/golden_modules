#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

echo "Packaging Verification Lambda..."
zip -j verification.zip verification_handler.py

echo "Packaging SQS Integration Lambda..."
zip -j sqs_integration.zip sqs_handler.py

echo "Packaging Agent Integration Lambda..."
zip -j agent_integration.zip agent_handler.py

echo "All Lambda packages created."
