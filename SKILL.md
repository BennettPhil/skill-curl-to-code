---
name: curl-to-code
description: Convert curl commands to equivalent code in JavaScript (fetch/axios), Python (requests), and Go (net/http).
version: 0.1.0
license: Apache-2.0
---

# curl-to-code

Converts curl commands (like those copied from browser DevTools) into equivalent code in your target language.

## Purpose

Every developer copies curl commands from browser DevTools but needs the code in their actual language. This skill parses a curl command and generates clean, idiomatic code for JavaScript (fetch or axios), Python (requests), and Go (net/http).

## See It in Action

See [examples/basic-example.md](examples/basic-example.md) for the simplest usage.

## Examples Index

- `examples/basic-example.md` — Simple GET request conversion
- `examples/common-patterns.md` — POST with JSON, auth headers, custom headers
- `examples/advanced-usage.md` — Multi-header, form data, cookies

## Reference

| Flag | Default | Description |
|------|---------|-------------|
| -q CURL_CMD | - | The curl command to convert (required if not piped) |
| --lang LANG | fetch | Target language: fetch, axios, python, go |
| --help | - | Show usage |

## Installation

No dependencies. Pure bash + awk implementation.
