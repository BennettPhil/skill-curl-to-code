#!/usr/bin/env python3
"""Converts a curl command string into equivalent Python, JavaScript, or Node.js code."""

import sys
import shlex
import json


def parse_curl(command_str):
    """Parse a curl command string into structured components."""
    command_str = command_str.strip()
    if not command_str:
        print("Error: empty input", file=sys.stderr)
        sys.exit(1)

    try:
        tokens = shlex.split(command_str)
    except ValueError as e:
        print(f"Error: failed to parse curl command: {e}", file=sys.stderr)
        sys.exit(1)

    # Strip leading 'curl' if present
    if tokens and tokens[0] == 'curl':
        tokens = tokens[1:]

    if not tokens:
        print("Error: empty input", file=sys.stderr)
        sys.exit(1)

    method = None
    url = None
    headers = {}
    data = None
    auth = None

    i = 0
    while i < len(tokens):
        tok = tokens[i]
        if tok in ('-X', '--request'):
            i += 1
            method = tokens[i]
        elif tok in ('-H', '--header'):
            i += 1
            hval = tokens[i]
            if ':' in hval:
                key, val = hval.split(':', 1)
                headers[key.strip()] = val.strip()
        elif tok in ('-d', '--data', '--data-raw'):
            i += 1
            data = tokens[i]
        elif tok in ('-u', '--user'):
            i += 1
            auth = tokens[i]
        elif tok == '--compressed':
            pass  # ignore
        elif not tok.startswith('-'):
            url = tok
        i += 1

    if url is None:
        print("Error: no URL found in curl command", file=sys.stderr)
        sys.exit(1)

    if method is None:
        method = 'POST' if data else 'GET'

    return {
        'method': method,
        'url': url,
        'headers': headers,
        'data': data,
        'auth': auth,
    }


def to_python(parsed):
    """Generate Python requests code."""
    lines = ['import requests', '']

    # Build args
    args = [f'    "{parsed["url"]}"']

    if parsed['headers']:
        hdr_str = json.dumps(parsed['headers'], indent=8)
        args.append(f'    headers={hdr_str}')

    if parsed['data']:
        args.append(f'    data={repr(parsed["data"])}')

    if parsed['auth']:
        parts = parsed['auth'].split(':', 1)
        if len(parts) == 2:
            args.append(f'    auth=({repr(parts[0])}, {repr(parts[1])})')
        else:
            args.append(f'    auth=({repr(parts[0])}, "")')

    method = parsed['method'].lower()
    args_str = ',\n'.join(args)
    lines.append(f'response = requests.{method}(')
    lines.append(args_str)
    lines.append(')')
    lines.append('')
    lines.append('print(response.status_code)')
    lines.append('print(response.text)')
    return '\n'.join(lines)


def to_javascript(parsed):
    """Generate JavaScript fetch code."""
    lines = []

    options = {}
    options['method'] = parsed['method']

    if parsed['headers']:
        options['headers'] = parsed['headers']

    if parsed['data']:
        options['body'] = parsed['data']

    # Build fetch call
    lines.append(f'fetch("{parsed["url"]}", {{')

    lines.append(f'  method: "{parsed["method"]}",')

    if parsed['headers']:
        lines.append('  headers: {')
        for k, v in parsed['headers'].items():
            lines.append(f'    "{k}": "{v}",')
        lines.append('  },')

    if parsed['data']:
        # Try to detect JSON
        try:
            json.loads(parsed['data'])
            lines.append(f'  body: JSON.stringify({parsed["data"]}),')
        except (json.JSONDecodeError, TypeError):
            lines.append(f'  body: {repr(parsed["data"])},')

    if parsed['auth']:
        parts = parsed['auth'].split(':', 1)
        user = parts[0]
        passwd = parts[1] if len(parts) == 2 else ''
        b64_comment = f'btoa("{user}:{passwd}")'
        lines.append(f'  // Add to headers: Authorization: "Basic " + {b64_comment}')

    lines.append('})')
    lines.append('.then(response => response.text())')
    lines.append('.then(data => console.log(data))')
    lines.append('.catch(error => console.error(error));')
    return '\n'.join(lines)


def to_node(parsed):
    """Generate Node.js axios code."""
    lines = ['const axios = require("axios");', '']

    lines.append('axios({')
    lines.append(f'  method: "{parsed["method"].lower()}",')
    lines.append(f'  url: "{parsed["url"]}",')

    if parsed['headers']:
        lines.append('  headers: {')
        for k, v in parsed['headers'].items():
            lines.append(f'    "{k}": "{v}",')
        lines.append('  },')

    if parsed['data']:
        try:
            json.loads(parsed['data'])
            lines.append(f'  data: {parsed["data"]},')
        except (json.JSONDecodeError, TypeError):
            lines.append(f'  data: {repr(parsed["data"])},')

    if parsed['auth']:
        parts = parsed['auth'].split(':', 1)
        user = parts[0]
        passwd = parts[1] if len(parts) == 2 else ''
        lines.append('  auth: {')
        lines.append(f'    username: "{user}",')
        lines.append(f'    password: "{passwd}",')
        lines.append('  },')

    lines.append('})')
    lines.append('.then(response => console.log(response.data))')
    lines.append('.catch(error => console.error(error));')
    return '\n'.join(lines)


def main():
    lang = 'python'
    curl_input = None

    args = sys.argv[1:]
    positional = []

    for arg in args:
        if arg.startswith('--lang='):
            lang = arg.split('=', 1)[1]
        else:
            positional.append(arg)

    if positional:
        curl_input = ' '.join(positional)
    else:
        if not sys.stdin.isatty():
            curl_input = sys.stdin.read().strip()

    if not curl_input:
        print("Error: empty input", file=sys.stderr)
        sys.exit(1)

    if lang not in ('python', 'javascript', 'node'):
        print(f"Error: unknown language '{lang}'. Supported: python, javascript, node", file=sys.stderr)
        sys.exit(1)

    parsed = parse_curl(curl_input)

    generators = {
        'python': to_python,
        'javascript': to_javascript,
        'node': to_node,
    }

    output = generators[lang](parsed)
    print(output)


if __name__ == '__main__':
    main()
