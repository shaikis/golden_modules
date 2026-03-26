#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# build.sh — Package the Lambda handler into handler.zip
#
# Usage:
#   cd solutions/bedrock-entity-recognition/lambda_src
#   bash build.sh
#
# The resulting handler.zip is referenced by the tf-aws-lambda module via
# the `filename` input variable.
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Packaging Lambda handler..."
zip -j handler.zip handler.py
echo "Created: ${SCRIPT_DIR}/handler.zip"
