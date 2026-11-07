#!/usr/bin/env python3
import json, os
from http.server import HTTPServer, BaseHTTPRequestHandler

DATA_FILE = "/var/www/html/data/windows.json"

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        if os.path.exists(DATA_FILE):
            with open(DATA_FILE) as f:
                self.wfile.write(f.read().encode())
        else:
            self.wfile.write(b"{}")
    
    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        data = self.rfile.read(length)
        with open(DATA_FILE, "wb") as f:
            f.write(data)
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(b"ok")
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

if __name__ == "__main__":
    HTTPServer(("127.0.0.1", 8089), Handler).serve_forever()
