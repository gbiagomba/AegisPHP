# Changelog

All notable changes to PHALANX will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Unit tests for all Python functions
- Integration tests with sample PHP projects
- Performance benchmarks
- Additional output formats (SARIF, HTML)
- Configuration file support (.phalanxrc)
- Custom scanner rule support
- Parallel scanner execution
- Progress bars for long scans

---

## [0.2.0] - 2025-10-15

### Changed - Major Scanner Upgrades
#### Scanner Replacements
- **Upgraded Psalm** from v0.2.16 (2017) to **v6.13.1** (latest stable, PHP 8.4 compatible)
  - Full PHP 8.4 support
  - Auto-initialization with `--init` for projects without config
  - Modern type checking and error detection
  - Massive improvement over 8-year-old v0.2.16
- **Replaced psecio/parse** with **Semgrep v1.102.0**
  - Active maintenance (vs. abandoned psecio/parse from 2017)
  - 100+ PHP security rules with OWASP coverage
  - Clean JSON output without deprecation warnings
  - Modern pattern-based security scanning
- **Kept ProgPilot** for unique taint analysis capabilities

#### Dockerfile Updates
- Added Python 3 and pip for Semgrep installation
- Updated Psalm installation to use `^7.0` version constraint
- Removed psecio/parse from global Composer dependencies
- Updated healthcheck to use `semgrep --version` instead of `parse --version`

#### Python Orchestrator Updates (phalanx.py)
- Updated version to 0.2.0
- Modified Psalm command to auto-init config files
- Replaced parse scanner with Semgrep
- Added `normalize_semgrep()` function for Semgrep JSON output
- Removed `normalize_parse()` function
- Updated tool descriptions and help text

#### Documentation Updates
- Updated README.md scanner descriptions
- Modified acknowledgments section
- Updated version badges and references
- Updated CLAUDE.md with new scanner details

### Added
- Semgrep normalization with support for ERROR/WARNING/INFO severity levels
- Confidence metadata in Semgrep findings
- Auto-initialization for Psalm v7 projects

### Removed
- psecio/parse scanner and all related code
- parse normalization function
- Deprecated PHP warnings from scanner output

### Fixed
- Psalm now works on projects without existing `psalm.xml` configuration
- Eliminated hundreds of deprecation warnings from old scanner dependencies
- Improved JSON parsing reliability with modern scanner outputs

---

## [0.1.0] - 2025-10-15

### Added - Initial Release

#### Core Functionality
- **Renamed from AegisPHP to PHALANX** with full rebranding
- Unified PHP SAST orchestrator combining Psalm, psecio/parse, and ProgPilot
- Docker-based architecture for cross-platform compatibility
- Python 3.8+ CLI tool with comprehensive argument parsing

#### Security Enhancements
- **Secure code by default**: All subprocess calls include timeouts
- **Input validation**: Path validation and sanitization for all user inputs
- **Docker security hardening**:
  - `--security-opt=no-new-privileges` on all container runs
  - `--cap-drop=ALL` to drop all Linux capabilities
  - Read-only mounts for target directories
  - Non-root user execution inside containers
- **Error handling**: Comprehensive try-catch blocks with proper logging
- **Output limits**: String length limits on all normalized findings
- **JSON validation**: Proper JSON decode error handling

#### Features
- Automatic Docker image building on first run
- Standardized JSON output format with severity normalization
- Summary statistics by tool and severity level
- Timestamped output files with customizable paths
- Verbose logging mode with structured log output
- Version command (`--version`) for easy version checking

#### Documentation
- Comprehensive README.md with:
  - Installation instructions for Linux, macOS, and Windows
  - Platform-specific guides (Ubuntu, Debian, RHEL, CentOS, Fedora, macOS, Windows)
  - Usage examples and command-line reference
  - Architecture diagrams
  - Contributing guidelines
- CHANGELOG.md following Keep a Changelog format
- Detailed inline code documentation with docstrings
- GPL v3.0 LICENSE file

#### Build System
- **Makefile** with targets:
  - `build`: Build Docker image
  - `rebuild`: Rebuild with no cache
  - `scan`: Run security scan
  - `test`: Run tests and linters
  - `install`: System-wide installation
  - `uninstall`: System-wide removal
  - `clean`: Remove Docker images
  - `clean-all`: Remove all artifacts

#### Dockerfile Improvements
- Multi-stage build foundation for future optimization
- Security metadata labels (version, description)
- Non-root user (`phalanx`) for all operations
- Minimal attack surface with `--no-install-recommends`
- Healthcheck for container monitoring
- Cleaned apt caches to reduce image size
- Shallow git clone (`--depth 1`) for ProgPilot

#### Installation Scripts
- **install.sh**: Cross-platform Unix/Linux/macOS installer
  - Automatic OS detection (Ubuntu, Debian, RHEL, CentOS, Fedora, macOS)
  - Package manager detection (apt, yum, dnf, brew)
  - Docker and Python dependency installation
  - Optional system-wide installation
- **install.ps1**: Windows PowerShell installer
  - Package manager detection (winget, chocolatey)
  - Automated dependency installation
  - Docker Desktop handling
  - PATH configuration

#### CI/CD
- **GitHub Actions workflow** (`.github/workflows/ci.yml`):
  - Multi-platform testing (Ubuntu, macOS, Windows)
  - Multi-architecture support (x64, arm64)
  - Automated Docker builds on push
  - Matrix testing across platforms
  - Automated tagging and releases on version tags
  - Docker image publishing to GitHub Container Registry
  - Build artifact archiving

#### Git & Versioning
- `.gitignore` with comprehensive exclusions for:
  - Python artifacts (`__pycache__`, `*.pyc`)
  - Output files (`PHALANX_output-*.json`)
  - IDE files (`.vscode`, `.idea`)
  - OS files (`.DS_Store`, `Thumbs.db`)
  - Security files (`*.key`, `*.pem`, `credentials.json`)
- Semantic Versioning 2.0.0 compliance
- Git branch structure (main and dev branches)

### Changed
- **Rebranded** from AegisPHP to PHALANX (PHP Advanced Holistic Analysis for Nix/Unix eXamination)
- **Image name** changed from `aegisphp` to `phalanx`
- **Output filename** changed from `AegisPHP_output-*.json` to `PHALANX_output-*.json`
- **ProgPilot path** updated from `/opt/progpilot` to `/home/phalanx/progpilot`
- Enhanced error messages with actionable guidance
- Improved logging with severity levels (INFO, WARNING, ERROR, DEBUG)

### Security
- All subprocess calls protected with 5-10 minute timeouts
- JSON parsing wrapped in try-catch with fallback to empty results
- File I/O operations use explicit UTF-8 encoding
- Docker containers run with minimal privileges
- Input paths validated before use
- Output paths sanitized and parent directories checked

### Fixed
- Potential indefinite hangs from subprocess calls without timeouts
- Missing error handling for malformed JSON from scanners
- Uncaught exceptions during path validation
- Docker image name hardcoding in multiple locations
- Missing exception handling in normalization functions

---

## Historical Context

### Pre-0.1.0 (AegisPHP Era)
- Project existed as "AegisPHP" with basic functionality
- Simple Python script with minimal error handling
- Docker image with three PHP security scanners
- Basic JSON output without standardization
- No installation scripts or comprehensive documentation
- Limited security hardening

---

## Version Numbering Guide

PHALANX follows [Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR** version (X.0.0): Incompatible API changes
- **MINOR** version (0.X.0): Backward-compatible functionality additions
- **PATCH** version (0.0.X): Backward-compatible bug fixes

### Version Increment Examples

**MAJOR (1.0.0)**:
- Breaking changes to CLI arguments
- Changes to output JSON structure
- Removal of features

**MINOR (0.2.0)**:
- New command-line options
- New output formats
- Additional security scanners
- New installation methods

**PATCH (0.1.1)**:
- Bug fixes
- Security patches
- Documentation updates
- Dependency updates

---

## Links

- [PHALANX Repository](https://github.com/yourusername/phalanx)
- [Issue Tracker](https://github.com/yourusername/phalanx/issues)
- [Release Notes](https://github.com/yourusername/phalanx/releases)

---

[Unreleased]: https://github.com/yourusername/phalanx/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/yourusername/phalanx/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/yourusername/phalanx/releases/tag/v0.1.0
