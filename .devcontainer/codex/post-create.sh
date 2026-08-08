#!/usr/bin/env bash
set -euo pipefail

cd "${containerWorkspaceFolder:-$(pwd)}"

echo "Installing workspace npm dependencies..."
npm install

echo "Syncing Python environment with uv..."
uv sync

echo "Installing Codex CLI..."
npm install -g @openai/codex@latest

echo "Codex post-create complete."
codex --version || true
uv --version || true
python --version || true
