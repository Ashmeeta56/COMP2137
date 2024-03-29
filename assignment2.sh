#!/bin/bash

# Function to check if a package is installed
package_installed() {
    dpkg -l "$1" &> /dev/null
}

# Function to add users with specified configurations
add_users() {
    local users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
    for user in "${users[@]}"; do
        if ! id "$user" &> /dev/null; then
            useradd -m -s /bin/bash "$user"
            mkdir -p /home/"$user"/.ssh
            # Add RSA and ED25519 public keys for each user
            # Replace below with actual public keys
            echo "ssh-rsa <RSA_PUBLIC_KEY_HERE>" >> /home/"$user"/.ssh/authorized_keys
            echo "ssh-ed25519 <ED25519_PUBLIC_KEY_HERE>" >> /home/"$user"/.ssh/authorized_keys
        fi
    done
}

# Function to configure network interface and /etc/hosts
configure_network() {
    # Check if interface configuration already exists
    if ! grep -q "192.168.16.21" /etc/netplan/*.yaml; then
        # Add configuration for 192.168.16.21/24
        cat <<EOF >> /etc/netplan/*.yaml
            network:
              version: 2
              renderer: networkd
              ethernets:
                ens160:   # Replace with appropriate interface name
                  addresses:
                    - 192.168.16.21
                  gateway4: 192.168.16.2
                  nameservers:
                    addresses: [8.8.8.8, 8.8.4.4]
EOF
        # Apply netplan configuration
        netplan apply
    fi

    # Update /etc/hosts with server1 entry
    sed -i '/192.168.16.21/d' /etc/hosts
    echo "192.168.16.21 server1" >> /etc/hosts
}

# Function to install and configure required software
install_configure_software() {
    # Install Apache if not installed
    if ! package_installed apache2; then
        apt update
        apt install -y apache2
    fi

    # Install Squid if not installed
    if ! package_installed squid; then
        apt update
        apt install -y squid
    fi

    # Configure firewall rules
    ufw allow OpenSSH
    ufw allow 'Apache Full'
    ufw allow 'Squid'
    ufw --force enable
}

# Main function
main() {
    add_users
    configure_network
    install_configure_software
}

main
