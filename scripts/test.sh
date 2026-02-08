#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN="$SCRIPT_DIR/run.sh"

PASS=0
FAIL=0
TOTAL=0

assert_contains() {
    local test_name="$1"
    local output="$2"
    local needle="$3"
    TOTAL=$((TOTAL + 1))
    if echo "$output" | grep -qF -- "$needle"; then
        echo "  PASS: $test_name"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $test_name"
        echo "    expected to contain: $needle"
        echo "    got: $output"
        FAIL=$((FAIL + 1))
    fi
}

assert_exit_code() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    TOTAL=$((TOTAL + 1))
    if [ "$actual" -eq "$expected" ]; then
        echo "  PASS: $test_name"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $test_name (expected exit $expected, got $actual)"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== curl-to-code test suite ==="
echo ""

# ---- Test 1: Simple GET (Python) ----
echo "Test 1: Simple GET -> Python"
OUTPUT=$(echo "curl https://api.example.com/users" | "$RUN")
assert_contains "has requests import" "$OUTPUT" "import requests"
assert_contains "has URL" "$OUTPUT" "https://api.example.com/users"
assert_contains "has requests.get" "$OUTPUT" "requests.get("

# ---- Test 2: POST with JSON body and headers (Python) ----
echo "Test 2: POST with JSON body and headers -> Python"
OUTPUT=$(echo 'curl -X POST https://api.example.com/data -H "Content-Type: application/json" -d "{\"key\":\"value\"}"' | "$RUN")
assert_contains "has requests.post" "$OUTPUT" "requests.post("
assert_contains "has Content-Type header" "$OUTPUT" "Content-Type"
assert_contains "has data" "$OUTPUT" "data="

# ---- Test 3: Custom headers (JavaScript) ----
echo "Test 3: Custom headers -> JavaScript"
OUTPUT=$(echo 'curl https://api.example.com/me -H "Authorization: Bearer tok123" -H "Accept: application/json"' | "$RUN" --lang=javascript)
assert_contains "has fetch call" "$OUTPUT" "fetch("
assert_contains "has Authorization header" "$OUTPUT" "Authorization"
assert_contains "has Bearer token" "$OUTPUT" "Bearer tok123"
assert_contains "has Accept header" "$OUTPUT" "Accept"

# ---- Test 4: Basic auth (Python) ----
echo "Test 4: Basic auth -> Python"
OUTPUT=$(echo 'curl -u admin:secret https://api.example.com/admin' | "$RUN" --lang=python)
assert_contains "has auth tuple" "$OUTPUT" "auth="
assert_contains "has admin user" "$OUTPUT" "admin"
assert_contains "has secret pass" "$OUTPUT" "secret"

# ---- Test 5: Multiple headers (Node) ----
echo "Test 5: Multiple headers -> Node"
OUTPUT=$(echo 'curl https://api.example.com/items -H "X-Api-Key: abc123" -H "X-Request-Id: req-456"' | "$RUN" --lang=node)
assert_contains "has axios require" "$OUTPUT" 'require("axios")'
assert_contains "has X-Api-Key" "$OUTPUT" "X-Api-Key"
assert_contains "has X-Request-Id" "$OUTPUT" "X-Request-Id"

# ---- Test 6: PUT method (Python) ----
echo "Test 6: PUT method -> Python"
OUTPUT=$(echo 'curl -X PUT https://api.example.com/items/1 -d "{\"name\":\"updated\"}"' | "$RUN")
assert_contains "has requests.put" "$OUTPUT" "requests.put("

# ---- Test 7: DELETE method (JavaScript) ----
echo "Test 7: DELETE method -> JavaScript"
OUTPUT=$(echo 'curl -X DELETE https://api.example.com/items/1' | "$RUN" --lang=javascript)
assert_contains "has method DELETE" "$OUTPUT" '"DELETE"'

# ---- Test 8: Unknown language flag ----
echo "Test 8: Unknown language flag"
set +e
OUTPUT=$(echo "curl https://example.com" | "$RUN" --lang=ruby 2>&1)
EXIT_CODE=$?
set -e
assert_exit_code "exits with error" 1 "$EXIT_CODE"
assert_contains "has error message" "$OUTPUT" "unknown language"

# ---- Test 9: Empty input ----
echo "Test 9: Empty input"
set +e
OUTPUT=$(echo "" | "$RUN" 2>&1)
EXIT_CODE=$?
set -e
assert_exit_code "exits with error" 1 "$EXIT_CODE"
assert_contains "has error message" "$OUTPUT" "Error"

# ---- Test 10: --data-raw flag (Python) ----
echo "Test 10: --data-raw flag -> Python"
OUTPUT=$(echo 'curl -X POST https://api.example.com/submit --data-raw "field=value&other=123"' | "$RUN")
assert_contains "has requests.post" "$OUTPUT" "requests.post("
assert_contains "has data" "$OUTPUT" "field=value"

# ---- Test 11: Basic auth (Node) ----
echo "Test 11: Basic auth -> Node"
OUTPUT=$(echo 'curl -u myuser:mypass https://api.example.com/secure' | "$RUN" --lang=node)
assert_contains "has auth block" "$OUTPUT" "auth:"
assert_contains "has username" "$OUTPUT" "myuser"
assert_contains "has password" "$OUTPUT" "mypass"

# ---- Test 12: Basic auth (JavaScript) ----
echo "Test 12: Basic auth -> JavaScript"
OUTPUT=$(echo 'curl -u bob:hunter2 https://api.example.com/login' | "$RUN" --lang=javascript)
assert_contains "has btoa reference" "$OUTPUT" "btoa"
assert_contains "has user:pass" "$OUTPUT" "bob:hunter2"

# ---- Test 13: Argument-based input (no stdin) ----
echo "Test 13: Argument-based input"
OUTPUT=$("$RUN" "curl -X GET https://api.example.com/health")
assert_contains "has requests.get" "$OUTPUT" "requests.get("
assert_contains "has URL" "$OUTPUT" "https://api.example.com/health"

# ---- Test 14: POST with --data-raw JSON (JavaScript) ----
echo "Test 14: POST with --data-raw JSON -> JavaScript"
OUTPUT=$(echo 'curl -X POST https://api.example.com/webhook -H "Content-Type: application/json" --data-raw "{\"event\":\"push\"}"' | "$RUN" --lang=javascript)
assert_contains "has fetch call" "$OUTPUT" "fetch("
assert_contains "has POST method" "$OUTPUT" '"POST"'
assert_contains "has body" "$OUTPUT" "body:"

echo ""
echo "=== Results: $PASS passed, $FAIL failed, $TOTAL total ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi

echo "All tests passed!"
