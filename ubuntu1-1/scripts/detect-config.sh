#!/bin/bash
# Detect the appropriate Home Manager flake configuration based on architecture and user
# Outputs the flake configuration name to stdout

set -e
set -u

# Detect architecture and user
ARCH=$(uname -m)
CURRENT_USER="${USER:-$(whoami)}"

# Select appropriate configuration based on architecture and user
if [ "${CURRENT_USER}" = "testuser" ]; then
    # Docker test environment
    if [ "${ARCH}" = "aarch64" ]; then
        FLAKE_CONFIG="testuser"
    else
        FLAKE_CONFIG="testuser-x86"
    fi
else
    # Production/normal environment
    if [ "${ARCH}" = "aarch64" ]; then
        FLAKE_CONFIG="ubuntu-aarch64"
    else
        FLAKE_CONFIG="ubuntu"
    fi
fi

# Output configuration name
echo "${FLAKE_CONFIG}"
