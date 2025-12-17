#!/bin/bash
set -e
set -u

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_success() { echo -e "${GREEN}✓${NC} $1"; }
echo_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
echo_error() { echo -e "${RED}✗${NC} $1"; }

# Check if .env exists
if [ ! -f .env ]; then
    echo_error ".env file not found"
    echo "Please create .env from .env.example and fill in your details"
    exit 1
fi

# Source .env
# shellcheck source=../.env
source .env

# Validate and set git config
if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
    echo_warning "GIT_NAME or GIT_EMAIL not set in .env"
    echo "Git user configuration skipped. Please update .env and run 'make install' again"
    exit 0
fi

# Set git config
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

echo_success "Git configured: $GIT_NAME <$GIT_EMAIL>"
