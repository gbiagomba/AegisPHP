#!/usr/bin/env bash
# PHALANX Installation Script for Linux/macOS/Unix
# Version: 0.1.0
# Supports: Ubuntu, Debian, RHEL, CentOS, Fedora, macOS

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Version
VERSION="0.1.0"
PROJECT_NAME="PHALANX"

# Print functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $PROJECT_NAME Installer v$VERSION${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════${NC}\n"
}

# Detect OS and distribution
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        DISTRO="macos"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS="linux"
        DISTRO="${ID}"
    elif [[ -f /etc/redhat-release ]]; then
        OS="linux"
        DISTRO="rhel"
    else
        OS="unknown"
        DISTRO="unknown"
    fi

    print_info "Detected OS: $OS"
    print_info "Detected Distribution: $DISTRO"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root. This is not recommended for Docker usage."
        print_warning "Consider running as a regular user and using sudo only when needed."
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install dependencies on Ubuntu/Debian
install_ubuntu_debian() {
    print_info "Installing dependencies for Ubuntu/Debian..."

    sudo apt-get update

    if ! command_exists docker; then
        print_info "Installing Docker..."
        sudo apt-get install -y docker.io
        sudo systemctl enable docker
        sudo systemctl start docker
        sudo usermod -aG docker "$USER" || true
        print_success "Docker installed"
    else
        print_success "Docker already installed"
    fi

    if ! command_exists python3; then
        print_info "Installing Python 3..."
        sudo apt-get install -y python3 python3-pip
        print_success "Python 3 installed"
    else
        print_success "Python 3 already installed"
    fi

    if ! command_exists git; then
        print_info "Installing Git..."
        sudo apt-get install -y git
        print_success "Git installed"
    else
        print_success "Git already installed"
    fi
}

# Install dependencies on RHEL/CentOS/Fedora
install_rhel_centos_fedora() {
    print_info "Installing dependencies for RHEL/CentOS/Fedora..."

    # Determine package manager
    if command_exists dnf; then
        PKG_MGR="dnf"
    else
        PKG_MGR="yum"
    fi

    if ! command_exists docker; then
        print_info "Installing Docker..."
        sudo $PKG_MGR install -y docker
        sudo systemctl enable docker
        sudo systemctl start docker
        sudo usermod -aG docker "$USER" || true
        print_success "Docker installed"
    else
        print_success "Docker already installed"
    fi

    if ! command_exists python3; then
        print_info "Installing Python 3..."
        sudo $PKG_MGR install -y python3 python3-pip
        print_success "Python 3 installed"
    else
        print_success "Python 3 already installed"
    fi

    if ! command_exists git; then
        print_info "Installing Git..."
        sudo $PKG_MGR install -y git
        print_success "Git installed"
    else
        print_success "Git already installed"
    fi
}

# Install dependencies on macOS
install_macos() {
    print_info "Installing dependencies for macOS..."

    if ! command_exists brew; then
        print_warning "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        print_success "Homebrew installed"
    else
        print_success "Homebrew already installed"
    fi

    if ! command_exists docker; then
        print_info "Installing Docker Desktop..."
        brew install --cask docker
        print_success "Docker Desktop installed"
        print_warning "Please start Docker Desktop manually from Applications"
    else
        print_success "Docker already installed"
    fi

    if ! command_exists python3; then
        print_info "Installing Python 3..."
        brew install python3
        print_success "Python 3 installed"
    else
        print_success "Python 3 already installed"
    fi

    if ! command_exists git; then
        print_info "Installing Git..."
        brew install git
        print_success "Git installed"
    else
        print_success "Git already installed"
    fi
}

# Install $PROJECT_NAME
install_phalanx() {
    print_info "Setting up $PROJECT_NAME..."

    # Make script executable
    chmod +x phalanx.py
    print_success "Made phalanx.py executable"

    # Ask if user wants system-wide installation
    echo ""
    read -p "Install $PROJECT_NAME system-wide to /usr/local/bin? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ -w /usr/local/bin ]]; then
            cp phalanx.py /usr/local/bin/phalanx
            chmod +x /usr/local/bin/phalanx
            print_success "$PROJECT_NAME installed to /usr/local/bin/phalanx"
        else
            sudo cp phalanx.py /usr/local/bin/phalanx
            sudo chmod +x /usr/local/bin/phalanx
            print_success "$PROJECT_NAME installed to /usr/local/bin/phalanx (with sudo)"
        fi
        print_info "You can now run: phalanx /path/to/project"
    else
        print_info "Skipping system-wide installation"
        print_info "You can run: ./phalanx.py /path/to/project"
    fi
}

# Verify installation
verify_installation() {
    print_info "Verifying installation..."

    local errors=0

    if command_exists docker; then
        if docker ps >/dev/null 2>&1; then
            print_success "Docker is running"
        else
            print_warning "Docker is installed but not running or you need to add your user to docker group"
            print_info "Run: sudo usermod -aG docker $USER && newgrp docker"
            errors=$((errors + 1))
        fi
    else
        print_error "Docker not found"
        errors=$((errors + 1))
    fi

    if command_exists python3; then
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        print_success "Python 3 installed (version: $PYTHON_VERSION)"
    else
        print_error "Python 3 not found"
        errors=$((errors + 1))
    fi

    if command_exists git; then
        print_success "Git installed"
    else
        print_warning "Git not found (optional)"
    fi

    if [[ $errors -eq 0 ]]; then
        print_success "All required dependencies are installed!"
        return 0
    else
        print_error "Some dependencies are missing or not configured correctly"
        return 1
    fi
}

# Main installation flow
main() {
    print_header

    check_root
    detect_os

    echo ""
    print_info "Installing dependencies..."
    echo ""

    case "$DISTRO" in
        ubuntu|debian|linuxmint|pop)
            install_ubuntu_debian
            ;;
        rhel|centos|fedora|rocky|alma)
            install_rhel_centos_fedora
            ;;
        macos)
            install_macos
            ;;
        *)
            print_error "Unsupported distribution: $DISTRO"
            print_info "Please manually install: Docker, Python 3.8+, Git"
            exit 1
            ;;
    esac

    echo ""
    verify_installation

    echo ""
    install_phalanx

    echo ""
    print_success "═══════════════════════════════════════════════"
    print_success "  $PROJECT_NAME installation complete!"
    print_success "═══════════════════════════════════════════════"
    echo ""
    print_info "Next steps:"
    echo "  1. Log out and log back in (for Docker group membership)"
    echo "  2. Run: phalanx --version"
    echo "  3. Scan a project: phalanx /path/to/php/project"
    echo ""
    print_info "Documentation: https://github.com/yourusername/phalanx"
    echo ""
}

# Run main function
main "$@"
