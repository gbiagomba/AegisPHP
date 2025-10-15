# PHALANX Installation Script for Windows
# Version: 0.1.0
# Requires: PowerShell 5.1+ and Administrator privileges

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

# Version
$VERSION = "0.1.0"
$PROJECT_NAME = "PHALANX"

# Print functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[✓] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[✗] $Message" -ForegroundColor Red
}

function Write-Header {
    Write-Host "`n═══════════════════════════════════════════════" -ForegroundColor Blue
    Write-Host "  $PROJECT_NAME Installer v$VERSION" -ForegroundColor Blue
    Write-Host "═══════════════════════════════════════════════`n" -ForegroundColor Blue
}

# Check if command exists
function Test-CommandExists {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# Detect package manager
function Get-PackageManager {
    if (Test-CommandExists "winget") {
        return "winget"
    }
    elseif (Test-CommandExists "choco") {
        return "choco"
    }
    else {
        return "none"
    }
}

# Install winget if not present
function Install-Winget {
    Write-Info "Installing Windows Package Manager (winget)..."

    try {
        # Check if App Installer is available
        $appxPackage = Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue

        if ($null -eq $appxPackage) {
            Write-Info "Downloading App Installer from Microsoft Store..."
            Start-Process "ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1"
            Write-Warning "Please install 'App Installer' from the Microsoft Store and run this script again."
            exit 1
        }

        Write-Success "winget is available"
    }
    catch {
        Write-Error "Failed to install winget: $_"
        exit 1
    }
}

# Install Chocolatey if not present
function Install-Chocolatey {
    Write-Info "Installing Chocolatey package manager..."

    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        Write-Success "Chocolatey installed successfully"
    }
    catch {
        Write-Error "Failed to install Chocolatey: $_"
        exit 1
    }
}

# Install Docker Desktop
function Install-Docker {
    $pkgMgr = Get-PackageManager

    if (Test-CommandExists "docker") {
        Write-Success "Docker already installed"
        return
    }

    Write-Info "Installing Docker Desktop..."

    try {
        if ($pkgMgr -eq "winget") {
            winget install Docker.DockerDesktop --silent --accept-source-agreements --accept-package-agreements
        }
        elseif ($pkgMgr -eq "choco") {
            choco install docker-desktop -y
        }
        else {
            Write-Warning "No package manager found. Please download Docker Desktop manually:"
            Write-Info "https://www.docker.com/products/docker-desktop/"
            Start-Process "https://www.docker.com/products/docker-desktop/"
            exit 1
        }

        Write-Success "Docker Desktop installed"
        Write-Warning "Please restart your computer and start Docker Desktop before using $PROJECT_NAME"
    }
    catch {
        Write-Error "Failed to install Docker: $_"
        Write-Info "Please install Docker Desktop manually from: https://www.docker.com/products/docker-desktop/"
    }
}

# Install Python
function Install-Python {
    if (Test-CommandExists "python") {
        $pythonVersion = python --version 2>&1
        Write-Success "Python already installed ($pythonVersion)"
        return
    }

    $pkgMgr = Get-PackageManager
    Write-Info "Installing Python 3..."

    try {
        if ($pkgMgr -eq "winget") {
            winget install Python.Python.3 --silent --accept-source-agreements --accept-package-agreements
        }
        elseif ($pkgMgr -eq "choco") {
            choco install python3 -y
        }
        else {
            Write-Warning "No package manager found. Please download Python manually:"
            Write-Info "https://www.python.org/downloads/"
            Start-Process "https://www.python.org/downloads/"
            exit 1
        }

        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        Write-Success "Python 3 installed"
    }
    catch {
        Write-Error "Failed to install Python: $_"
        Write-Info "Please install Python 3.8+ manually from: https://www.python.org/downloads/"
    }
}

# Install Git
function Install-Git {
    if (Test-CommandExists "git") {
        Write-Success "Git already installed"
        return
    }

    $pkgMgr = Get-PackageManager
    Write-Info "Installing Git..."

    try {
        if ($pkgMgr -eq "winget") {
            winget install Git.Git --silent --accept-source-agreements --accept-package-agreements
        }
        elseif ($pkgMgr -eq "choco") {
            choco install git -y
        }
        else {
            Write-Warning "No package manager found. Please download Git manually:"
            Write-Info "https://git-scm.com/downloads"
            Start-Process "https://git-scm.com/downloads"
            exit 1
        }

        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        Write-Success "Git installed"
    }
    catch {
        Write-Error "Failed to install Git: $_"
        Write-Info "Please install Git manually from: https://git-scm.com/downloads"
    }
}

# Install PHALANX
function Install-Phalanx {
    Write-Info "Setting up $PROJECT_NAME..."

    # Check if phalanx.py exists
    if (-not (Test-Path "phalanx.py")) {
        Write-Error "phalanx.py not found in current directory"
        Write-Info "Please run this script from the $PROJECT_NAME directory"
        exit 1
    }

    # Create a wrapper batch file for Windows
    $batchContent = @"
@echo off
python "%~dp0phalanx.py" %*
"@

    Set-Content -Path "phalanx.bat" -Value $batchContent
    Write-Success "Created phalanx.bat wrapper"

    # Ask for system-wide installation
    $response = Read-Host "`nInstall $PROJECT_NAME system-wide to C:\Program Files\PHALANX? (y/N)"

    if ($response -match '^[Yy]$') {
        $installDir = "C:\Program Files\PHALANX"

        try {
            # Create installation directory
            New-Item -ItemType Directory -Path $installDir -Force | Out-Null

            # Copy files
            Copy-Item "phalanx.py" -Destination $installDir
            Copy-Item "phalanx.bat" -Destination $installDir
            Copy-Item "Dockerfile" -Destination $installDir -ErrorAction SilentlyContinue

            # Add to PATH
            $currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
            if ($currentPath -notlike "*$installDir*") {
                [System.Environment]::SetEnvironmentVariable(
                    "Path",
                    "$currentPath;$installDir",
                    "Machine"
                )
                Write-Success "$PROJECT_NAME installed to $installDir"
                Write-Success "Added to system PATH"
            }

            Write-Info "You can now run: phalanx /path/to/project"
        }
        catch {
            Write-Error "Failed to install system-wide: $_"
            Write-Info "You can still run locally: python phalanx.py /path/to/project"
        }
    }
    else {
        Write-Info "Skipping system-wide installation"
        Write-Info "You can run: python phalanx.py /path/to/project"
    }
}

# Verify installation
function Test-Installation {
    Write-Info "Verifying installation..."

    $errors = 0

    # Check Docker
    if (Test-CommandExists "docker") {
        try {
            docker ps | Out-Null
            Write-Success "Docker is running"
        }
        catch {
            Write-Warning "Docker is installed but not running. Please start Docker Desktop."
            $errors++
        }
    }
    else {
        Write-Error "Docker not found"
        $errors++
    }

    # Check Python
    if (Test-CommandExists "python") {
        $pythonVersion = python --version 2>&1
        Write-Success "Python installed ($pythonVersion)"
    }
    else {
        Write-Error "Python not found"
        $errors++
    }

    # Check Git
    if (Test-CommandExists "git") {
        Write-Success "Git installed"
    }
    else {
        Write-Warning "Git not found (optional)"
    }

    if ($errors -eq 0) {
        Write-Success "All required dependencies are installed!"
        return $true
    }
    else {
        Write-Error "Some dependencies are missing or not configured correctly"
        return $false
    }
}

# Main installation flow
function Main {
    Write-Header

    # Check for administrator privileges
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This script must be run as Administrator"
        Write-Info "Right-click PowerShell and select 'Run as Administrator'"
        exit 1
    }

    Write-Info "Detecting package manager..."
    $pkgMgr = Get-PackageManager

    if ($pkgMgr -eq "none") {
        Write-Warning "No package manager found (winget or Chocolatey)"
        $response = Read-Host "Install Chocolatey package manager? (y/N)"
        if ($response -match '^[Yy]$') {
            Install-Chocolatey
        }
        else {
            Write-Error "Package manager required for automatic installation"
            exit 1
        }
    }
    else {
        Write-Success "Found package manager: $pkgMgr"
    }

    Write-Host "`n"
    Write-Info "Installing dependencies..."
    Write-Host "`n"

    Install-Docker
    Install-Python
    Install-Git

    Write-Host "`n"
    $verified = Test-Installation

    if ($verified) {
        Write-Host "`n"
        Install-Phalanx
    }

    Write-Host "`n"
    Write-Success "═══════════════════════════════════════════════"
    Write-Success "  $PROJECT_NAME installation complete!"
    Write-Success "═══════════════════════════════════════════════"
    Write-Host "`n"
    Write-Info "Next steps:"
    Write-Host "  1. Restart your computer (if Docker or Python were just installed)"
    Write-Host "  2. Start Docker Desktop"
    Write-Host "  3. Run: phalanx --version"
    Write-Host "  4. Scan a project: phalanx C:\path\to\php\project"
    Write-Host "`n"
    Write-Info "Documentation: https://github.com/yourusername/phalanx"
    Write-Host "`n"
}

# Run main function
try {
    Main
}
catch {
    Write-Error "Installation failed: $_"
    Write-Info "Please report this issue at: https://github.com/yourusername/phalanx/issues"
    exit 1
}
