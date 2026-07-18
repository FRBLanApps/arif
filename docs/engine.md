# Engine integration (aria2-next)

Upstream: https://github.com/AnInsomniacy/aria2-next

## V1 strategy

1. Pin a release tag (e.g. `v2.5.1`) via submodule under `third_party/aria2-next`.
2. Prefer **official release binaries** for Linux / Windows / Android arm64.
3. Shallow fork only for packaging / execution patches (not protocol core).

## Process mode (Linux, Windows, Android)

```
arif → ProcessEngineHost.start(EngineConfig)
    → spawn aria2-next --enable-rpc ...
    → Aria2Client → http://127.0.0.1:$port/jsonrpc
```

## FFI mode (iOS, optional later elsewhere)

```
arif → FfiEngineHost (libaria2)
    → same domain models / optional loopback RPC facade
```

## Fetch script

```bash
./tool/fetch_engine.sh v2.5.1
```

Artifacts land in `tool/dist/engine/` for bundling into app assets.
