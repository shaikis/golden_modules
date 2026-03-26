#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

echo "Packaging Embedding Lambda..."
zip -j embedding.zip embedding_handler.py
echo "  Created: embedding.zip"

echo "Packaging Chatbot Lambda..."
zip -j chatbot.zip chatbot_handler.py
echo "  Created: chatbot.zip"

echo "All Lambda packages built successfully."
echo ""
echo "NEXT: run terraform apply to deploy."
