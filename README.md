# curl-to-code

Convert curl commands to equivalent code in JavaScript (fetch/axios), Python (requests), and Go (net/http).

## Quick Start

```bash
./scripts/run.sh -q "curl -X GET https://api.example.com/users -H 'Authorization: Bearer token123'"
```

## Prerequisites

- Bash 4+
- awk (standard Unix)

## Usage

```bash
# Convert to fetch (default)
./scripts/run.sh -q "curl https://api.example.com/users"

# Convert to Python requests
./scripts/run.sh -q "curl https://api.example.com/users" --lang python

# Convert to axios
./scripts/run.sh -q "curl -X POST https://api.example.com/data -d '{\"key\":\"value\"}'" --lang axios

# Convert to Go
./scripts/run.sh -q "curl https://api.example.com" --lang go
```
