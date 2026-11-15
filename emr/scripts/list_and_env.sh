#!/bin/bash
set -euo pipefail

echo "=== Step 1: List and Env Check ==="
echo "Working directory: $(pwd)"
echo "--- /mnt/var/lib/hadoop/tmp/"
ls -la /mnt/var/lib/hadoop/tmp/ || true

echo "--- Environment snapshot ---"
echo "Hostname: $(hostname)"
echo "User: $(whoami)"
echo "Python:"
python3 --version || true
echo "Spark:"
spark-submit --version 2>/dev/null || true

echo "Done."
