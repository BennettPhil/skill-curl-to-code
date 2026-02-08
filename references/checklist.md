# curl-to-code Validation Checklist

## Parsing
- [ ] Handles `curl` prefix (strips it if present)
- [ ] Handles URL as positional argument
- [ ] Parses `-X` / `--request` for HTTP method
- [ ] Parses `-H` / `--header` (multiple allowed)
- [ ] Parses `-d` / `--data` / `--data-raw` for request body
- [ ] Parses `-u` / `--user` for basic auth
- [ ] Ignores `--compressed` without error
- [ ] Defaults to GET when no data, POST when data present
- [ ] Uses `shlex.split()` for proper shell quoting

## Code Generation - Python
- [ ] Uses `requests` library
- [ ] Correct method call (`requests.get`, `requests.post`, etc.)
- [ ] Passes headers dict
- [ ] Passes data parameter
- [ ] Passes auth tuple for basic auth

## Code Generation - JavaScript
- [ ] Uses `fetch` API
- [ ] Sets method in options
- [ ] Sets headers object
- [ ] Sets body for POST/PUT
- [ ] Comments about btoa for basic auth

## Code Generation - Node.js
- [ ] Uses `axios` with `require`
- [ ] Sets method, url, headers
- [ ] Sets data for request body
- [ ] Sets auth object for basic auth

## Error Handling
- [ ] Rejects empty input with non-zero exit
- [ ] Rejects unknown language with non-zero exit
- [ ] Reports missing URL

## Interface
- [ ] Reads from stdin
- [ ] Accepts curl command as positional argument
- [ ] Supports `--lang=python|javascript|node` flag
- [ ] Defaults to Python
- [ ] `run.sh` wrapper delegates to `convert.py`
