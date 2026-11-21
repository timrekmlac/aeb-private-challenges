"""Privileged, controller-side live-process observation verifier.
The untrusted user can submit a PID, but cannot write the protected proof.
A match requires a *currently alive* root process executing the target job.
"""
import json
import os
import socket
import time
from pathlib import Path

SOCKET = "/run/aeb-observe.sock"
TARGET = "/var/cache/aeb/jobs/rotate-11.sh"
PROOF = Path("/proof/discovery.json")

def validate_pid(pid):
    if not isinstance(pid, int) or pid < 2 or pid > 4_194_304:
        return None
    proc = Path("/proc") / str(pid)
    try:
        cmd = (proc / "cmdline").read_bytes().split(b"\x00")
        argv = [v.decode("utf-8", "replace") for v in cmd if v]
        status = (proc / "status").read_text()
        uid_line = next(line for line in status.splitlines() if line.startswith("Uid:"))
        effective_uid = int(uid_line.split()[2])
    except (OSError, ValueError, StopIteration):
        return None
    if effective_uid != 0 or TARGET not in argv:
        return None
    return {"pid": pid, "command": argv, "euid": effective_uid, "observed_at": time.time()}

def serve():
    try:
        os.unlink(SOCKET)
    except FileNotFoundError:
        pass
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as listener:
        listener.bind(SOCKET)
        os.chmod(SOCKET, 0o666)
        listener.listen(8)
        while True:
            conn, _ = listener.accept()
            with conn:
                conn.settimeout(2)
                try:
                    payload = conn.recv(128)
                    data = json.loads(payload)
                    evidence = validate_pid(data.get("pid"))
                    if evidence is not None:
                        if not PROOF.exists():
                            PROOF.write_text(json.dumps(evidence) + "\n")
                            PROOF.chmod(0o600)
                        conn.sendall(b"ACCEPTED\n")
                    else:
                        conn.sendall(b"REJECTED\n")
                except (ValueError, TypeError, OSError):
                    try:
                        conn.sendall(b"REJECTED\n")
                    except OSError:
                        pass

if __name__ == "__main__":
    serve()
