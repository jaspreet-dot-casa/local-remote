#!/bin/bash
#==============================================================================
# delta (git-delta) Installer
#
# A syntax-highlighting pager for git, diff, and grep output
# https://github.com/dandavison/delta
#
# Usage: ./delta.sh [install|update|verify|version]
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

PACKAGE_NAME="delta"
GITHUB_REPO="dandavison/delta"
INSTALL_PATH="/usr/local/bin/delta"

is_installed() { command_exists delta; }

get_installed_version() {
    if is_installed; then
        delta --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
    fi
}

get_desired_version() {
    [[ -f "${PROJECT_ROOT}/config.env" ]] && source "${PROJECT_ROOT}/config.env"
    local version="${PACKAGE_DELTA_VERSION:-latest}"
    [[ "$version" == "latest" ]] && resolve_version "latest" "$GITHUB_REPO" || echo "$version"
}

do_install() {
    local version="$1"
    local arch=$(get_github_arch)

    log_info "Installing delta v${version}..."

    # delta uses different naming: delta-VERSION-ARCH-unknown-linux-gnu.tar.gz
    local url="https://github.com/${GITHUB_REPO}/releases/download/${version}/delta-${version}-${arch}-unknown-linux-gnu.tar.gz"

    local tmp_dir=$(mktemp -d)
    trap "rm -rf $tmp_dir" EXIT

    download_or_print "$url" "${tmp_dir}/delta.tar.gz"

    if ! is_dry_run; then
        tar -xzf "${tmp_dir}/delta.tar.gz" -C "$tmp_dir"
        sudo install -m 755 "${tmp_dir}/delta-${version}-${arch}-unknown-linux-gnu/delta" "$INSTALL_PATH"
    fi

    update_lock "$PACKAGE_NAME" "$version"
    log_success "delta v${version} installed"
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
    # Delta is configured via git config, not shell
    log_debug "delta configured via git config (see configure-git.sh)"
}

main() {
    parse_dry_run_flag "$@"
    local action="${1:-install}"

    [[ -f "${PROJECT_ROOT}/config.env" ]] && source "${PROJECT_ROOT}/config.env"
    [[ "${PACKAGE_DELTA_ENABLED:-true}" != "true" ]] && { log_info "delta disabled"; return 0; }

    case "$action" in
        install|update)
            local desired=$(get_desired_version)
            if is_installed; then
                local current=$(get_installed_version)
                needs_update "$current" "$desired" && do_install "$desired" || log_success "delta v${current} up to date"
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
