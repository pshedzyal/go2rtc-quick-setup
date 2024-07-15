#!/bin/bash

# Determine the path to the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

log() {
    echo "| $1"
}

log_warning() {
    echo -e "${YELLOW} $1 ${RESET}"
}

log_success() {
    echo -e "| ${GREEN}$1${RESET}"
}


# Display ASCII art
cat << "EOF"

░██████╗░░█████╗░██████╗░██████╗░████████╗░█████╗░
██╔════╝░██╔══██╗╚════██╗██╔══██╗╚══██╔══╝██╔══██╗
██║░░██╗░██║░░██║░░███╔═╝██████╔╝░░░██║░░░██║░░╚═╝
██║░░╚██╗██║░░██║██╔══╝░░██╔══██╗░░░██║░░░██║░░██╗
╚██████╔╝╚█████╔╝███████╗██║░░██║░░░██║░░░╚█████╔╝
░╚═════╝░░╚════╝░╚══════╝╚═╝░░╚═╝░░░╚═╝░░░░╚════╝░

░██████╗░██╗░░░██╗██╗░█████╗░██╗░░██╗  ░██████╗███████╗████████╗██╗░░░██╗██████╗░
██╔═══██╗██║░░░██║██║██╔══██╗██║░██╔╝  ██╔════╝██╔════╝╚══██╔══╝██║░░░██║██╔══██╗
██║██╗██║██║░░░██║██║██║░░╚═╝█████═╝░  ╚█████╗░█████╗░░░░░██║░░░██║░░░██║██████╔╝
╚██████╔╝██║░░░██║██║██║░░██╗██╔═██╗░  ░╚═══██╗██╔══╝░░░░░██║░░░██║░░░██║██╔═══╝░
░╚═██╔═╝░╚██████╔╝██║╚█████╔╝██║░╚██╗  ██████╔╝███████╗░░░██║░░░╚██████╔╝██║░░░░░
░░░╚═╝░░░░╚═════╝░╚═╝░╚════╝░╚═╝░░╚═╝  ╚═════╝░╚══════╝░░░╚═╝░░░░╚═════╝░╚═╝░░░░░
EOF


spinner() {
    local pid=$1
    local spin_chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧")
    while kill -0 "$pid" &>/dev/null; do
        for char in "${spin_chars[@]}"; do
            echo -ne "\r${YELLOW}${char}${RESET} Downloading..."
            sleep 0.1
        done
    done
    echo -e "\r${GREEN}Download complete!${RESET}"
}

setupAutoRun() {
    # Check if go2rtc binary exists in the specified folder or in a go2rtc subfolder
    if [[ -f "$SCRIPT_DIR/go2rtc" ]]; then
        # Verify if the service already exists
        if systemctl is-enabled go2rtc.service &>/dev/null; then
            log_warning "go2rtc service already exists. Need to uninstall first."
            systemctl stop go2rtc.service
            systemctl disable go2rtc.service
            rm /etc/systemd/system/go2rtc.service
            log "Uninstalled."
        fi

        # Create the systemd service unit file
        sudo cat <<EOF > /etc/systemd/system/go2rtc.service
[Unit]
Description=go2rtc Service
After=network.target

[Service]
ExecStart=$SCRIPT_DIR/go2rtc
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target
EOF

        # Reload systemd and enable the service
        systemctl daemon-reload
        systemctl enable go2rtc.service
        log "Enabled auto-start on system boot"

        # Start the service immediately
        systemctl start go2rtc.service
        log "Started go2rtc service"
        log "go2rtc service installed successfully!"
    else
        log_warning "go2rtc binary not found. Nothing to install."
    fi
}

install() {
    LATEST_RELEASE_JSON=$(curl -s "https://api.github.com/repos/AlexxIT/go2rtc/releases/latest")
    TAG_NAME=$(echo "$LATEST_RELEASE_JSON" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)

    if [[ -z "$TAG_NAME" ]]; then
        log_warning "Error: Unable to determine the latest release tag. Installation failed."
        exit 1
    fi
    # Construct the download URL
    DOWNLOAD_URL="https://github.com/AlexxIT/go2rtc/releases/download/$TAG_NAME/go2rtc_linux_arm64"

    # Determine the path to the script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    log "Script directory: $SCRIPT_DIR"

    # Download the latest go2rtc binary
    wget "$DOWNLOAD_URL" -O "$SCRIPT_DIR/go2rtc" 2>/dev/null & download_pid=$!
    spinner "$download_pid"
    log "Downloaded go2rtc binary"

    # Make the binary executable
    chmod +x "$SCRIPT_DIR/go2rtc"
    log "Made go2rtc binary executable"

    # Create an empty go2rtc.yaml file
    touch "$SCRIPT_DIR/go2rtc.yaml"
    log "Created configuration file: go2rtc.yaml"

    # Configure auto-start on system boot (using systemd)
    setupAutoRun

    log_success "Setup completed successfully!"
}

uninstall() {
    # Check if go2rtc binary exists in the specified folder or in a go2rtc subfolder
    if [[ -f "$SCRIPT_DIR/go2rtc" ]]; then
        # Verify if the service exists
        if systemctl is-enabled go2rtc.service &>/dev/null; then
            systemctl stop go2rtc.service
            systemctl disable go2rtc.service
            rm /etc/systemd/system/go2rtc.service

            rm "$SCRIPT_DIR/go2rtc"
            rm "$SCRIPT_DIR/go2rtc.yaml"

            log_success "go2rtc service uninstalled successfully!"
        else
            log_warning "go2rtc service not found. Nothing to uninstall."
        fi
    else
        log_warning "go2rtc binary not found. Nothing to uninstall."
    fi
}

# Menu
echo -e "\n${GREEN}Select an option:${RESET}"
PS3="> "
options=("Install go2rtc" "Uninstall go2rtc" "Quit")
select opt in "${options[@]}"; do
    case $opt in
        "Install go2rtc")
            install
            break
            ;;
        "Uninstall go2rtc")
            uninstall
            break
            ;;
        "Quit")
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option. Please choose again."
            ;;
    esac
done