# LadyBird_dev

A browser engine built from scratch in C++23. No legacy code, no borrowed engines — just the spec and the compiler.

## Architecture

```
src/
├── net/          HTTP/HTTPS client — TLS 1.2+ enforced, cert verification mandatory
├── html/         WHATWG HTML tokenizer (§13.2.5 state machine) + tree-construction parser
├── css/          CSS Syntax Level 3 parser — selector matching, cascade, computed styles
├── dom/          DOM tree — Document, Element, Text nodes
├── layout/       Block formatting context — layout box tree from DOM + styles
├── render/       Terminal renderer — ANSI output with headings, links, lists, tables
└── security/     CSP parser, Same-Origin Policy, sandbox flags
```

## Security Model

Security is first-class, not an afterthought:

| Layer | What it does |
|---|---|
| **TLS** | TLS 1.2 minimum, strong cipher suites only (ECDHE + AES-GCM / ChaCha20), hostname verification via OpenSSL X.509, OCSP stapling, no session ticket resumption |
| **URL** | Scheme whitelist (http/https), userinfo blocked, port range validated, host character validation |
| **HTTP** | HTTPS→HTTP redirect downgrade blocked, redirect count capped at 10, body size capped at 10 MB, header injection stripped |
| **CSP** | Full `Content-Security-Policy` header parsing and enforcement — `script-src`, `img-src`, `connect-src`, `upgrade-insecure-requests`, `block-all-mixed-content` |
| **SOP** | Same-Origin Policy checks on scheme + host + port |
| **Sandbox** | iframe `sandbox=` attribute parser mapping all WHATWG sandbox flags |
| **DOM** | Null bytes stripped from attribute names and values, no `innerHTML` eval path |
| **Compiler** | `-fstack-protector-strong`, `-D_FORTIFY_SOURCE=2`, `-Wformat-security`, RELRO, PIE |

## Build

**Requirements:** CMake 3.20+, C++23 compiler (GCC 13+ or Clang 16+), OpenSSL 3.x

```bash
./build.sh             # Release build
./build.sh Debug       # Debug build with symbols
```

Binary lands at `build/ladybird`.

## Usage

```bash
./build/ladybird https://example.com
./build/ladybird http://info.cern.ch
```

## Run tests

```bash
cd build && ctest --output-on-failure
```

## Roadmap

- [ ] CSS box model dimensions + text wrapping
- [ ] JavaScript engine (LibJS-style interpreter)
- [ ] Image decoding (PNG/JPEG)
- [ ] GUI rendering (SDL2 or GTK4 backend)
- [ ] HTTP/2 support
- [ ] Cookie jar with SameSite enforcement
- [ ] CORS preflight handling
- [ ] Full WHATWG URL parser
