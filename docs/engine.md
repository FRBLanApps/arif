# Engine integration (aria2-next)

Upstream: https://github.com/AnInsomniacy/aria2-next

## Modes

| Mode | Package API | Platforms |
| --- | --- | --- |
| **Process sidecar** (V1) | `ProcessEngineHost` / `LocalEngineService` | Linux, Windows, Android (staged binary) |
| **Remote RPC only** | `Aria2Client` via `SessionController` | All |
| **FFI / libaria2** | *later* | iOS (required), optional elsewhere |

## Process mode (Motrix Next–style)

```
LocalEngineService.ensureRunning()
  → reuse existing RPC on port if aria2 already answers
  → else locate binary (ARIF_ENGINE_PATH, PATH, tool/dist/engine, …)
  → ProcessEngineHost.start(EngineConfig)
  → waitForRpcReady(getVersion)
  → SessionController polls JSON-RPC
```

### Binary resolution

1. `ARIF_ENGINE_PATH` or `ARIA2_PATH`
2. Bundled / search dirs (`tool/dist/engine`, next to app executable)
3. `PATH` (`aria2-next`, `aria2c`)
4. Common Unix prefixes (`/usr/bin`, …)

Fetch release artifacts:

```bash
./tool/fetch_engine.sh v2.5.1
```

### Lifecycle

- **Start**: create data dirs, optional free-port allocation, spawn, wait RPC
- **Stop**: `aria2.shutdown` / `forceShutdown`, then SIGTERM/SIGKILL
- **Env**: child process clears `HTTP(S)_PROXY` for reliable loopback RPC

### Data paths (default)

| OS | Root |
| --- | --- |
| Linux | `$XDG_DATA_HOME/arif` or `~/.local/share/arif` |
| Windows | `%APPDATA%/arif` |
| macOS | `~/.local/share/arif` (same XDG-style for now) |

Contains `downloads/`, `aria2.session`, optional conf/log.

## App wiring

- Profile `EngineMode.local` + `autoStartLocalEngine` → ensure process/reuse then connect
- Profile `EngineMode.remote` → only JSON-RPC to host:port

## FFI (not in this milestone)

iOS will host libaria2 in-process; `EngineHost` stays the abstraction.
