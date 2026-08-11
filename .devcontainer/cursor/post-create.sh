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
	"${HOME}/.cursor"
do
	sudo mkdir -p "${dir}"
	sudo chown -R "$(id -u):$(id -g)" "${dir}"
	chmod -R u+rwX "${dir}"
done

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
