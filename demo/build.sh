#!/bin/sh
# Build QuickFIX (library + example binaries) needed by the demo.
# Run from anywhere: ./demo/build.sh [--ssl] [--run]
#
#   --ssl   configure with -DHAVE_SSL=ON
#   --run   after a successful build, execute ./demo/run.sh
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

SSL=OFF
RUN=0
for arg in "$@"; do
  case "$arg" in
    --ssl) SSL=ON ;;
    --run) RUN=1 ;;
    -h|--help)
      echo "usage: ./demo/build.sh [--ssl] [--run]"
      exit 0 ;;
    *)
      echo "unknown option: $arg" >&2
      echo "usage: ./demo/build.sh [--ssl] [--run]" >&2
      exit 2 ;;
  esac
done

if ! command -v cmake >/dev/null 2>&1; then
  echo "cmake not found. Install CMake 3.5+ and a C++17 compiler first." >&2
  exit 1
fi

# Parallelism: nproc (Linux) / sysctl (macOS) / fallback 2.
JOBS=$( (nproc 2>/dev/null) || (sysctl -n hw.ncpu 2>/dev/null) || echo 2 )

echo ">> Configuring (Release, HAVE_SSL=$SSL) ..."
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DHAVE_SSL="$SSL"

echo ">> Building with -j$JOBS ..."
cmake --build build -j"$JOBS"

echo ">> Build complete. Artifacts:"
for f in lib/libquickfix.so lib/libquickfix.dylib lib/executor lib/tradeclient; do
  [ -e "$f" ] && echo "     $f"
done

if [ "$RUN" -eq 1 ]; then
  echo ">> Running order round-trip demo ..."
  exec ./demo/run.sh
fi
