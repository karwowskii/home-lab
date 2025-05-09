#!/bin/bash

set -e

# Resolve absolute path of the directory this script is in
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Script paths
CREATE_SCRIPT="$SCRIPT_DIR/create-ansible-node.sh"
BOOTSTRAP_SCRIPT="$SCRIPT_DIR/bootstrap-ansible-node.sh"
PROVISION_SCRIPT="$SCRIPT_DIR/run-provisioning-from-node.sh"
INFO_FILE="/tmp/ansible-node-info"

function confirm_step() {
    local msg="$1"
    read -p "$msg [y/N]: " choice
    case "$choice" in
        y|Y) return 0 ;;
        *) echo "[INFO] Skipping..."; return 1 ;;
    esac
}

function read_node_info() {
    if [[ ! -f "$INFO_FILE" ]]; then
        echo "[ERROR] $INFO_FILE not found. Run the provisioning step first."
        exit 1
    fi
    source "$INFO_FILE"
    if [[ -z "$ANSIBLE_NODE_IP" || -z "$ANSIBLE_NODE_USER" ]]; then
        echo "[ERROR] Invalid content in $INFO_FILE"
        exit 1
    fi
}

function main_menu() {
    echo "Home Lab Setup Menu"
    echo "1) Provision Ansible Control Node"
    echo "2) Bootstrap Ansible Control Node"
    echo "3) Provision Full Environment"
    echo "4) Run All Steps"
    echo "5) Exit"
    read -p "Choose an option: " opt
    case "$opt" in
        1)
            echo "-- Provisioning Ansible Control Node --"
            bash "$CREATE_SCRIPT"
            ;;
        2)
            echo "-- Bootstrapping Ansible Control Node --"
            if confirm_step "Have you run Provision Ansible Control Node?"; then
                read_node_info
                bash "$BOOTSTRAP_SCRIPT" "$ANSIBLE_NODE_IP"
            fi
            ;;
        3)
            echo "-- Provisioning Full Environment --"
            if confirm_step "Have you bootstrapped the Ansible control node?"; then
                read_node_info
                bash "$PROVISION_SCRIPT" "$ANSIBLE_NODE_IP"
            fi
            ;;
        4)
            echo "-- Running All Steps --"
            bash "$CREATE_SCRIPT"
            read_node_info
            bash "$BOOTSTRAP_SCRIPT" "$ANSIBLE_NODE_IP"
            bash "$PROVISION_SCRIPT" "$ANSIBLE_NODE_IP"
            ;;
        5)
            exit 0
            ;;
        *) echo "Invalid option";;
    esac
}

# Loop until user exits
while true; do
    main_menu
    echo
done
