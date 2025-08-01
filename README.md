![alt tag](img/main_logo.jpg)

# AegisPHP

## Background/Lore
AegisPHP was born from the frustration of wrestling with incompatible PHP SAST installers on host systems. It bundles the three best open-source PHP security scanners�Psalm, ProgPilot, and psecio/parse�into one Docker image, and provides a single Python CLI to orchestrate and normalize all findings into a unified report.

## Table of Contents
- [Features](#features)  
- [Installation](#installation)  
  - [Prerequisites](#prerequisites)  
  - [Build Docker Image](#build-docker-image)  
- [Flags](#flags)  
  - [Usage](#usage)  
  - [Running a Scan](#running-a-scan)  
- [Contributing](#contributing)  
- [License](#license)  

## Features
- **All-in-One Docker Image**: No host PHP tinkering�just one image with all three security tools.
- **Unified CLI (`aegisphp.py`)**: Single command to launch every scan, normalize outputs, and produce a central JSON report.
- **Auto-Build**: The Python script will build the Docker image on first run if it doesn�t exist.
- **Customizable Output**: Specify `-o <path>` or get a timestamped default file `AegisPHP_output-<YYYYMMDD_HHMMSS>.json`.
- **Stdout Streaming**: See scan progress and results live in your terminal.

## Installation

### Prerequisites
- Docker ≥ 20.x
- Python 3.8+  

### Build Docker Image
```bash
# (Optional) build by hand; otherwise the script will auto-build
docker build -t aegisphp .
```

## Flags

Flag | Description
--- | ---
`-o`, `--output` | Path to write combined JSON report (default: timestamped in cwd)

### Usage

Running a Scan
```bash
./aegisphp.py /path/to/php/project
```
Or specify your own output path:
```bash
./aegisphp.py /path/to/project -o /path/to/my-report.json
```
You'll see each tool's progress in stdout, and at the end a combined JSON report.

---

## ⚙️ Makefile

```makefile
IMAGE_NAME := aegisphp
TARGET     ?= .
OUTPUT     ?= AegisPHP_output-$(shell date +"%Y%m%d_%H%M%S").json

# Build or rebuild the Docker image
build:
  docker build -t $(IMAGE_NAME) .

# Run the full security scan
scan: build
  ./aegisphp.py $(TARGET) -o $(OUTPUT)

# Remove the Docker image
clean:
  docker image rm -f $(IMAGE_NAME) || true

.PHONY: build scan clean
```

## Contributing
	1.	Fork the repo
	2.	Create a branch (git checkout -b feature/my-scan-rule)
	3.	Submit a PR with tests or examples for new rules or normalizations

Please keep the focus strictly on PHP security scanning�no lint or style features.

## License

This project is licensed under the GNU GPL v3.0. See LICENSE for details.



