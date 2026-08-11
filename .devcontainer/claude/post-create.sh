#!/usr/bin/env bash
set -euo pipefail

cd "${containerWorkspaceFolder:-$(pwd)}"

echo "Installing workspace npm dependencies..."
npm install

echo "Syncing Python environment with uv..."
uv sync

echo "Preparing Docker volume directories..."
# Fresh named volumes may mount as root; ensure vscode can write state and config.
for dir in \
	"${HOME}/.sf" \
	"${HOME}/.sfdx" \
	"${HOME}/.ssh" \
	"${HOME}/.claude"
do
	sudo mkdir -p "${dir}"
	sudo chown -R "$(id -u):$(id -g)" "${dir}"
	chmod -R u+rwX "${dir}"
done

echo "Installing Claude Code CLI..."
# Install to user prefix — postCreate runs as vscode, not root
npm install -g --prefix "${HOME}/.local" @anthropic-ai/claude-code@latest

echo "Claude post-create complete."
claude --version || true
uv --version || true
python --version || true
