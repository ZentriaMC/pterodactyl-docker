#!/usr/bin/env bash
set -euo pipefail

docker build \
	-t pterodactyl-panel \
	.
