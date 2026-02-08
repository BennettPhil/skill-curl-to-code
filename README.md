# curl-to-code

Converts curl commands to equivalent HTTP client code in JavaScript (fetch/axios), Python (requests), Go, or Ruby.

## Quick Start

```bash
./scripts/run.sh 'curl -X POST https://api.example.com/data -H "Content-Type: application/json" -d "{\"key\":\"value\"}"'
```

## Targets

```bash
./scripts/run.sh --fetch 'curl ...'      # JavaScript fetch (default)
./scripts/run.sh --axios 'curl ...'      # JavaScript axios
./scripts/run.sh --requests 'curl ...'   # Python requests
./scripts/run.sh --go 'curl ...'         # Go net/http
./scripts/run.sh --ruby 'curl ...'       # Ruby net/http
```

## Pipe from stdin

```bash
pbpaste | ./scripts/run.sh --requests
```

## Prerequisites

- Python 3 (for curl command parsing)
- No other dependencies
