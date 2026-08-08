#!/usr/bin/env bash
set -euo pipefail

cd "${containerWorkspaceFolder:-$(pwd)}"

echo "Installing workspace npm dependencies..."
npm install

echo "Syncing Python environment with uv..."
uv sync

echo "Installing Claude Code CLI..."
# Install to user prefix — postCreate runs as vscode, not root
npm install -g --prefix "${HOME}/.local" @anthropic-ai/claude-code@latest

echo "Claude post-create complete."
claude --version || true
uv --version || true
python --version || true
