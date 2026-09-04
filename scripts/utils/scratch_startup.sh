#!/usr/bin/env bash
# Creates a scratch org and installs this project's required unlocked packages.
# Keep the package list in sync with README.md's "Dependencies / Salesforce Libraries" table.

set -Eeuo pipefail

readonly PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly DEFAULT_ALIAS='moxskr-scratch'
readonly DEFAULT_DURATION_DAYS=7
readonly DEFAULT_DEFINITION_FILE='config/project-scratch-def.json'

ORG_ALIAS="$DEFAULT_ALIAS"
DURATION_DAYS="$DEFAULT_DURATION_DAYS"
DEFINITION_FILE="$DEFAULT_DEFINITION_FILE"
DEV_HUB=''
ORG_CREATED=false
CURRENT_STEP='initializing'

usage() {
	cat <<'EOF'
Usage: scripts/utils/scratch_startup.sh [options]

Create a scratch org, set it as the default target org, and install the
unlocked package dependencies listed in this repository's README.

Options:
  --alias NAME             Scratch org alias (default: moxskr-scratch)
  --duration-days DAYS     Scratch org lifetime from 1 to 30 days (default: 7)
  --dev-hub ALIAS          Dev Hub alias or username (default: configured Dev Hub)
  --definition-file PATH   Scratch definition file (default: config/project-scratch-def.json)
  --help                   Show this help message
EOF
}

fail() {
	printf 'Error: %s\n' "$*" >&2
	exit 1
}

on_error() {
	local exit_code=$?

	if [[ "$ORG_CREATED" == true ]]; then
		printf '\nFailed while %s. Scratch org "%s" was preserved for diagnosis.\n' \
			"$CURRENT_STEP" "$ORG_ALIAS" >&2
	else
		printf '\nFailed while %s.\n' "$CURRENT_STEP" >&2
	fi

	exit "$exit_code"
}

trap on_error ERR

while (($# > 0)); do
	case "$1" in
		--alias)
			(($# >= 2)) || fail '--alias requires a value.'
			ORG_ALIAS="$2"
			shift 2
			;;
		--duration-days)
			(($# >= 2)) || fail '--duration-days requires a value.'
			DURATION_DAYS="$2"
			shift 2
			;;
		--dev-hub)
			(($# >= 2)) || fail '--dev-hub requires a value.'
			DEV_HUB="$2"
			shift 2
			;;
		--definition-file)
			(($# >= 2)) || fail '--definition-file requires a value.'
			DEFINITION_FILE="$2"
			shift 2
			;;
		--help)
			usage
			exit 0
			;;
		*)
			fail "Unknown option: $1. Run with --help for usage."
			;;
	esac
done

[[ -n "$ORG_ALIAS" ]] || fail '--alias cannot be empty.'
[[ "$DURATION_DAYS" =~ ^[0-9]+$ ]] || fail '--duration-days must be a whole number from 1 to 30.'
((DURATION_DAYS >= 1 && DURATION_DAYS <= 30)) || fail '--duration-days must be from 1 to 30.'

cd "$PROJECT_ROOT"

if [[ "$DEFINITION_FILE" != /* ]]; then
	DEFINITION_FILE="$PROJECT_ROOT/$DEFINITION_FILE"
fi

command -v sf >/dev/null 2>&1 || fail 'Salesforce CLI (sf) is not installed or is not on PATH.'
[[ -f "$DEFINITION_FILE" ]] || fail "Scratch definition file not found: $DEFINITION_FILE"

DEV_HUB_ARGS=()
if [[ -n "$DEV_HUB" ]]; then
	DEV_HUB_ARGS=(--target-dev-hub "$DEV_HUB")
	printf 'Using Dev Hub: %s\n' "$DEV_HUB"
else
	CURRENT_STEP='checking the configured Dev Hub'
	DEV_HUB_CONFIG="$(sf config get target-dev-hub --json)"
	if [[ ! "$DEV_HUB_CONFIG" =~ \"value\"[[:space:]]*:[[:space:]]*\"[^\"]+\" ]]; then
		fail 'No default Dev Hub is configured. Run "sf org login web --set-default-dev-hub" or pass --dev-hub.'
	fi
	printf 'Using the configured default Dev Hub.\n'
fi

# Name, version, and subscriber package version ID from README.md.
PACKAGES=(
	'SOQL Lib|6.11.1|04tP6000003On13IAC'
	'DML Lib|3.1.0|04tP60000036moDIAQ'
	'Async Lib|2.7.0|04tP6000003Sp7WIAS'
	'HTTP Mock Lib|1.2.0|04tP6000002EJBJIA4'
	'Test Lib|0.1.0 BETA|04tP600000390yLIAQ'
	'Trigger Actions Framework|0.3.4-1|04tKY000000R0yHYAS'
	'Nebula Logger|v4.19.1|04tg7000000GqibAAC'
)

CURRENT_STEP="creating scratch org \"$ORG_ALIAS\""
printf 'Creating scratch org "%s" for %s day(s)...\n' "$ORG_ALIAS" "$DURATION_DAYS"
sf org create scratch \
	--definition-file "$DEFINITION_FILE" \
	--alias "$ORG_ALIAS" \
	--set-default \
	--duration-days "$DURATION_DAYS" \
	--wait 10 \
	"${DEV_HUB_ARGS[@]}"
ORG_CREATED=true

for package in "${PACKAGES[@]}"; do
	IFS='|' read -r package_name package_version package_id <<<"$package"
	CURRENT_STEP="installing $package_name ($package_version)"
	printf 'Installing %s %s...\n' "$package_name" "$package_version"
	sf package install \
		--package "$package_id" \
		--target-org "$ORG_ALIAS" \
		--security-type AdminsOnly \
		--wait 20 \
		--no-prompt
done

printf '\nScratch org "%s" is ready and is now the default target org.\n' "$ORG_ALIAS"
