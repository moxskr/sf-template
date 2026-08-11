#!/usr/bin/env bash
set -euo pipefail

cd "${containerWorkspaceFolder:-$(pwd)}"

echo "Installing workspace npm dependencies..."
npm install

echo "Syncing Python environment with uv..."
uv sync

echo "Preparing Cursor state directory..."
# ~/.cursor may be a Docker named volume initially owned by root.
# Ensure the vscode user can create/update Cursor config and state.
sudo mkdir -p "${HOME}/.cursor"
sudo chown -R "$(id -u):$(id -g)" "${HOME}/.cursor"
chmod -R u+rwX "${HOME}/.cursor"

echo "Installing Cursor CLI..."
curl https://cursor.com/install -fsS | bash

# Ensure Cursor agent binaries are on PATH for interactive shells
MARKER='export PATH="$HOME/.local/bin:$PATH"'
for rc in "${HOME}/.bashrc" "${HOME}/.zshrc" "${HOME}/.profile"; do
	touch "${rc}"
	if ! grep -Fq "${MARKER}" "${rc}"; then
		echo "${MARKER}" >> "${rc}"
	fi
done
export PATH="${HOME}/.local/bin:${PATH}"

echo "Cursor post-create complete."
agent --version || cursor-agent --version || true
uv --version || true
python --version || true
