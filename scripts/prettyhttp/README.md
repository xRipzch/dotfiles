# prettyhttp

Prettify raw HTTP responses from curl.

## Usage

```bash
curl -si https://example.com | prettyhttp
```

## Install

```bash
chmod +x prettyhttp && sudo mv prettyhttp /usr/local/bin/
```

## What it does

- Status line colored green/yellow/red by code
- Headers highlighted
- JSON body auto pretty-printed
- Handles redirects (multiple HTTP blocks)

## Requirements

Python 3.10+
