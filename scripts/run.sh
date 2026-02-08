#!/usr/bin/env bash
set -euo pipefail

# curl-to-code: convert curl commands to HTTP client code

TARGET="fetch"
CURL_CMD=""

usage() {
  cat <<'EOF'
Usage: curl-to-code [OPTIONS] [CURL_COMMAND]

Convert a curl command to HTTP client code.

Options:
  --fetch       Generate JavaScript fetch code (default)
  --axios       Generate JavaScript axios code
  --requests    Generate Python requests code
  --go          Generate Go net/http code
  --ruby        Generate Ruby net/http code
  --help        Show this help message

Input:
  Pass the curl command as an argument (in quotes) or via stdin.

Examples:
  curl-to-code --fetch 'curl -X POST https://api.example.com/data -H "Content-Type: application/json" -d "{\"key\":\"value\"}"'
  echo 'curl https://api.example.com/data' | curl-to-code --requests
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fetch)    TARGET="fetch"; shift ;;
    --axios)    TARGET="axios"; shift ;;
    --requests) TARGET="requests"; shift ;;
    --go)       TARGET="go"; shift ;;
    --ruby)     TARGET="ruby"; shift ;;
    --help)     usage; exit 0 ;;
    -*)         echo "Error: unknown option '$1'" >&2; exit 1 ;;
    *)          CURL_CMD="$1"; shift ;;
  esac
done

# Read from stdin if no argument
if [ -z "$CURL_CMD" ]; then
  if [ -t 0 ]; then
    echo "Error: no curl command provided" >&2
    usage >&2
    exit 1
  fi
  CURL_CMD=$(cat)
fi

# Strip leading "curl " if present
CURL_CMD="${CURL_CMD#curl }"

# Write curl command to temp file and invoke Python
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT
printf '%s' "$CURL_CMD" > "$TMPFILE"

python3 - "$TMPFILE" "$TARGET" << 'PYEOF'
import shlex
import sys
import json

cmd_file = sys.argv[1]
target = sys.argv[2]

with open(cmd_file) as f:
    cmd = f.read()

try:
    tokens = shlex.split(cmd)
except ValueError as e:
    print(f"Error: failed to parse curl command: {e}", file=sys.stderr)
    sys.exit(1)

url = ""
method = "GET"
headers = {}
data = ""
auth_user = ""
auth_pass = ""
cookies = ""
follow_redirects = False
insecure = False

i = 0
while i < len(tokens):
    tok = tokens[i]
    if tok in ("-X", "--request"):
        i += 1; method = tokens[i].upper()
    elif tok in ("-H", "--header"):
        i += 1
        h = tokens[i]
        key, _, val = h.partition(":")
        headers[key.strip()] = val.strip()
    elif tok in ("-d", "--data", "--data-raw", "--data-binary"):
        i += 1; data = tokens[i]
        if method == "GET":
            method = "POST"
    elif tok in ("-u", "--user"):
        i += 1
        parts = tokens[i].split(":", 1)
        auth_user = parts[0]
        auth_pass = parts[1] if len(parts) > 1 else ""
    elif tok in ("-b", "--cookie"):
        i += 1; cookies = tokens[i]
    elif tok in ("-L", "--location"):
        follow_redirects = True
    elif tok in ("-k", "--insecure"):
        insecure = True
    elif tok.startswith("http://") or tok.startswith("https://"):
        url = tok
    elif not tok.startswith("-"):
        url = tok
    i += 1

if not url:
    print("Error: no URL found in curl command", file=sys.stderr)
    sys.exit(1)

if target == "fetch":
    print(f"const response = await fetch('{url}', {{")
    print(f"  method: '{method}',")
    if headers:
        print("  headers: {")
        for k, v in headers.items():
            print(f"    '{k}': '{v}',")
        print("  },")
    if data:
        try:
            json.loads(data)
            print(f"  body: JSON.stringify({data}),")
        except (json.JSONDecodeError, TypeError):
            print(f"  body: '{data}',")
    if follow_redirects:
        print("  redirect: 'follow',")
    print("});")
    print("")
    print("const data = await response.json();")

elif target == "axios":
    print("const response = await axios({")
    print(f"  method: '{method.lower()}',")
    print(f"  url: '{url}',")
    if headers:
        print("  headers: {")
        for k, v in headers.items():
            print(f"    '{k}': '{v}',")
        print("  },")
    if data:
        try:
            json.loads(data)
            print(f"  data: {data},")
        except (json.JSONDecodeError, TypeError):
            print(f"  data: '{data}',")
    if auth_user:
        print("  auth: {")
        print(f"    username: '{auth_user}',")
        print(f"    password: '{auth_pass}',")
        print("  },")
    if not follow_redirects:
        print("  maxRedirects: 0,")
    print("});")

elif target == "requests":
    print("import requests")
    print("")
    args = [f"'{url}'"]
    if headers:
        h_items = ", ".join([f"'{k}': '{v}'" for k, v in headers.items()])
        print(f"headers = {{{h_items}}}")
        args.append("headers=headers")
    if data:
        try:
            json.loads(data)
            args.append(f"json={data}")
        except (json.JSONDecodeError, TypeError):
            args.append(f"data='{data}'")
    if auth_user:
        args.append(f"auth=('{auth_user}', '{auth_pass}')")
    if not follow_redirects and method != "GET":
        args.append("allow_redirects=False")
    if insecure:
        args.append("verify=False")
    if cookies:
        args.append(f"cookies={{'cookie': '{cookies}'}}")
    print(f"response = requests.{method.lower()}({', '.join(args)})")
    print("print(response.json())")

elif target == "go":
    print("package main")
    print("")
    print("import (")
    print('\t"fmt"')
    print('\t"io"')
    print('\t"net/http"')
    if data:
        print('\t"strings"')
    print(")")
    print("")
    print("func main() {")
    if data:
        print(f'\tbody := strings.NewReader(`{data}`)')
        print(f'\treq, err := http.NewRequest("{method}", "{url}", body)')
    else:
        print(f'\treq, err := http.NewRequest("{method}", "{url}", nil)')
    print("\tif err != nil {")
    print("\t\tpanic(err)")
    print("\t}")
    for k, v in headers.items():
        print(f'\treq.Header.Set("{k}", "{v}")')
    if auth_user:
        print(f'\treq.SetBasicAuth("{auth_user}", "{auth_pass}")')
    print("")
    print("\tclient := &http.Client{}")
    print("\tresp, err := client.Do(req)")
    print("\tif err != nil {")
    print("\t\tpanic(err)")
    print("\t}")
    print("\tdefer resp.Body.Close()")
    print("")
    print("\tdata, _ := io.ReadAll(resp.Body)")
    print("\tfmt.Println(string(data))")
    print("}")

elif target == "ruby":
    print("require 'net/http'")
    print("require 'uri'")
    print("require 'json'")
    print("")
    print(f"uri = URI.parse('{url}')")
    method_cap = method.capitalize()
    print(f"request = Net::HTTP::{method_cap}.new(uri)")
    for k, v in headers.items():
        print(f"request['{k}'] = '{v}'")
    if data:
        print(f"request.body = '{data}'")
    if auth_user:
        print(f"request.basic_auth('{auth_user}', '{auth_pass}')")
    print("")
    print("response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|")
    print("  http.request(request)")
    print("end")
    print("")
    print("puts response.body")

PYEOF
