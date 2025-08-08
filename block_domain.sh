#!/bin/bash

# Clear the screen for a clean start
clear

# --- Functions ---

# Function to display colored messages
function print_message() {
    case $1 in
        "green") echo -e "\e[32m$2\e[0m" ;;
        "red") echo -e "\e[31m$2\e[0m" ;;
        "yellow") echo -e "\e[33m$2\e[0m" ;;
        "cyan") echo -e "\e[36m$2\e[0m" ;;
        *) echo "$2" ;;
    esac
}

# --- Main Script ---

# Check for root/sudo privileges at the very beginning
if [[ $EUID -ne 0 ]]; then
   print_message "red" "Error: This script must be run with root privileges (use sudo). Exiting."
   exit 1
fi

print_message "yellow" "Welcome to the Interactive Domain Blocker!"
echo "This script will block domains by adding rules to iptables."
echo "--------------------------------------------------------"

# Loop to allow blocking multiple domains
while true; do
    # 1. Get Domain Name from User
    read -p "Please enter the domain name to block: " domain_name

    if [ -z "$domain_name" ]; then
        print_message "red" "No domain entered. Please try again."
        continue # Skip to the next loop iteration
    fi

    # 2. Resolve Domain to IP Addresses
    echo ""
    print_message "yellow" "Resolving '$domain_name' to IP address(es)..."
    ip_addresses=$(dig +short "$domain_name" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')

    if [ -z "$ip_addresses" ]; then
        print_message "red" "Error: Could not resolve any IP addresses for '$domain_name'."
        echo ""
    else
        # 3. Show Rule Syntax and Block IPs
        echo ""
        print_message "green" "Found the following IP(s) for '$domain_name':"
        echo "$ip_addresses"
        echo ""

        for ip in $ip_addresses; do
            print_message "cyan" "--> The script will add the following rules for IP: $ip"
            # This is where the rule syntax is shown
            echo "    iptables -A OUTPUT -d \"$ip\" -j DROP"
            echo "    iptables -A INPUT -s \"$ip\" -j DROP"
            # Add the rules
            iptables -A OUTPUT -d "$ip" -j DROP
            iptables -A INPUT -s "$ip" -j DROP
        done

        print_message "green" "\nSuccessfully added all iptables rules."

        # 4. Verify the Block
        echo ""
        print_message "yellow" "--- Verification ---"
        print_message "yellow" "Attempting to ping '$domain_name' (this should fail)..."
        ping -c 3 "$domain_name"
        echo ""
    fi

    # 5. Ask to Add Another Rule
    read -p "Do you want to block another domain? (y/n): " choice
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
        break # Exit the while loop
    fi
    clear
done

print_message "yellow" "\nScript finished. Goodbye! "
