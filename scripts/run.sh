#!/usr/bin/env bash
set -euo pipefail

# run.sh — Convert curl commands to code
# Usage: ./run.sh -q "curl ..." --lang fetch|axios|python|go

LANG="fetch"
CURL_CMD=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -q) CURL_CMD="$2"; shift 2 ;;
    --lang) LANG="$2"; shift 2 ;;
    --help)
      echo "Usage: run.sh [OPTIONS]"
      echo ""
      echo "Convert curl commands to code."
      echo ""
      echo "Options:"
      echo "  -q COMMAND     The curl command to convert"
      echo "  --lang LANG    Target: fetch, axios, python, go (default: fetch)"
      echo "  --help         Show this help"
      exit 0
      ;;
    -*) echo "Error: unknown option: $1" >&2; exit 2 ;;
    *) echo "Error: unexpected argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$CURL_CMD" ]]; then
  if [[ -t 0 ]]; then
    echo "Error: no curl command provided. Use -q or pipe via stdin." >&2
    exit 2
  fi
  CURL_CMD=$(cat)
fi

if [[ -z "$CURL_CMD" ]]; then
  echo "Error: empty curl command" >&2
  exit 2
fi

# Parse the curl command
# Extract: URL, method, headers, data/body
parse_result=$(echo "$CURL_CMD" | awk '
BEGIN {
  url = ""
  method = "GET"
  num_headers = 0
  body = ""
  content_type = ""
}

{
  line = $0
  # Remove "curl " prefix
  gsub(/^[[:space:]]*curl[[:space:]]+/, "", line)
  # Remove backslash continuations
  gsub(/\\[[:space:]]*$/, "", line)

  n = split(line, tokens, " ")
  i = 1
  while (i <= n) {
    tok = tokens[i]

    # Remove quotes from token
    gsub(/^'\''/, "", tok)
    gsub(/'\''$/, "", tok)
    gsub(/^"/, "", tok)
    gsub(/"$/, "", tok)

    if (tok == "-X" || tok == "--request") {
      i++
      method = tokens[i]
      gsub(/^'\''|'\''$|^"|"$/, "", method)
    } else if (tok == "-H" || tok == "--header") {
      i++
      header = tokens[i]
      # Rejoin if header value has spaces
      while (i < n) {
        next_tok = tokens[i+1]
        if (next_tok ~ /^-/ || next_tok ~ /^http/ || next_tok ~ /^'\''/) break
        if (substr(header, 1, 1) == "'\''") {
          if (header ~ /'\''$/) break
        } else if (substr(header, 1, 1) == "\"") {
          if (header ~ /"$/) break
        } else {
          break
        }
        i++
        header = header " " tokens[i]
      }
      gsub(/^'\''|'\''$|^"|"$/, "", header)
      num_headers++
      headers[num_headers] = header
      if (tolower(header) ~ /^content-type:/) {
        content_type = header
        gsub(/^[Cc]ontent-[Tt]ype:[[:space:]]*/, "", content_type)
      }
    } else if (tok == "-d" || tok == "--data" || tok == "--data-raw" || tok == "--data-binary") {
      i++
      body = tokens[i]
      # Rejoin body if it has spaces
      while (i < n) {
        next_tok = tokens[i+1]
        if (substr(body, 1, 1) == "'\''") {
          if (body ~ /'\''$/) break
        } else if (substr(body, 1, 1) == "\"") {
          if (body ~ /"$/) break
        } else {
          break
        }
        i++
        body = body " " tokens[i]
      }
      gsub(/^'\''|'\''$|^"|"$/, "", body)
      if (method == "GET") method = "POST"
    } else if (tok ~ /^https?:/ || tok ~ /^'\''https?:/) {
      url = tok
      gsub(/^'\''|'\''$|^"|"$/, "", url)
    }

    i++
  }
}

END {
  print "URL=" url
  print "METHOD=" method
  print "BODY=" body
  print "CONTENT_TYPE=" content_type
  print "NUM_HEADERS=" num_headers
  for (i = 1; i <= num_headers; i++) {
    print "HEADER_" i "=" headers[i]
  }
}
')

# Extract parsed values
URL=$(echo "$parse_result" | grep "^URL=" | sed 's/^URL=//')
METHOD=$(echo "$parse_result" | grep "^METHOD=" | sed 's/^METHOD=//')
BODY=$(echo "$parse_result" | grep "^BODY=" | sed 's/^BODY=//')
CONTENT_TYPE=$(echo "$parse_result" | grep "^CONTENT_TYPE=" | sed 's/^CONTENT_TYPE=//')
NUM_HEADERS=$(echo "$parse_result" | grep "^NUM_HEADERS=" | sed 's/^NUM_HEADERS=//')

# Collect headers
declare -a HEADERS
for ((i = 1; i <= NUM_HEADERS; i++)); do
  h=$(echo "$parse_result" | grep "^HEADER_${i}=" | sed "s/^HEADER_${i}=//")
  HEADERS+=("$h")
done

if [[ -z "$URL" ]]; then
  echo "Error: could not parse URL from curl command" >&2
  exit 1
fi

# Generate code based on language
case "$LANG" in
  fetch)
    echo "const response = await fetch('${URL}', {"
    echo "  method: '${METHOD}',"
    if [[ $NUM_HEADERS -gt 0 ]]; then
      echo "  headers: {"
      for ((i = 0; i < ${#HEADERS[@]}; i++)); do
        h="${HEADERS[$i]}"
        key="${h%%:*}"
        val="${h#*: }"
        comma=","
        [[ $i -eq $((${#HEADERS[@]} - 1)) ]] && comma=""
        echo "    '${key}': '${val}'${comma}"
      done
      echo "  },"
    fi
    if [[ -n "$BODY" ]]; then
      echo "  body: '${BODY}',"
    fi
    echo "});"
    echo ""
    echo "const data = await response.json();"
    ;;

  axios)
    echo "const { data } = await axios({"
    echo "  method: '$(echo "$METHOD" | tr '[:upper:]' '[:lower:]')',"
    echo "  url: '${URL}',"
    if [[ $NUM_HEADERS -gt 0 ]]; then
      echo "  headers: {"
      for ((i = 0; i < ${#HEADERS[@]}; i++)); do
        h="${HEADERS[$i]}"
        key="${h%%:*}"
        val="${h#*: }"
        comma=","
        [[ $i -eq $((${#HEADERS[@]} - 1)) ]] && comma=""
        echo "    '${key}': '${val}'${comma}"
      done
      echo "  },"
    fi
    if [[ -n "$BODY" ]]; then
      echo "  data: '${BODY}',"
    fi
    echo "});"
    ;;

  python)
    echo "import requests"
    echo ""
    if [[ $NUM_HEADERS -gt 0 ]]; then
      echo "headers = {"
      for ((i = 0; i < ${#HEADERS[@]}; i++)); do
        h="${HEADERS[$i]}"
        key="${h%%:*}"
        val="${h#*: }"
        comma=","
        [[ $i -eq $((${#HEADERS[@]} - 1)) ]] && comma=""
        echo "    '${key}': '${val}'${comma}"
      done
      echo "}"
      echo ""
    fi
    method_lower=$(echo "$METHOD" | tr '[:upper:]' '[:lower:]')
    echo -n "response = requests.${method_lower}('${URL}'"
    if [[ $NUM_HEADERS -gt 0 ]]; then
      echo -n ", headers=headers"
    fi
    if [[ -n "$BODY" ]]; then
      echo -n ", data='${BODY}'"
    fi
    echo ")"
    echo "data = response.json()"
    ;;

  go)
    echo "package main"
    echo ""
    echo "import ("
    echo '    "fmt"'
    echo '    "io"'
    echo '    "net/http"'
    if [[ -n "$BODY" ]]; then
      echo '    "strings"'
    fi
    echo ")"
    echo ""
    echo "func main() {"
    if [[ -n "$BODY" ]]; then
      echo "    body := strings.NewReader(\`${BODY}\`)"
      echo "    req, err := http.NewRequest(\"${METHOD}\", \"${URL}\", body)"
    else
      echo "    req, err := http.NewRequest(\"${METHOD}\", \"${URL}\", nil)"
    fi
    echo "    if err != nil {"
    echo "        panic(err)"
    echo "    }"
    for ((i = 0; i < ${#HEADERS[@]}; i++)); do
      h="${HEADERS[$i]}"
      key="${h%%:*}"
      val="${h#*: }"
      echo "    req.Header.Set(\"${key}\", \"${val}\")"
    done
    echo ""
    echo "    client := &http.Client{}"
    echo "    resp, err := client.Do(req)"
    echo "    if err != nil {"
    echo "        panic(err)"
    echo "    }"
    echo "    defer resp.Body.Close()"
    echo ""
    echo "    respBody, _ := io.ReadAll(resp.Body)"
    echo "    fmt.Println(string(respBody))"
    echo "}"
    ;;

  *)
    echo "Error: unknown language: $LANG" >&2
    echo "Supported: fetch, axios, python, go" >&2
    exit 2
    ;;
esac
