![PHALANX Logo](img/main_logo.jpg)

# PHALANX

**PHP Advanced Holistic Analysis for Nix/Unix eXamination**

A unified PHP Static Application Security Testing (SAST) orchestrator that bundles three best-in-class open-source security scanners—Psalm v7, Semgrep, and ProgPilot—into a single Docker image with a Python CLI for seamless vulnerability detection.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Version](https://img.shields.io/badge/version-0.2.0-green.svg)](https://github.com/yourusername/phalanx)
[![Docker](https://img.shields.io/badge/docker-required-blue.svg)](https://www.docker.com/)
[![Python](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/)

---

## Table of Contents

- [Background](#background)
- [Features](#features)
- [Architecture](#architecture)
- [Installation](#installation)
  - [Prerequisites](#prerequisites)
  - [Quick Start](#quick-start)
  - [Platform-Specific Installation](#platform-specific-installation)
- [Usage](#usage)
  - [Basic Scan](#basic-scan)
  - [Command-Line Options](#command-line-options)
  - [Output Format](#output-format)
- [Makefile Commands](#makefile-commands)
- [Security Scanners](#security-scanners)
- [Development](#development)
  - [Building from Source](#building-from-source)
  - [Running Tests](#running-tests)
- [Contributing](#contributing)
- [Versioning](#versioning)
- [License](#license)
- [Acknowledgments](#acknowledgments)

---

## Background

PHALANX was created to solve the frustration of managing incompatible PHP security scanner installations on host systems. Instead of wrestling with conflicting dependencies, incompatible PHP versions, and complex configurations, PHALANX provides:

- **One Docker image** containing all three scanners
- **One command** to run comprehensive security analysis
- **One standardized output format** for all findings

The name PHALANX represents a defensive formation—a unified shield against security vulnerabilities in PHP applications.

---

## Features

- **All-in-One Docker Image**: No host PHP configuration required—all tools bundled in a single container
- **Unified CLI**: Single Python command orchestrates all scanners and normalizes output
- **Auto-Build**: Docker image builds automatically on first run if not present
- **Secure by Default**:
  - Runs containers with `--security-opt=no-new-privileges`
  - Drops all Linux capabilities (`--cap-drop=ALL`)
  - Mounts target directories as read-only
  - Non-root user execution inside containers
- **Comprehensive Validation**: Input validation, path sanitization, timeout protection
- **Detailed Logging**: Structured logging with configurable verbosity
- **Standardized Output**: Normalized JSON reports with severity mapping across all tools
- **Summary Statistics**: Aggregated findings by tool and severity level
- **Cross-Platform**: Works on Linux, macOS, and Windows (with Docker)

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│           User: ./phalanx.py /path/to/php       │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────┐
│         phalanx.py (Python Orchestrator)        │
│  • Input validation                             │
│  • Docker management                            │
│  • Output normalization                         │
│  • Report generation                            │
└─────────────────┬───┬───┬───────────────────────┘
                  │   │   │
      ┌───────────┘   │   └───────────┐
      │               │               │
┌─────▼─────┐  ┌─────▼─────┐  ┌─────▼─────┐
│   Psalm   │  │   parse   │  │ ProgPilot │
│ Container │  │ Container │  │ Container │
└─────┬─────┘  └─────┬─────┘  └─────┬─────┘
      │               │               │
      └───────────┬───┴───────────────┘
                  │
      ┌───────────▼────────────────┐
      │  Normalized JSON Report    │
      │  • Summary statistics      │
      │  • Findings by tool        │
      │  • Severity classification │
      └────────────────────────────┘
```

---

## Installation

### Prerequisites

- **Docker** ≥ 20.x ([Install Docker](https://docs.docker.com/get-docker/))
- **Python** 3.8+ ([Install Python](https://www.python.org/downloads/))
- **Git** (for cloning the repository)

### Quick Start

#### Using the Install Script (Recommended)

**Linux/macOS/Unix:**
```bash
curl -sSL https://raw.githubusercontent.com/yourusername/phalanx/main/install.sh | bash
```

Or download and run manually:
```bash
git clone https://github.com/yourusername/phalanx.git
cd phalanx
chmod +x install.sh
./install.sh
```

**Windows (PowerShell as Administrator):**
```powershell
irm https://raw.githubusercontent.com/yourusername/phalanx/main/install.ps1 | iex
```

Or download and run manually:
```powershell
git clone https://github.com/yourusername/phalanx.git
cd phalanx
.\install.ps1
```

#### Manual Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/phalanx.git
cd phalanx

# Make the script executable
chmod +x phalanx.py

# Run your first scan (Docker image will auto-build)
./phalanx.py /path/to/php/project
```

### Platform-Specific Installation

<details>
<summary><b>Ubuntu/Debian</b></summary>

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install -y docker.io python3 python3-pip git

# Enable Docker
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

# Clone and run
git clone https://github.com/yourusername/phalanx.git
cd phalanx
./phalanx.py --version
```
</details>

<details>
<summary><b>RHEL/CentOS/Fedora</b></summary>

```bash
# Install dependencies
sudo yum install -y docker python3 python3-pip git

# Enable Docker
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

# Clone and run
git clone https://github.com/yourusername/phalanx.git
cd phalanx
./phalanx.py --version
```
</details>

<details>
<summary><b>macOS</b></summary>

```bash
# Install Homebrew if not present
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install docker python3 git
brew install --cask docker

# Start Docker Desktop
open -a Docker

# Clone and run
git clone https://github.com/yourusername/phalanx.git
cd phalanx
./phalanx.py --version
```
</details>

<details>
<summary><b>Windows</b></summary>

```powershell
# Install using winget (Windows Package Manager)
winget install Docker.DockerDesktop
winget install Python.Python.3
winget install Git.Git

# Or use Chocolatey
choco install docker-desktop python3 git -y

# Clone and run
git clone https://github.com/yourusername/phalanx.git
cd phalanx
python phalanx.py --version
```
</details>

---

## Usage

### Basic Scan

```bash
# Scan a PHP project
./phalanx.py /path/to/php/project

# Specify custom output path
./phalanx.py /path/to/php/project -o my-report.json

# Enable verbose logging
./phalanx.py /path/to/php/project --verbose
```

### Command-Line Options

```
usage: phalanx.py [-h] [-o OUTPUT] [-v] [--verbose] target

PHALANX: Unified PHP SAST orchestrator (Psalm, parse, ProgPilot)

positional arguments:
  target                Path to PHP project directory to scan

optional arguments:
  -h, --help            Show this help message and exit
  -o OUTPUT, --output OUTPUT
                        Path for combined JSON report (default: timestamped in cwd)
  -v, --version         Show program's version number and exit
  --verbose             Enable verbose logging
```

### Output Format

PHALANX generates a comprehensive JSON report with the following structure:

```json
{
  "summary": {
    "total_findings": 42,
    "by_tool": {
      "psalm": 15,
      "parse": 12,
      "progpilot": 15
    },
    "by_severity": {
      "critical": 2,
      "high": 8,
      "medium": 20,
      "low": 12
    },
    "scan_timestamp": "2025-10-15T12:34:56Z",
    "phalanx_version": "0.1.0"
  },
  "findings": [
    {
      "tool": "psalm",
      "title": "PossibleRawObjectIteration",
      "file": "/app/src/Controller.php",
      "line": 42,
      "severity": "medium",
      "code": "$user = $this->getUser();",
      "metadata": {
        "type": "PossibleRawObjectIteration",
        "link": "https://psalm.dev/..."
      }
    }
  ]
}
```

**Severity Levels:**
- `critical`: Exploitable vulnerabilities requiring immediate attention
- `high`: Serious security issues that should be fixed soon
- `medium`: Moderate security concerns
- `low`: Minor issues and code quality improvements

---

## Makefile Commands

```bash
# Build the Docker image
make build

# Run a scan using the Makefile
make scan TARGET=/path/to/project OUTPUT=report.json

# Clean up Docker images
make clean

# Run tests
make test

# Install PHALANX system-wide
make install

# Uninstall PHALANX
make uninstall
```

---

## Security Scanners

PHALANX orchestrates three industry-leading PHP security scanners:

### 1. Psalm v6 (by Vimeo)
- **Type**: Advanced static analysis tool with security focus
- **Version**: v6.13.1 (latest stable, PHP 8.4 compatible)
- **Strengths**: Type safety, undefined variable detection, SQL injection patterns, dead code detection
- **Website**: https://psalm.dev/

### 2. Semgrep
- **Type**: Modern security-focused pattern scanner
- **Version**: v1.102.0
- **Strengths**: OWASP vulnerability detection, 100+ PHP security rules, actively maintained
- **Website**: https://semgrep.dev/

### 3. ProgPilot
- **Type**: Taint analysis security scanner
- **Strengths**: Data flow analysis, XSS/SQLi detection, user input tracking
- **Website**: https://github.com/designsecurity/progpilot

---

## Development

### Building from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/phalanx.git
cd phalanx

# Build Docker image
docker build -t phalanx .

# Run from source
python3 phalanx.py /path/to/project
```

### Running Tests

```bash
# Run Python tests
python3 -m pytest tests/

# Run linter
python3 -m pylint phalanx.py

# Type checking
python3 -m mypy phalanx.py

# Test Docker build
docker build -t phalanx-test .
```

---

## Contributing

We welcome contributions! Please follow these guidelines:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/my-security-rule`
3. **Make your changes**:
   - Add tests for new functionality
   - Update documentation
   - Follow PEP 8 style guidelines
   - Keep focus on security scanning (no linting/style features)
4. **Run tests**: Ensure all tests pass
5. **Submit a Pull Request** with a clear description

### Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Security issues should be reported privately (see SECURITY.md)

---

## Versioning

PHALANX follows [Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR**: Incompatible API changes
- **MINOR**: Backward-compatible functionality additions
- **PATCH**: Backward-compatible bug fixes

**Current Version**: 0.2.0

See [CHANGELOG.md](CHANGELOG.md) for version history.

---

## License

This project is licensed under the **GNU General Public License v3.0**.

See [LICENSE](LICENSE) for full details.

### Summary

- ✅ You can use, modify, and distribute this software
- ✅ You must disclose the source code
- ✅ Changes must be documented
- ✅ Same license applies to derivatives
- ❌ No warranty provided

---

## Acknowledgments

PHALANX is built on the shoulders of giants:

- **Psalm v7** by Vimeo: https://github.com/vimeo/psalm
- **Semgrep** by Semgrep Inc: https://github.com/semgrep/semgrep
- **ProgPilot** by designsecurity: https://github.com/designsecurity/progpilot
- **Docker** for containerization
- **Python** community for excellent tooling

---

## Support & Contact

- **Issues**: [GitHub Issues](https://github.com/yourusername/phalanx/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/phalanx/discussions)
- **Security**: See [SECURITY.md](SECURITY.md) for reporting vulnerabilities

---

**Made with ❤️ for the PHP security community**
