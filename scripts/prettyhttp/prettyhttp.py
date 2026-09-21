#!/usr/bin/env python
"""
prettyhttp - prettify raw HTTP responses piped from curl

Usage:
    curl -si https://example.com | prettyhttp
    curl -si https://api.github.com/users/torvalds | prettyhttp
    curl -siX POST https://httpbin.org/post -d '{"key":"val"}' | prettyhttp
"""

import sys
import json


RESET  = "\033[0m"
BOLD   = "\033[1m"
GREEN  = "\033[32m"
YELLOW = "\033[33m"
CYAN   = "\033[36m"
RED    = "\033[31m"
DIM    = "\033[2m"


def status_color(code: int) -> str:
    if code < 300: return GREEN
    if code < 400: return YELLOW
    return RED


def print_status(line: str):
    parts = line.split(" ", 2)
    if len(parts) < 2:
        print(line)
        return
    proto, code_str, *rest = parts
    try:
        code = int(code_str)
    except ValueError:
        print(line)
        return
    color = status_color(code)
    reason = rest[0] if rest else ""
    print(f"{DIM}{proto}{RESET} {color}{BOLD}{code} {reason}{RESET}")


def print_headers(headers: list[str]):
    for header in headers:
        if ":" not in header:
            continue
        key, _, val = header.partition(":")
        print(f"  {CYAN}{key}{RESET}:{val}")


def print_body(body: str):
    body = body.strip()
    if not body:
        return
    print()
    try:
        parsed = json.loads(body)
        print(json.dumps(parsed, indent=2, ensure_ascii=False))
    except json.JSONDecodeError:
        print(body)


def parse(raw: str):
    blocks = []
    current = []
    for line in raw.splitlines():
        if line.startswith("HTTP/") and current:
            blocks.append(current)
            current = []
        current.append(line)
    if current:
        blocks.append(current)

    for i, block in enumerate(blocks):
        if not block:
            continue
        try:
            blank = block.index("")
            header_lines = block[:blank]
            body_lines   = block[blank + 1:]
        except ValueError:
            header_lines = block
            body_lines   = []

        if i > 0:
            print(f"\n{DIM}── redirect ──────────────────────{RESET}")

        print_status(header_lines[0])
        print_headers(header_lines[1:])
        print_body("\n".join(body_lines))


def main():
    if sys.stdin.isatty():
        print("Usage: curl -si <url> | prettyhttp")
        sys.exit(0)
    raw = sys.stdin.read()
    parse(raw)


if __name__ == "__main__":
    main()
