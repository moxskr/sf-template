#!/usr/bin/env bash
set -euo pipefail

cd "${containerWorkspaceFolder:-$(pwd)}"

echo "Installing workspace npm dependencies..."
npm install

echo "Syncing Python environment with uv..."
uv sync

echo "Preparing Claude state directory..."
# ~/.claude may be a Docker named volume initially owned by root.
# Ensure the vscode user can create/update Claude Code config and state.
sudo mkdir -p "${HOME}/.claude"
sudo chown -R "$(id -u):$(id -g)" "${HOME}/.claude"
chmod -R u+rwX "${HOME}/.claude"

echo "Installing Claude Code CLI..."
# Install to user prefix — postCreate runs as vscode, not root
npm install -g --prefix "${HOME}/.local" @anthropic-ai/claude-code@latest

echo "Claude post-create complete."
claude --version || true
uv --version || true
python --version || true
