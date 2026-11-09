from http.server import HTTPServer, BaseHTTPRequestHandler
import json, os

DATA_DIR = "/var/www/html/data"

class Handler(BaseHTTPRequestHandler):
    def get_file(self):
        path = self.path.split("?")[0].strip("/")
        if path == "" or path == "data-api":
            return os.path.join(DATA_DIR, "windows.json")
        elif "tiktok" in path:
            return os.path.join(DATA_DIR, "tiktok.json")
        elif "facebook" in path:
            return os.path.join(DATA_DIR, "facebook.json")
        return os.path.join(DATA_DIR, "windows.json")
    
    def do_GET(self):
        try:
            f = self.get_file()
            with open(f) as file:
                data = file.read()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(data.encode())
        except Exception as e:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(str(e).encode())
    
    def do_POST(self):
        try:
            f = self.get_file()
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)
            with open(f, "w") as file:
                file.write(body.decode())
            self.send_response(200)
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(b'{"ok":true}')
        except Exception as e:
            self.send_response(500)
            self.end_headers()

HTTPServer(("0.0.0.0", 8089), Handler).serve_forever()
