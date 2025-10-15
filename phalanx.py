#!/usr/bin/env python3
"""
PHALANX - PHP Security Analysis Tool
A unified PHP SAST orchestrator using Psalm, parse, and ProgPilot
Version: 0.1.0
"""
import argparse
import subprocess
import os
import sys
import json
import logging
import re
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple

__version__ = "0.1.0"
IMAGE_NAME = "phalanx"

# Configure logging with security-conscious settings
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stderr)]
)
logger = logging.getLogger("PHALANX")

# Severity normalization mapping
SEV_MAP = {
    "info": "low",
    "notice": "low",
    "warning": "medium",
    "error": "high",
    "critical": "critical"
}

def validate_docker_installed() -> bool:
    """Check if Docker is installed and accessible."""
    try:
        subprocess.run(
            ["docker", "--version"],
            check=True,
            capture_output=True,
            timeout=5
        )
        return True
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        logger.error("Docker is not installed or not accessible")
        return False

def validate_path(path: str) -> Tuple[bool, str]:
    """
    Validate that the provided path is safe and exists.
    Returns: (is_valid, absolute_path)
    """
    try:
        abs_path = os.path.abspath(path)
        # Ensure path exists and is a directory
        if not os.path.exists(abs_path):
            logger.error(f"Path does not exist: {abs_path}")
            return False, ""
        if not os.path.isdir(abs_path):
            logger.error(f"Path is not a directory: {abs_path}")
            return False, ""
        # Check if path is readable
        if not os.access(abs_path, os.R_OK):
            logger.error(f"Path is not readable: {abs_path}")
            return False, ""
        return True, abs_path
    except Exception as e:
        logger.error(f"Path validation error: {e}")
        return False, ""

def sanitize_output_path(output_path: str) -> Tuple[bool, str]:
    """
    Validate and sanitize output file path.
    Returns: (is_valid, absolute_path)
    """
    try:
        abs_path = os.path.abspath(output_path)
        parent_dir = os.path.dirname(abs_path)

        # Ensure parent directory exists and is writable
        if not os.path.exists(parent_dir):
            logger.error(f"Output directory does not exist: {parent_dir}")
            return False, ""
        if not os.access(parent_dir, os.W_OK):
            logger.error(f"Output directory is not writable: {parent_dir}")
            return False, ""

        # Validate file extension
        if not abs_path.endswith('.json'):
            logger.warning("Output file should have .json extension, appending it")
            abs_path += '.json'

        return True, abs_path
    except Exception as e:
        logger.error(f"Output path validation error: {e}")
        return False, ""

def ensure_image(dockerfile_dir: str) -> bool:
    """Build the Docker image if it doesn't already exist."""
    try:
        result = subprocess.run(
            ["docker", "images", "-q", IMAGE_NAME],
            capture_output=True,
            text=True,
            timeout=30,
            check=True
        )
        existing = result.stdout.strip()
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
        logger.error(f"Failed to check for existing Docker image: {e}")
        return False

    if not existing:
        logger.info(f"Building Docker image '{IMAGE_NAME}'...")
        try:
            subprocess.run(
                ["docker", "build", "-t", IMAGE_NAME, dockerfile_dir],
                check=True,
                timeout=600  # 10 minute timeout for building
            )
            logger.info(f"Successfully built Docker image '{IMAGE_NAME}'")
            return True
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
            logger.error(f"Failed to build Docker image: {e}")
            return False

    return True

def run_tool(cmd: List[str], tool_name: str) -> str:
    """
    Run a command safely with timeout and error handling.
    Returns stdout as string or empty JSON object on error.
    """
    try:
        logger.debug(f"Running command: {' '.join(cmd)}")
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=300,  # 5 minute timeout per tool
            check=False  # Don't raise on non-zero exit
        )

        if result.returncode != 0 and result.stderr:
            logger.warning(f"{tool_name} completed with warnings/errors: {result.stderr[:200]}")

        return result.stdout or "{}"
    except subprocess.TimeoutExpired:
        logger.error(f"{tool_name} execution timed out after 5 minutes")
        return "{}"
    except Exception as e:
        logger.error(f"Error running {tool_name}: {e}")
        return "{}"

def normalize_psalm(data: Dict) -> List[Dict]:
    """Normalize Psalm output to standard format."""
    findings = []
    try:
        for issue in data.get("issues", []):
            sev = issue.get("severity", "").lower()
            findings.append({
                "tool": "psalm",
                "title": str(issue.get("message", ""))[:500],  # Limit title length
                "file": str(issue.get("file_name", ""))[:1000],
                "line": int(issue.get("line_from", 0)),
                "severity": SEV_MAP.get(sev, "medium"),
                "code": str(issue.get("snippet", "")).strip()[:1000],
                "metadata": {
                    "type": str(issue.get("type", ""))[:100],
                    "link": str(issue.get("link", ""))[:500]
                }
            })
    except Exception as e:
        logger.error(f"Error normalizing Psalm output: {e}")
    return findings

def normalize_parse(data: Dict) -> List[Dict]:
    """Normalize psecio/parse output to standard format."""
    findings = []
    try:
        for issue in data.get("findings", []):
            sev = issue.get("severity", "warning").lower()
            findings.append({
                "tool": "parse",
                "title": str(issue.get("title") or issue.get("message", ""))[:500],
                "file": str(issue.get("file", ""))[:1000],
                "line": int(issue.get("line", 0)),
                "severity": SEV_MAP.get(sev, "medium"),
                "code": str(issue.get("code", ""))[:1000],
                "metadata": {"rule": str(issue.get("rule", ""))[:100]}
            })
    except Exception as e:
        logger.error(f"Error normalizing parse output: {e}")
    return findings

def normalize_progpilot(data: Dict) -> List[Dict]:
    """Normalize ProgPilot output to standard format."""
    findings = []
    try:
        for issue in data.get("results", []):
            sev = issue.get("severity", "medium").lower()
            findings.append({
                "tool": "progpilot",
                "title": str(issue.get("description") or issue.get("message", ""))[:500],
                "file": str(issue.get("file", ""))[:1000],
                "line": int(issue.get("line", 0)),
                "severity": SEV_MAP.get(sev, "medium"),
                "code": str(issue.get("code", ""))[:1000],
                "metadata": {"rule": str(issue.get("rule_name", ""))[:100]}
            })
    except Exception as e:
        logger.error(f"Error normalizing ProgPilot output: {e}")
    return findings

def main() -> int:
    """Main entry point for PHALANX."""
    parser = argparse.ArgumentParser(
        description="PHALANX: Unified PHP SAST orchestrator (Psalm, parse, ProgPilot)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=f"PHALANX v{__version__}\nA defensive security tool for PHP vulnerability detection."
    )
    parser.add_argument(
        "target",
        help="Path to PHP project directory to scan"
    )
    parser.add_argument(
        "-o", "--output",
        help="Path for combined JSON report (default: timestamped in cwd)"
    )
    parser.add_argument(
        "-v", "--version",
        action="version",
        version=f"PHALANX v{__version__}"
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable verbose logging"
    )

    args = parser.parse_args()

    if args.verbose:
        logger.setLevel(logging.DEBUG)

    logger.info(f"PHALANX v{__version__} - PHP Security Analysis Tool")

    # Validate Docker installation
    if not validate_docker_installed():
        logger.error("Docker is required but not found. Please install Docker and try again.")
        return 1

    # Validate target directory
    is_valid, target_dir = validate_path(args.target)
    if not is_valid:
        logger.error(f"Invalid target directory: {args.target}")
        return 1

    logger.info(f"Target directory: {target_dir}")

    # Determine Dockerfile location (script's directory)
    docker_dir = os.path.dirname(os.path.abspath(__file__))

    # Ensure the Docker image is built
    if not ensure_image(docker_dir):
        logger.error("Failed to build or find Docker image")
        return 1

    # Run each security tool in its container
    logger.info("Running Psalm security scanner...")
    psalm_cmd = [
        "docker", "run", "--rm",
        "--security-opt=no-new-privileges",
        "--cap-drop=ALL",
        "-v", f"{target_dir}:/app:ro",
        IMAGE_NAME,
        "psalm", "--output-format=json"
    ]
    psalm_out = run_tool(psalm_cmd, "Psalm")

    try:
        psalm_json = json.loads(psalm_out)
    except json.JSONDecodeError:
        logger.warning("Psalm output is not valid JSON, using empty result")
        psalm_json = {}

    logger.info("Running psecio/parse security scanner...")
    parse_cmd = [
        "docker", "run", "--rm",
        "--security-opt=no-new-privileges",
        "--cap-drop=ALL",
        "-v", f"{target_dir}:/app:ro",
        IMAGE_NAME,
        "parse", "scan", "/app", "--format", "json"
    ]
    parse_out = run_tool(parse_cmd, "parse")

    try:
        parse_json = json.loads(parse_out)
    except json.JSONDecodeError:
        logger.warning("parse output is not valid JSON, using empty result")
        parse_json = {}

    logger.info("Running ProgPilot security scanner...")
    prog_cmd = [
        "docker", "run", "--rm",
        "--security-opt=no-new-privileges",
        "--cap-drop=ALL",
        "-v", f"{target_dir}:/workspace:ro",
        IMAGE_NAME,
        "php", "/home/phalanx/progpilot/src/ProgPilot.php",
        "--level", "high", "--target", "/workspace", "--output=json"
    ]
    prog_out = run_tool(prog_cmd, "ProgPilot")

    try:
        prog_json = json.loads(prog_out)
    except json.JSONDecodeError:
        logger.warning("ProgPilot output is not valid JSON, using empty result")
        prog_json = {}

    # Normalize all findings
    all_findings = []
    all_findings.extend(normalize_psalm(psalm_json))
    all_findings.extend(normalize_parse(parse_json))
    all_findings.extend(normalize_progpilot(prog_json))

    # Build summary statistics
    summary = {
        "total_findings": len(all_findings),
        "by_tool": {},
        "by_severity": {"low": 0, "medium": 0, "high": 0, "critical": 0},
        "scan_timestamp": datetime.utcnow().isoformat() + "Z",
        "phalanx_version": __version__
    }

    for finding in all_findings:
        tool = finding.get("tool", "unknown")
        severity = finding.get("severity", "medium")
        summary["by_tool"][tool] = summary["by_tool"].get(tool, 0) + 1
        summary["by_severity"][severity] = summary["by_severity"].get(severity, 0) + 1

    report = {
        "summary": summary,
        "findings": all_findings
    }

    # Determine output path
    if args.output:
        is_valid, out_path = sanitize_output_path(args.output)
        if not is_valid:
            logger.error(f"Invalid output path: {args.output}")
            return 1
    else:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        default_name = f"PHALANX_output-{timestamp}.json"
        out_path = os.path.join(os.getcwd(), default_name)

    # Write report to file
    try:
        with open(out_path, "w", encoding="utf-8") as fd:
            json.dump(report, fd, indent=2, ensure_ascii=False)
        logger.info(f"Combined report written to: {out_path}")
    except IOError as e:
        logger.error(f"Failed to write report file: {e}")
        return 1

    # Display summary to stdout
    print("\n" + "="*60)
    print(f"PHALANX v{__version__} - Scan Complete")
    print("="*60)
    print(f"Total Findings: {summary['total_findings']}")
    print(f"  Critical: {summary['by_severity']['critical']}")
    print(f"  High:     {summary['by_severity']['high']}")
    print(f"  Medium:   {summary['by_severity']['medium']}")
    print(f"  Low:      {summary['by_severity']['low']}")
    print("\nFindings by Tool:")
    for tool, count in summary["by_tool"].items():
        print(f"  {tool}: {count}")
    print(f"\nReport saved to: {out_path}")
    print("="*60 + "\n")

    return 0

if __name__ == "__main__":
    sys.exit(main())
