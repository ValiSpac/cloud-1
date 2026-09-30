#!/bin/bash
# Cloud-1 Deployment Script
# Usage: ./deploy.sh [options]
set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# helper functions
log_info() {
    echo -e "[INFO] $1"
}

log_success() {
    echo -e "[SUCCESS] $1"
}

log_warning() {
    echo -e "[WARNING] $1"
}

log_error() {
    echo -e "[ERROR] $1"
}

check_dependencies() {
    log_info "Checking dependencies..."

    if ! command -v ansible &> /dev/null; then
        log_error "Ansible is not installed (pip3 install ansible)"
        exit 1
    fi

    if ! command -v ansible-galaxy &> /dev/null; then
        log_error "ansible-galaxy is not available"
        exit 1
    fi

    log_success "All dependencies found"
}

install_ansible_collections() {
    log_info "Installing Ansible collections..."
    ansible-galaxy collection install community.docker --force
    ansible-galaxy collection install ansible.posix --force
    log_success "Collections installed"
}

check_env_vars() {
    log_info "Checking environment variables..."

    local missing_vars=()

    [[ -z "${SERVER_IP:-}" ]] && missing_vars+=("SERVER_IP")
    [[ -z "${DB_ROOT_PASSWORD:-}" ]] && missing_vars+=("DB_ROOT_PASSWORD")
    [[ -z "${DB_PASSWORD:-}" ]] && missing_vars+=("DB_PASSWORD")
    [[ -z "${WP_ADMIN_PASSWORD:-}" ]] && missing_vars+=("WP_ADMIN_PASSWORD")
    [[ -z "${WP_USER_PASSWORD:-}" ]] && missing_vars+=("WP_USER_PASSWORD")

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        echo "Set them with:"
        echo "  export SERVER_IP=\"your.server.ip\""
        echo "  export DB_ROOT_PASSWORD=\"secure_password\""
        echo "  export DB_PASSWORD=\"secure_password\""
        echo "  export WP_ADMIN_PASSWORD=\"secure_password\""
        echo "  export WP_USER_PASSWORD=\"secure_password\""
        echo ""
        echo "Optional:"
        echo "  export DOMAIN_NAME=\"domainname.duckdns.org\""
        echo "  export SSH_KEY_PATH=\"~/.ssh/id_ed25519\""
        exit 1
    fi

    log_success "All required environment variables are set"
}

run_playbook() {
    local playbook="${1:-site.yml}"
    local extra_args="${2:-}"

    log_info "Running playbook: ${playbook}"

    cd "${SCRIPT_DIR}"

    ansible-playbook "playbooks/${playbook}" \
        -i inventory/hosts.yml \
        ${extra_args} \
        -v
}

# Main script
usage() {
    echo "Usage: $0 [command] [options]"
    echo "Commands:"
    echo "  deploy    Full deployment (default)"
    echo "  setup     Server setup only (no app)"
    echo "  app       Deploy app only (after setup)"
    echo "  destroy   Remove everything"
    echo "  status    Check deployment status"
    echo "Options:"
    echo "  -h, --help    Show help"
    echo "  -v, --verbose Verbose output"
    echo "Required Environment Variables:"
    echo "  SERVER_IP         - Target server IP address"
    echo "  DB_ROOT_PASSWORD  - MariaDB root password"
    echo "  DB_PASSWORD       - MariaDB user password"
    echo "  WP_ADMIN_PASSWORD - WordPress admin password"
    echo "  WP_USER_PASSWORD  - WordPress user password"
    echo "Optional Environment Variables:"
    echo "  DOMAIN_NAME   - Domain name"
    echo "  SSH_KEY_PATH  - Path to SSH key"
    echo "  FTP_PASSWORD  - FTP password"
}

main() {
    local command="${1:-deploy}"
    local verbose=""

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                verbose="-vv"
                shift
                ;;
            deploy|setup|app|destroy|status)
                command="$1"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    echo "Cloud-1 Deployment Script"
    check_dependencies

    case "$command" in
        deploy)
            check_env_vars
            install_ansible_collections
            run_playbook "site.yml" "$verbose"
            ;;
        setup)
            check_env_vars
            install_ansible_collections
            run_playbook "setup.yml" "$verbose"
            ;;
        app)
            check_env_vars
            run_playbook "deploy.yml" "$verbose"
            ;;
        destroy)
            run_playbook "destroy.yml" "$verbose"
            ;;
        status)
            log_info "Checking deployment status..."
            ssh "root@${SERVER_IP}" "docker ps && echo '' && docker compose -f /opt/cloudone/docker-compose.yml ps"
            ;;
        *)
            log_error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac

    log_success "Done!"
}

main "$@"
