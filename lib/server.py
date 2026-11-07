#!/usr/bin/env python3
from http.server import HTTPServer, BaseHTTPRequestHandler
import json
from pathlib import Path

LIB = Path("/var/www/html/lib/library.json")
SRC = Path("/var/www/threads-generator/data/library.json")

class H(BaseHTTPRequestHandler):
    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
    def do_OPTIONS(self):
        self.send_response(200); self._cors(); self.end_headers()
    def do_GET(self):
        if "/library.json" in self.path:
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self._cors()
            self.end_headers()
            self.wfile.write(LIB.read_bytes() if LIB.exists() else b'{"groups":[]}')
        else:
            self.send_response(404); self.end_headers()
    def do_POST(self):
        if self.path == "/lib/save":
            n = int(self.headers.get("Content-Length", 0))
            data = json.loads(self.rfile.read(n).decode())
            text = json.dumps(data, ensure_ascii=False, indent=2)
            LIB.write_text(text)
            SRC.write_text(text)
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self._cors()
            self.end_headers()
            self.wfile.write(b'{"ok":true}')
        else:
            self.send_response(404); self.end_headers()
    def log_message(self, *a): pass

HTTPServer(("127.0.0.1", 8088), H).serve_forever()
