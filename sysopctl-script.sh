#!/bin/bash

# sysopctl - System Operations Control
# Version: v0.1.0
# Author: Senior Linux Administrator
# Description: A comprehensive system management utility

VERSION="v0.1.0"
BACKUP_DIR="/var/backups/sysopctl"
LOG_FILE="/var/log/sysopctl.log"

# Logging function
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# Error handling function
handle_error() {
    local error_message="$1"
    log "ERROR: $error_message"
    echo "Error: $error_message" >&2
    exit 1
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        handle_error "This command requires root privileges"
    fi
}

# Display help information
show_help() {
    cat << EOF
sysopctl - System Operations Control ($VERSION)

Usage: sysopctl [OPTIONS] COMMAND [ARGS]

Options:
    --help      Display this help message
    --version   Show version information

Commands:
    service     Manage system services
        list            List all running services
        start <name>    Start a service
        stop <name>     Stop a service
    
    system      System information
        load            Display system load average
    
    disk        Disk operations
        usage           Show disk usage statistics
    
    process     Process management
        monitor         Monitor system processes
    
    logs        Log management
        analyze         Analyze system logs
    
    backup      Backup operations
        <path>         Backup specified path

Examples:
    sysopctl service list
    sysopctl service start nginx
    sysopctl system load
    sysopctl backup /etc

For more detailed information, see: man sysopctl
EOF
}

# Service management functions
service_list() {
    systemctl list-units --type=service --no-pager
}

service_start() {
    local service_name="$1"
    if [ -z "$service_name" ]; then
        handle_error "Service name required"
    fi
    systemctl start "$service_name"
    log "Started service: $service_name"
}

service_stop() {
    local service_name="$1"
    if [ -z "$service_name" ]; then
        handle_error "Service name required"
    fi
    systemctl stop "$service_name"
    log "Stopped service: $service_name"
}

# System load function
system_load() {
    uptime | awk -F'load average:' '{print $2}'
}

# Disk usage function
disk_usage() {
    df -h
}

# Process monitor function
process_monitor() {
    top -b -n 1
}

# Log analysis function
logs_analyze() {
    journalctl -p err..emerg --no-pager -n 50
}

# Backup function
backup_files() {
    local source_path="$1"
    if [ -z "$source_path" ]; then
        handle_error "Backup path required"
    fi
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/$timestamp"
    
    mkdir -p "$backup_path"
    rsync -av --progress "$source_path" "$backup_path/" || handle_error "Backup failed"
    log "Backup completed: $source_path -> $backup_path"
}

# Main command parser
main() {
    case "$1" in
        --help)
            show_help
            ;;
        --version)
            echo "sysopctl $VERSION"
            ;;
        service)
            check_root
            case "$2" in
                list)    service_list ;;
                start)   service_start "$3" ;;
                stop)    service_stop "$3" ;;
                *)      handle_error "Invalid service command" ;;
            esac
            ;;
        system)
            case "$2" in
                load)    system_load ;;
                *)      handle_error "Invalid system command" ;;
            esac
            ;;
        disk)
            case "$2" in
                usage)   disk_usage ;;
                *)      handle_error "Invalid disk command" ;;
            esac
            ;;
        process)
            case "$2" in
                monitor) process_monitor ;;
                *)      handle_error "Invalid process command" ;;
            esac
            ;;
        logs)
            case "$2" in
                analyze) logs_analyze ;;
                *)      handle_error "Invalid logs command" ;;
            esac
            ;;
        backup)
            check_root
            backup_files "$2"
            ;;
        *)
            handle_error "Invalid command. Use --help for usage information."
            ;;
    esac
}

# Script entry point
main "$@"
