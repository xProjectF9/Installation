#!/bin/sh

# xProject Installer
# POSIX sh compatible
#
# Usage:
#   curl -fsSL https://xproject.studio/downloads/xProject/install.sh | sh

set -u

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------

if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    COLORS=$(tput colors 2>/dev/null || echo 0)

    if [ "$COLORS" -gt 0 ]; then
        RED=$(tput setaf 1)
        GREEN=$(tput setaf 2)
        YELLOW=$(tput setaf 3)
        BLUE=$(tput setaf 4)
        CYAN=$(tput setaf 6)
        BOLD=$(tput bold)
        NC=$(tput sgr0)
    else
        RED=""
        GREEN=""
        YELLOW=""
        BLUE=""
        CYAN=""
        BOLD=""
        NC=""
    fi
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    CYAN=""
    BOLD=""
    NC=""
fi

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

XPROJECT_URL="https://xproject.studio/downloads/xProject/00000000-0000-0000-0000-000000000000/xProject.zip"
XPROJECT_ZIP="Lin64/xProject.zip"
XPROJECT_DIR="Lin64"

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

log_info() {
    printf "%s[INFO]%s %s\n" "$BLUE" "$NC" "$*"
}

log_success() {
    printf "%s[ OK ]%s %s\n" "$GREEN" "$NC" "$*"
}

log_warn() {
    printf "%s[WARN]%s %s\n" "$YELLOW" "$NC" "$*"
}

log_error() {
    printf "%s[ERROR]%s %s\n" "$RED" "$NC" "$*"
}

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------

print_header() {
    printf "\n"
    printf "%s%s============================================================%s\n" \
        "$BOLD" "$CYAN" "$NC"
    printf "%s%s                    xProject Installer%s\n" \
        "$BOLD" "$CYAN" "$NC"
    printf "%s%s                 https://xproject.studio%s\n" \
        "$BOLD" "$CYAN" "$NC"
    printf "%s%s============================================================%s\n" \
        "$BOLD" "$CYAN" "$NC"
    printf "\n"
}

# ---------------------------------------------------------------------------
# Manual installation instructions
# ---------------------------------------------------------------------------

print_manual_instructions() {
    printf "%sManual installation%s\n" "$BOLD" "$NC"
    printf "%s\n" "------------------------------------------------------------"

    printf "Debian / Ubuntu:\n"
    printf "  sudo apt update\n"
    printf "  sudo apt install -y libgtk2.0-0 libssl-dev unzip p7zip-full\n\n"

    printf "Fedora / Rocky / AlmaLinux:\n"
    printf "  sudo dnf install -y gtk2 openssl-devel unzip p7zip\n\n"

    printf "openSUSE:\n"
    printf "  sudo zypper install -y gtk2 libopenssl-devel unzip p7zip\n"

    printf "%s\n\n" "------------------------------------------------------------"
}

# ---------------------------------------------------------------------------
# Ask a yes/no question
#
# stdin is occupied when the installer is started with:
#
#   curl ... | sh
#
# Therefore input must be read from /dev/tty.
# ---------------------------------------------------------------------------

prompt_yes_no() {
    prompt="$1"
    default="${2:-y}"

    while true; do
        printf "%s [%s]: " "$prompt" "$default" > /dev/tty

        if ! IFS= read -r choice < /dev/tty; then
            printf "\n" > /dev/tty
            return 1
        fi

        if [ -z "$choice" ]; then
            choice="$default"
        fi

        case "$choice" in
            y|Y|yes|YES|Yes)
                return 0
                ;;
            n|N|no|NO|No)
                return 1
                ;;
            *)
                printf "Please answer y or n.\n" > /dev/tty
                ;;
        esac
    done
}

# ---------------------------------------------------------------------------
# Detect Linux distribution
# ---------------------------------------------------------------------------

detect_distro() {
    if [ -f /etc/debian_version ]; then
        printf "debian"
    elif [ -f /etc/fedora-release ] ||
         [ -f /etc/rocky-release ] ||
         [ -f /etc/almalinux-release ]; then
        printf "fedora"
    elif [ -f /etc/os-release ] &&
         grep -qi "opensuse" /etc/os-release; then
        printf "opensuse"
    else
        printf "unknown"
    fi
}

# ---------------------------------------------------------------------------
# Check installed packages
# ---------------------------------------------------------------------------

check_pkg_debian() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null |
        grep -q "install ok installed"
}

check_pkg_fedora() {
    rpm -q "$1" >/dev/null 2>&1
}

check_pkg_opensuse() {
    rpm -q "$1" >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# Install package
# ---------------------------------------------------------------------------

install_pkg_debian() {
    pkg="$1"

    if check_pkg_debian "$pkg"; then
        log_success "$pkg is already installed"
        return 0
    fi

    log_info "Installing $pkg..."

    if sudo apt install -y "$pkg"; then
        log_success "$pkg installed"
        return 0
    fi

    log_error "Failed to install $pkg"
    return 1
}

install_pkg_fedora() {
    pkg="$1"

    if check_pkg_fedora "$pkg"; then
        log_success "$pkg is already installed"
        return 0
    fi

    log_info "Installing $pkg..."

    if sudo dnf install -y "$pkg"; then
        log_success "$pkg installed"
        return 0
    fi

    log_error "Failed to install $pkg"
    return 1
}

install_pkg_opensuse() {
    pkg="$1"

    if check_pkg_opensuse "$pkg"; then
        log_success "$pkg is already installed"
        return 0
    fi

    log_info "Installing $pkg..."

    if sudo zypper --non-interactive install -y "$pkg"; then
        log_success "$pkg installed"
        return 0
    fi

    log_error "Failed to install $pkg"
    return 1
}

# ---------------------------------------------------------------------------
# Install dependencies
# ---------------------------------------------------------------------------

install_deps() {
    distro="$1"

    case "$distro" in
        debian)
            log_info "Updating package list..."

            if ! sudo apt update; then
                log_error "Failed to update package list"
                return 1
            fi

            for pkg in libgtk2.0-0 libssl-dev unzip p7zip-full; do
                install_pkg_debian "$pkg" || return 1
            done
            ;;

        fedora)
            for pkg in gtk2 openssl-devel unzip p7zip; do
                install_pkg_fedora "$pkg" || return 1
            done
            ;;

        opensuse)
            for pkg in gtk2 libopenssl-devel unzip p7zip; do
                install_pkg_opensuse "$pkg" || return 1
            done
            ;;

        *)
            log_error "Unsupported distribution: $distro"
            return 1
            ;;
    esac

    return 0
}

# ---------------------------------------------------------------------------
# Download and install xProject
# ---------------------------------------------------------------------------

download_xproject() {
    log_info "Preparing $XPROJECT_DIR directory..."

    if ! mkdir -p "$XPROJECT_DIR"; then
        log_error "Could not create $XPROJECT_DIR directory"
        return 1
    fi

    log_info "Downloading xProject..."

    if ! wget -O "$XPROJECT_ZIP" "$XPROJECT_URL" --show-progress; then
        log_error "Download failed"
        rm -f "$XPROJECT_ZIP"
        return 1
    fi

    log_success "Download complete"

    log_info "Extracting xProject..."

    if ! unzip -o "$XPROJECT_ZIP" -d "$XPROJECT_DIR"; then
        log_error "Extraction failed"
        return 1
    fi

    rm -f "$XPROJECT_ZIP"

    if [ ! -f "$XPROJECT_DIR/xProject" ]; then
        log_error "$XPROJECT_DIR/xProject was not found after extraction"
        return 1
    fi

    chmod +x "$XPROJECT_DIR/xProject"

    cat > xProject.sh << 'EOF'
#!/bin/sh

./Lin64/xProject
EOF

    chmod +x xProject.sh

    log_success "xProject is ready to run"

    return 0
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
    print_header

    # Check that an interactive terminal is available.
    if [ ! -r /dev/tty ] || [ ! -w /dev/tty ]; then
        log_error "No interactive terminal available."
        log_error "Please run this installer from a terminal."
        exit 1
    fi

    distro=$(detect_distro)

    log_info "Detected distribution: $distro"

    if [ "$distro" = "unknown" ]; then
        log_error "Unsupported distribution."
        printf "\n"
        print_manual_instructions
        exit 1
    fi

    printf "\n"

    if prompt_yes_no \
        "Install required system dependencies (GTK2, OpenSSL, unzip, 7z)?" \
        "y"; then

        if ! install_deps "$distro"; then
            log_error "Dependency installation failed"
            exit 1
        fi
    else
        log_warn "Skipping dependency installation."
        log_warn "Make sure the required libraries are installed manually."
    fi

    printf "\n"

    if prompt_yes_no "Download and install xProject now?" "y"; then

        if download_xproject; then
            printf "\n"
            log_success "Installation complete!"
            printf "\n"
            printf "Start xProject with:\n"
            printf "  ./xProject.sh\n"
            printf "\n"

            if prompt_yes_no "Start xProject now?" "y"; then
                printf "\n"
                ./xProject.sh
            fi
        else
            log_error "Installation failed"
            exit 1
        fi

    else
        printf "\n"
        log_info "You can install xProject manually with:"
        printf "\n"
        printf "  mkdir -p Lin64\n"
        printf "  wget -O Lin64/xProject.zip \"%s\"\n" "$XPROJECT_URL"
        printf "  unzip Lin64/xProject.zip -d Lin64\n"
        printf "  rm Lin64/xProject.zip\n"
        printf "  chmod +x Lin64/xProject\n"
        printf "\n"
        printf "Then create xProject.sh containing:\n"
        printf "\n"
        printf "  #!/bin/sh\n"
        printf "\n"
        printf "  ./Lin64/xProject\n"
        printf "\n"
        printf "and make it executable:\n"
        printf "\n"
        printf "  chmod +x xProject.sh\n"
        printf "\n"
    fi
}

main "$@"
