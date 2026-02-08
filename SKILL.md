---
name: curl-to-code
description: Converts curl commands to equivalent code in fetch, axios, requests, or other HTTP libraries
version: 0.1.0
license: Apache-2.0
---

# curl-to-code

Converts curl commands into equivalent HTTP client code in your language of choice. Paste a curl command from browser DevTools and get clean, working code back.

## Purpose

Developers frequently copy curl commands from browser DevTools, API docs, or colleagues. Manually rewriting them into fetch, axios, or Python requests is tedious and error-prone. This tool automates the conversion.

## Instructions

When a user provides a curl command and wants it converted to code:

1. Run `./scripts/run.sh` with the curl command as input and the target language/library as a flag
2. Supported targets: `--fetch`, `--axios`, `--requests`, `--go`, `--ruby`
3. The tool parses curl flags (`-X`, `-H`, `-d`, `--data`, `-u`, etc.) and generates equivalent code
4. Output goes to stdout

## Inputs

- A curl command via stdin or as a quoted argument
- A target language flag (default: `--fetch`)

## Outputs

- Generated code to stdout, ready to copy-paste

## Constraints

- Supports common curl flags: `-X`, `-H`, `-d`, `--data`, `--data-raw`, `-u`, `--user`, `-b`, `--cookie`, `-L`, `-k`, `-o`
- Does not execute the curl command
- Does not handle curl flags for file uploads (`-F`) in this version
