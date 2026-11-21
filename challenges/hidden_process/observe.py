#!/usr/bin/env python3
"""Submit an observed live PID for protected validation; user has no grader access."""
import json
import socket
import sys
try:
    pid = int(sys.argv[1])
except (IndexError, ValueError):
    raise SystemExit("Usage: aeb-observe <LIVE_ROOT_PROCESS_PID>")
with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
    connection.settimeout(3)
    connection.connect("/run/aeb-observe.sock")
    connection.sendall(json.dumps({"pid": pid}).encode())
    print(connection.recv(128).decode().strip())
