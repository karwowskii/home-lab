#!/bin/bash

set -e

# Path to scripts\SCRIPT_DIR="$(dirname "$0")"
CREATE_SCRIPT="$SCRIPT_DIR/create-ansible-node.sh"
BOOTSTRAP_SCRIPT="$SCRIPT_DIR/bootstrap-ansible-node.sh"
PROVISION_SCRIPT="$SCRIPT_DIR/run-provisioning-from-node.sh"

function confirm_step() {
    local msg="$1"
    read -p "$msg [y/N]: " choice
    case "$choice" in
        y|Y) return 0 ;; 
        *) echo "[INFO] Skipping..."; return 1 ;;
    esac
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
                read -p "Enter Ansible node IP: " ip
                bash "$BOOTSTRAP_SCRIPT" "$ip"
            fi
            ;;
        3)
            echo "-- Provisioning Full Environment --"
            if confirm_step "Have you bootstrapped the Ansible control node?"; then
                read -p "Enter Ansible node IP: " ip
                bash "$PROVISION_SCRIPT" "$ip"
            fi
            ;;
        4)
            echo "-- Running All Steps --"
            bash "$CREATE_SCRIPT"
            read -p "Enter Ansible node IP: " ip_all
            bash "$BOOTSTRAP_SCRIPT" "$ip_all"
            bash "$PROVISION_SCRIPT" "$ip_all"
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
