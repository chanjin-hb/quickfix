#!/bin/sh
# Full FIX 4.2 order round-trip demo.
# Run from the repo root after building: ./demo/run.sh
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

if [ ! -x lib/executor ] || [ ! -x lib/tradeclient ]; then
  echo "Build first: cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j" >&2
  exit 1
fi

# Fresh runtime dirs (git-ignored).
rm -rf demo/store demo/log
mkdir -p demo/store/executor demo/store/client demo/log/executor demo/log/client

export LD_LIBRARY_PATH=lib

# Start the acceptor (server).
nohup ./lib/executor demo/executor.cfg > demo/executor.out 2>&1 &
EXEC_PID=$!
trap 'kill "$EXEC_PID" 2>/dev/null || true' EXIT
sleep 2

# Drive the interactive client to send one limit buy order.
# Field prompts are consumed in constructor-argument order (compiler-dependent);
# this sequence matches GCC. Groups of inputs are paced so logon completes
# before the order is sent and the execution report arrives before quitting.
{
  printf '1\n3\n'                                        # Action=Enter Order, Version=FIX.4.2
  sleep 2                                                # let logon complete
  printf '2\n1\nLNUX\nORDER001\n100\n1\n10.50\n'         # Limit, Buy, LNUX, ClOrdID, Qty, Day, Price
  printf 'CLIENT\nEXECUTOR\nN\nY\n'                      # Sender, Target, no TargetSubID, Send=Yes
  sleep 3                                                # let the execution report arrive
  printf '5\n'                                           # Quit
} | ./lib/tradeclient demo/tradeclient.cfg > demo/tradeclient.out 2>&1

sleep 1
kill "$EXEC_PID" 2>/dev/null || true

echo "===== NewOrderSingle sent by CLIENT (35=D) ====="
grep '35=D' demo/tradeclient.out | grep 'OUT:' | head -1 | tr '\001' '|' | sed 's/.*8=FIX/8=FIX/'
echo
echo "===== ExecutionReport returned by EXECUTOR (35=8) ====="
grep '35=8' demo/executor.out | head -1 | tr '\001' '|' | sed 's/.*(8=FIX/8=FIX/; s/)$//'
