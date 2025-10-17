# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**PHALANX** (PHP Advanced Holistic Analysis for Nix/Unix eXamination) is a unified PHP Static Application Security Testing (SAST) orchestrator. It bundles three security scanners—Psalm v6, Semgrep, and ProgPilot—into a single Docker image with a Python CLI orchestrator.

**Key Architecture Principle**: Security-first design with defense in depth:
- All scanners run in isolated Docker containers with hardened security (no-new-privileges, capability drops, read-only mounts)
- Python orchestrator validates inputs, normalizes outputs, and enforces timeouts
- Non-root execution everywhere (containers run as `phalanx` user)

## Development Commands

### Building and Testing
```bash
# Build the Docker image (required for running scans)
make build

# Run all tests (syntax, type checking, linting, Docker build test)
make test

# Run version check (tests Python script without Docker)
python3 phalanx.py --version
```

### Running Scans
```bash
# Basic scan (auto-builds Docker image if needed)
./phalanx.py /path/to/php/project

# Scan with custom output and verbose logging
./phalanx.py /path/to/php/project -o report.json --verbose

# Using Make (includes auto-build)
make scan TARGET=/path/to/php/project OUTPUT=report.json
```

### Development Workflow
```bash
# Test syntax after changes
python3 -m py_compile phalanx.py

# Run linters if installed
make lint  # Runs pylint, mypy, flake8

# Clean Docker artifacts
make clean      # Removes Docker image only
make clean-all  # Removes image + output files
```

## Code Architecture

### Single-File Design
The entire orchestrator is in `phalanx.py` (~390 lines). There are no modules or packages—everything is self-contained by design for easy distribution.

### Core Flow (phalanx.py:219-390)
1. **Input Validation** (phalanx.py:52-100): Path validation with security checks (exists, readable, no traversal)
2. **Docker Image Management** (phalanx.py:102-131): Auto-build if missing, with timeout protection
3. **Scanner Orchestration** (phalanx.py:133-157): Run each tool via Docker with:
   - Read-only target mounts (`/app:ro` or `/workspace:ro`)
   - Security options (`--security-opt=no-new-privileges`, `--cap-drop=ALL`)
   - 5-minute timeout per scanner
4. **Output Normalization** (phalanx.py:159-217): Convert each scanner's JSON to standard format:
   - Psalm: `normalize_psalm()` - handles Vimeo/Psalm JSON structure
   - psecio/parse: `normalize_parse()` - handles parse findings format
   - ProgPilot: `normalize_progpilot()` - handles ProgPilot results format
5. **Report Generation** (phalanx.py:326-385): Summary statistics + normalized findings in unified JSON

### Severity Mapping (phalanx.py:29-36)
All scanners normalize to: `low`, `medium`, `high`, `critical`. Mapping defined in `SEV_MAP` dict.

### Dockerfile Architecture
- **Base**: PHP 8.4-cli with security updates
- **Non-root user**: `phalanx` (UID 1000) for all operations
- **Tool Installation**:
  - Psalm & parse: Installed globally via Composer
  - ProgPilot: Cloned to `/home/phalanx/progpilot`
- **No ENTRYPOINT**: Allows direct tool invocation (e.g., `docker run phalanx psalm --version`)
- **Healthcheck**: Validates Psalm and parse are accessible

### Output Format
Generated JSON structure:
```json
{
  "summary": {
    "total_findings": N,
    "by_tool": {"psalm": X, "parse": Y, "progpilot": Z},
    "by_severity": {"low": A, "medium": B, "high": C, "critical": D},
    "scan_timestamp": "ISO-8601",
    "phalanx_version": "0.1.0"
  },
  "findings": [
    {
      "tool": "psalm|parse|progpilot",
      "title": "Issue description (max 500 chars)",
      "file": "/app/path/to/file.php (max 1000 chars)",
      "line": N,
      "severity": "low|medium|high|critical",
      "code": "Code snippet (max 1000 chars)",
      "metadata": {...}
    }
  ]
}
```

## Security Considerations

### Input Validation Patterns
When modifying validation functions:
- Always use `os.path.abspath()` to normalize paths (phalanx.py:58)
- Check existence, type (dir vs file), and permissions before use
- Wrap in try-except with explicit error logging
- Return tuples: `(is_valid: bool, result: str)` for clear error handling

### Subprocess Safety
All `subprocess.run()` calls MUST include:
- `timeout=N` parameter (no infinite hangs)
- `check=False` unless failure is truly fatal (scanners may return non-zero on findings)
- `capture_output=True, text=True` for safe output handling

### String Length Limits
All user-controlled or scanner-generated strings have limits (phalanx.py:169-175):
- Titles: 500 chars
- File paths: 1000 chars
- Code snippets: 1000 chars
- Metadata fields: 100-500 chars

## Git Workflow

### Branch Strategy
- `main`: Stable releases, protected
- `dev`: Active development
- Feature branches merge to `dev`, then `dev` → `main` for releases

### Versioning (Semantic Versioning 2.0.0)
- Version defined in `phalanx.py:18` as `__version__ = "X.Y.Z"`
- Update version in:
  1. `phalanx.py:18`
  2. `Dockerfile:8` (LABEL version)
  3. `Makefile:12` (VERSION variable)
  4. `CHANGELOG.md` (new section)
- **MAJOR**: Breaking CLI changes, output format changes
- **MINOR**: New features, new scanners, backward-compatible
- **PATCH**: Bug fixes, documentation updates

### Release Process
1. Update version in all files
2. Update `CHANGELOG.md` with changes
3. Commit to `dev` branch
4. Merge `dev` → `main`
5. Create tag: `git tag -a vX.Y.Z -m "Version X.Y.Z"`
6. Push tag: `git push origin vX.Y.Z`
7. CI/CD auto-creates GitHub release with Docker images

## CI/CD Pipeline (.github/workflows/ci.yml)

### Jobs
1. **lint**: Pylint, mypy, flake8, syntax check
2. **build-docker**: Multi-platform Docker builds (Linux amd64/arm64, macOS, Windows)
3. **test-python**: Matrix testing across Python 3.8-3.12 on Ubuntu/macOS/Windows
4. **build-and-push**: Multi-arch Docker images to ghcr.io (only on main/tags)
5. **release**: Auto-creates GitHub releases on version tags
6. **test-install**: Validates install scripts
7. **security**: Trivy (Dockerfile), Bandit (Python)

### Trigger Conditions
- Push to `main` or `dev`: Runs lint, build, test
- Push tags `v*`: Full pipeline + Docker publish + GitHub release
- Pull requests to `main`/`dev`: Full test suite

## Docker Container Invocation Patterns

When modifying scanner commands:
```bash
docker run --rm \
  --security-opt=no-new-privileges \  # Prevent privilege escalation
  --cap-drop=ALL \                     # Drop all Linux capabilities
  -v "/host/path:/container/path:ro" \ # Read-only mount
  phalanx \                             # Image name
  [tool-specific command]               # e.g., "psalm --output-format=json"
```

### Tool-Specific Paths
- **Psalm**: Scans `/app` (mounted target directory), executed with `sh -c "cd /app && psalm --output-format=json --no-cache --no-file-cache ."`
  - Note: Psalm v0.2.16 requires running from project directory and requires psalm.xml OR will fail gracefully
- **psecio/parse**: Uses `sh -c "parse scan /app --format json 2>&1 | tail -1"` to extract JSON from stderr noise
  - Output format: `{"results": {"error": {...}}}` for syntax errors or `{"findings": [...]}` for security findings
- **ProgPilot**: Scans `/workspace` (mounted target directory), invoked as `php /home/phalanx/progpilot_wrapper.php /workspace`
  - Uses custom PHP wrapper script (`progpilot_wrapper.php`) to provide JSON output from library API

## Makefile Targets Reference

- `make help`: Display all available targets
- `make build`: Build Docker image
- `make rebuild`: Build without cache (for troubleshooting)
- `make scan`: Run scan (set `TARGET=` and optionally `OUTPUT=`)
- `make test`: Full test suite (syntax, types, lint, Docker)
- `make install`: System-wide install to `/usr/local/bin/phalanx` (requires sudo)
- `make uninstall`: Remove system-wide installation
- `make clean`: Remove Docker image
- `make clean-all`: Remove Docker image + output files + Python artifacts
- `make lint`: Run code quality checks (pylint, mypy, flake8)
- `make version`: Display PHALANX version

## Common Development Tasks

### Adding a New Scanner
1. Update `Dockerfile` to install the tool (via Composer or git clone)
2. Add scanner invocation in `main()` (follow existing pattern with Docker run)
3. Create `normalize_<toolname>()` function to map output to standard format
4. Update severity mapping if scanner uses different levels
5. Test with sample PHP project containing known vulnerabilities
6. Update README.md with scanner description

### Modifying Output Format
⚠️ **Breaking Change (MAJOR version)** - Coordinate with users before changing:
1. Update normalization functions to include new fields
2. Update `report` dict structure in `main()`
3. Update README.md output format documentation
4. Add migration notes to CHANGELOG.md
5. Bump MAJOR version

### Changing Docker Security Hardening
Test carefully—overly restrictive settings may break scanners:
1. Modify Docker run commands in `main()` (phalanx.py:275-318)
2. Test each scanner individually with test PHP projects
3. Document any capability requirements if ALL caps can't be dropped
4. Update CHANGELOG.md security section

## Installation Scripts

### Unix/Linux/macOS (scripts/install.sh)
- Auto-detects OS (Ubuntu, Debian, RHEL, CentOS, Fedora, macOS)
- Installs Docker and Python 3 if missing
- Optionally installs PHALANX system-wide
- Sets executable permissions

### Windows (scripts/install.ps1)
- Detects package managers (winget, chocolatey)
- Installs Docker Desktop, Python 3, Git
- Configures PATH for command-line access
- Requires Administrator privileges

## Testing Notes

### Manual Testing Workflow
1. Find or create sample PHP project with security issues
2. Run: `./phalanx.py /path/to/vulnerable/php/project -o test-report.json --verbose`
3. Verify:
   - Docker image builds successfully
   - All three scanners execute without errors
   - Output JSON is valid and contains findings
   - Summary statistics are accurate
   - Exit code is 0

### CI/CD Testing
- Syntax validation runs on all Python versions 3.8-3.12
- Docker builds tested on Linux (amd64, arm64), macOS, Windows
- Security scanning with Trivy (Dockerfile) and Bandit (Python)

### Known Limitations
- No unit tests yet (planned for future release)
- **Psalm v6** requires projects to have a Composer autoloader
  - Will fail gracefully with informative error if no `composer.json` is found
  - Auto-initializes `psalm.xml` if missing using `--init`
- **Semgrep** requires internet connectivity for `--config=auto` to fetch rules
  - Can be configured to use local rules in future versions
  - Outputs telemetry warnings (cosmetic, doesn't affect functionality)
- **ProgPilot** doesn't have a working CLI in the version cloned from GitHub
  - Solution: Custom wrapper script (`progpilot_wrapper.php`) uses ProgPilot as a library
  - Iterates through all `.php` files in target directory recursively

## Project Constraints

### Single-File Philosophy
Keep `phalanx.py` as a single file. This simplifies:
- Distribution (one file + Dockerfile)
- Installation (no Python packages required)
- User understanding (entire logic visible in one place)

### Security-First Development
Every code change should ask:
- Could this accept malicious input? (validate)
- Could this hang indefinitely? (timeout)
- Could this leak information? (sanitize output)
- Could this run with excessive privileges? (drop capabilities)

### Backward Compatibility
For MINOR/PATCH versions:
- CLI arguments must remain compatible
- Output JSON structure must remain compatible (can add fields, not remove/rename)
- Docker image must support same scanner versions (or newer with same APIs)
