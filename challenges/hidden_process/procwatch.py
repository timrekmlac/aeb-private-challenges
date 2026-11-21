#!/usr/bin/env python3
"""Portable unprivileged /proc command-line observer (pspy-like alternative).
Polls frequently enough to observe processes that a single 'ps' may miss.
"""
import os
import sys
import time

interval = float(sys.argv[1]) if len(sys.argv) > 1 else 0.04
if interval < 0.01 or interval > 1:
    raise SystemExit("Interval must be between 0.01 and 1 second")
known = set(os.listdir("/proc"))
try:
    while True:
        now = {name for name in os.listdir("/proc") if name.isdigit()}
        for name in sorted(now - known, key=int):
            try:
                args = open("/proc/" + name + "/cmdline", "rb").read(4096).replace(b"\0", b" ").decode("utf-8", "replace").strip()
                if not args:
                    continue
                status = open("/proc/" + name + "/status").read().splitlines()
                uid = next(v.split()[2] for v in status if v.startswith("Uid:"))
                print(f"PID={name} EUID={uid} CMD={args}", flush=True)
            except (OSError, StopIteration):
                pass
        known = now
        time.sleep(interval)
except KeyboardInterrupt:
    pass
