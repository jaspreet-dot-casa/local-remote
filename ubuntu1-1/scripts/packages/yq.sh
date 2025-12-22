#!/bin/bash
#==============================================================================
# yq Installer
#
# A portable command-line YAML processor
# https://github.com/mikefarah/yq
#
# Usage: ./yq.sh [install|update|verify|version]
#==============================================================================

set -e
set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${SCRIPT_DIR}/../lib/core.sh"
source "${SCRIPT_DIR}/../lib/version.sh"
source "${SCRIPT_DIR}/../lib/lock.sh"
source "${SCRIPT_DIR}/../lib/health.sh"
source "${SCRIPT_DIR}/../lib/dryrun.sh"

PACKAGE_NAME="yq"
GITHUB_REPO="mikefarah/yq"
INSTALL_PATH="/usr/local/bin/yq"

is_installed() { command_exists yq; }

get_installed_version() {
    if is_installed; then
        yq --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
    fi
}

get_desired_version() {
    [[ -f "${PROJECT_ROOT}/config.env" ]] && source "${PROJECT_ROOT}/config.env"
    local version="${PACKAGE_YQ_VERSION:-latest}"
    [[ "$version" == "latest" ]] && resolve_version "latest" "$GITHUB_REPO" || echo "$version"
}

do_install() {
    local version="$1"
    local arch=$(get_arch)  # Uses amd64/arm64 naming

    log_info "Installing yq v${version}..."

    # yq naming: yq_linux_amd64
    local url="https://github.com/${GITHUB_REPO}/releases/download/v${version}/yq_linux_${arch}"

    local tmp_dir=$(mktemp -d)
    trap "rm -rf $tmp_dir" EXIT

    download_or_print "$url" "${tmp_dir}/yq"

    if ! is_dry_run; then
        chmod +x "${tmp_dir}/yq"
        sudo install -m 755 "${tmp_dir}/yq" "$INSTALL_PATH"
    fi

    update_lock "$PACKAGE_NAME" "$version"
    log_success "yq v${version} installed"
}

verify() {
    if ! is_installed; then
        health_fail "$PACKAGE_NAME" "not installed"
        return 1
    fi
    health_pass "$PACKAGE_NAME" "v$(get_installed_version)"
    return 0
}

create_shell_config() {
    # yq doesn't need shell config
    log_debug "yq doesn't require shell configuration"
}

main() {
    parse_dry_run_flag "$@"
    local action="${1:-install}"

    [[ -f "${PROJECT_ROOT}/config.env" ]] && source "${PROJECT_ROOT}/config.env"
    [[ "${PACKAGE_YQ_ENABLED:-true}" != "true" ]] && { log_info "yq disabled"; return 0; }

    case "$action" in
        install|update)
            local desired=$(get_desired_version)
            if is_installed; then
                local current=$(get_installed_version)
                needs_update "$current" "$desired" && do_install "$desired" || log_success "yq v${current} up to date"
            else
                do_install "$desired"
            fi
            create_shell_config
            verify
            ;;
        verify) verify ;;
        version) is_installed && get_installed_version || { echo "not installed"; return 1; } ;;
        *) echo "Usage: $0 [install|update|verify|version] [--dry-run]"; exit 1 ;;
    esac

    is_dry_run && print_dry_run_summary
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
