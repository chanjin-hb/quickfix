# QuickFIX Order Round-Trip Demo

A minimal, self-contained demonstration of a full FIX 4.2 session: a client
sends a limit order and receives an execution report (fill) from a server.

## Components

- `executor.cfg` — acceptor (server) config, listens on port 15001. Uses the
  bundled `executor` example, which accepts **limit orders only** and fills
  them immediately.
- `tradeclient.cfg` — initiator (client) config, connects to the acceptor.
- `run.sh` — builds nothing; it launches the already-built example binaries,
  sends one limit order, and prints the messages that were exchanged.

## Quick start

Build everything and run the demo in one shot:

```bash
./demo/build.sh --run
```

## Scripts

- `build.sh` — configures and builds the library + example binaries.
  - `--ssl` configure with `-DHAVE_SSL=ON`
  - `--run` run `run.sh` after a successful build
- `run.sh` — launches the binaries, sends one limit order, and prints the
  messages exchanged. Requires a prior build.

Manual build (equivalent to `build.sh`):

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
```

This produces `lib/executor`, `lib/tradeclient`, and `lib/libquickfix.so`.

## Run

From the repo root, after building:

```bash
./demo/run.sh
```

Expected result: the client sends a `NewOrderSingle` (35=D) limit buy of 100
LNUX @ 10.50, and the server replies with an `ExecutionReport` (35=8) showing
`OrdStatus=Filled` (39=2), fully filled with `LeavesQty=0` (151=0).

## Note on order types

The `executor` example intentionally rejects any non-limit order:

```cpp
if (ordType != FIX::OrdType_LIMIT)
    throw FIX::IncorrectTagValue(ordType.getTag());
```

Sending a market order (OrdType=1) therefore produces a session-level
`Reject` (35=3, reason 5) referring to tag 40. Use a limit order (OrdType=2)
with a price to get a fill.
