#!/usr/bin/env python3
import json, sys
from pathlib import Path
p = Path("/var/www/html/lib/library.json")
src = Path("/var/www/threads-generator/data/library.json")
try:
    data = json.loads(sys.stdin.read())
    lib = json.loads(p.read_text()) if p.exists() else {}
    for k in ["hooks","ends","kwhook","scenes","generated"]:
        if k in data and isinstance(data[k], list):
            lib.setdefault(k, [])
            for item in data[k]:
                if item and item not in lib[k]:
                    lib[k].append(item)
    p.write_text(json.dumps(lib, ensure_ascii=False, indent=2))
    src.write_text(json.dumps(lib, ensure_ascii=False, indent=2))
    print("Content-Type: application/json\n")
    print(json.dumps({"ok": True, "count": sum(len(v) for v in lib.values() if isinstance(v, list))}))
except Exception as e:
    print("Content-Type: application/json\n")
    print(json.dumps({"ok": False, "error": str(e)}))
