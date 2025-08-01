#!/usr/bin/env python3
import argparse
import subprocess
import shutil
import os
import sys
import json
from datetime import datetime

IMAGE_NAME = "aegisphp"

# Severity normalization
SEV_MAP = {
    "info": "low", "notice": "low",
    "warning": "medium", "error": "high",
    "critical": "critical"
}

def ensure_image(dockerfile_dir):
    """Build the Docker image if it doesn't already exist."""
    try:
        existing = subprocess.check_output(
            ["docker", "images", "-q", IMAGE_NAME],
            text=True
        ).strip()
    except subprocess.CalledProcessError:
        existing = ""
    if not existing:
        print(f"[+] Building Docker image '{IMAGE_NAME}'…")
        subprocess.check_call([
            "docker", "build",
            "-t", IMAGE_NAME,
            dockerfile_dir
        ])

def run_tool(cmd):
    """Run a command, capture stdout, return (stdout_text or '{}')."""
    try:
        out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True)
    except subprocess.CalledProcessError as e:
        out = e.output or "{}"
    return out

def normalize_psalm(data):
    findings = []
    for issue in data.get("issues", []):
        sev = issue.get("severity", "").lower()
        findings.append({
            "tool": "psalm",
            "title": issue.get("message"),
            "file": issue.get("file_name"),
            "line": issue.get("line_from"),
            "severity": SEV_MAP.get(sev, "medium"),
            "code": issue.get("snippet", "").strip(),
            "metadata": {"type": issue.get("type"), "link": issue.get("link")}
        })
    return findings

def normalize_parse(data):
    findings = []
    for issue in data.get("findings", []):
        sev = issue.get("severity", "warning").lower()
        findings.append({
            "tool": "parse",
            "title": issue.get("title") or issue.get("message"),
            "file": issue.get("file"),
            "line": issue.get("line"),
            "severity": SEV_MAP.get(sev, "medium"),
            "code": issue.get("code", ""),
            "metadata": {"rule": issue.get("rule")}
        })
    return findings

def normalize_progpilot(data):
    findings = []
    for issue in data.get("results", []):
        sev = issue.get("severity", "medium").lower()
        findings.append({
            "tool": "progpilot",
            "title": issue.get("description") or issue.get("message"),
            "file": issue.get("file"),
            "line": issue.get("line"),
            "severity": SEV_MAP.get(sev, "medium"),
            "code": issue.get("code", ""),
            "metadata": {"rule": issue.get("rule_name")}
        })
    return findings

def main():
    p = argparse.ArgumentParser(
        description="AegisPHP: Run PHP SAST (Psalm, parse, ProgPilot) in Docker and aggregate results."
    )
    p.add_argument("target", help="Path to PHP project directory")
    p.add_argument("-o", "--output", help="Path for combined JSON report")
    args = p.parse_args()

    target_dir = os.path.abspath(args.target)
    if not os.path.isdir(target_dir):
        print(f"ERROR: '{target_dir}' is not a directory.", file=sys.stderr)
        sys.exit(1)

    # Determine Dockerfile location (script’s directory)
    docker_dir = os.path.dirname(os.path.abspath(__file__))

    # 1) Ensure the Docker image is built
    ensure_image(docker_dir)

    # 2) Run each tool in its container
    print("[+] Running Psalm…")
    psalm_cmd = [
        "docker","run","--rm",
        "-v", f"{target_dir}:/app:ro",
        IMAGE_NAME,
        "psalm","--output-format=json"
    ]
    psalm_out = run_tool(psalm_cmd)
    psalm_json = json.loads(psalm_out or "{}")

    print("[+] Running parse…")
    parse_cmd = [
        "docker","run","--rm",
        "-v", f"{target_dir}:/app:ro",
        IMAGE_NAME,
        "parse","scan","/app","--format","json"
    ]
    parse_out = run_tool(parse_cmd)
    parse_json = json.loads(parse_out or "{}")

    print("[+] Running ProgPilot…")
    prog_cmd = [
        "docker","run","--rm",
        "-v", f"{target_dir}:/workspace:ro",
        IMAGE_NAME,
        "php","/opt/progpilot/src/ProgPilot.php",
        "--level","high","--target","/workspace","--output=json"
    ]
    prog_out = run_tool(prog_cmd)
    prog_json = json.loads(prog_out or "{}")

    # 3) Normalize
    all_findings = []
    all_findings += normalize_psalm(psalm_json)
    all_findings += normalize_parse(parse_json)
    all_findings += normalize_progpilot(prog_json)

    # 4) Build summary
    summary = {"total_findings": len(all_findings), "by_tool": {}}
    for f in all_findings:
        summary["by_tool"].setdefault(f["tool"], 0)
        summary["by_tool"][f["tool"]] += 1

    report = {"summary": summary, "findings": all_findings}

    # 5) Output path logic
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    default_name = f"AegisPHP_output-{timestamp}.json"
    out_path = args.output or os.path.join(os.getcwd(), default_name)

    with open(out_path, "w") as fd:
        json.dump(report, fd, indent=2)

    # 6) Echo to stdout
    print(json.dumps(report, indent=2))

    print(f"\n[+] Combined report written to {out_path}")

if __name__ == "__main__":
    main()