---
name: curl-to-code
description: Converts curl commands copied from browser devtools into equivalent Python requests, JavaScript fetch, or Node.js axios code.
version: 0.1.0
license: Apache-2.0
tags:
  - curl
  - codegen
  - python
  - javascript
  - node
---

# curl-to-code

Converts curl commands into equivalent code in Python (`requests`), JavaScript (`fetch`), or Node.js (`axios`).

## Usage

```bash
# Default: Python requests output
echo "curl -X POST https://api.example.com/data -H 'Content-Type: application/json' -d '{\"key\":\"value\"}'" | ./scripts/run.sh

# Specify language
echo "curl https://api.example.com/users" | ./scripts/run.sh --lang=javascript
echo "curl https://api.example.com/users" | ./scripts/run.sh --lang=node

# Pass curl command as argument
./scripts/run.sh --lang=python "curl -X GET https://api.example.com/users -H 'Authorization: Bearer token123'"
```

## Supported curl flags

| Flag | Description |
|------|-------------|
| `-X`, `--request` | HTTP method (GET, POST, PUT, DELETE, etc.) |
| `-H`, `--header` | Request header (repeatable) |
| `-d`, `--data`, `--data-raw` | Request body data |
| `-u`, `--user` | Basic auth credentials (`user:pass`) |
| `--compressed` | Noted but not affecting output |
| URL | Positional argument (with or without `curl` prefix) |

## Output languages

- **python** (default) — uses the `requests` library
- **javascript** — uses the browser `fetch` API
- **node** — uses the `axios` library
