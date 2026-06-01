#!/usr/bin/env python3
"""Static file server for the exported Godot Web build (./build/web).

Godot's HTML5 export needs `.wasm` served as `application/wasm` (for streaming compilation) and
`.pck` as a binary stream. This export uses the *non-threaded* variant, so no COOP/COEP
cross-origin-isolation headers are required.

Usage:
    python serve.py [port]        # default port 8061
Then open http://localhost:<port>/ in a browser.
"""
import http.server
import socketserver
import os
import sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8061
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "build", "web")


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def end_headers(self):
        # always serve fresh files during local testing
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


Handler.extensions_map.update({
    ".wasm": "application/wasm",
    ".pck": "application/octet-stream",
    ".js": "text/javascript",
})

if not os.path.isdir(ROOT):
    print(f"Build folder not found: {ROOT}\nRun the Web export first.")
    sys.exit(1)

socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("127.0.0.1", PORT), Handler) as httpd:
    print(f"Serving {ROOT}")
    print(f"  http://localhost:{PORT}/   (Ctrl+C to stop)")
    httpd.serve_forever()
