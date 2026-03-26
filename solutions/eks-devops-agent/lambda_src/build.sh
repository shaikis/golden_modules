#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
echo "Packaging DevOps Agent custom resource handler..."
zip -j handler.zip handler.py
echo "Done: handler.zip"
