# arif architecture

## Goal

Native AriaNg-style shell for **aria2-next** ([AnInsomniacy/aria2-next](https://github.com/AnInsomniacy/aria2-next)).

## V1 platforms

| Platform | Local engine | Control plane |
| --- | --- | --- |
| Linux | Process sidecar (`aria2-next`) | Internal JSON-RPC |
| Windows | Process sidecar | Internal JSON-RPC |
| Android | Process sidecar + foreground service | Internal JSON-RPC |
| iOS | libaria2 + FFI (no process spawn) | In-process / loopback RPC if needed |
| All | — | External remote RPC |
| Web (later) | None | External RPC only |

## Packages

```
apps/arif          Flutter UI + i18n
packages/arif_rpc  JSON-RPC client (aria2-compatible)
packages/arif_core Domain models, profiles, engine config
packages/arif_engine EngineHost (process now; FFI later)
third_party/aria2-next  git submodule / shallow fork patches
```

## Control plane rule

UI only talks to `SessionController` → `Aria2Client` (JSON-RPC).  
Local engine start is an implementation detail of `EngineHost` (not required for remote RPC).

### Current RPC + engine flow (V1)

```
App start (profile = local)
  → SessionController.connect()
  → LocalEngineService.ensureRunning()
       · reuse existing aria2 on port if RPC answers
       · else ProcessEngineHost spawn aria2-next/aria2c
  → aria2.getVersion
  → poll every 1s: getGlobalStat + tellActive/Waiting/Stopped
UI
  → addUri / pause / unpause / remove
Connections page
  → mode: local engine | remote RPC
  → host/port/secret/TLS and reconnect
```

Compatible with stock aria2 and aria2-next (Motrix Next–style method set).
FFI/libaria2 is deferred (iOS later).

## Tooling

- **FVM**: pin Flutter via `.fvmrc` (`stable`)
- **Melos**: workspace bootstrap for `apps/**` and `packages/**`
- Run: `fvm flutter ...` or `fvm dart ...` from repo root

## i18n

- Flutter gen-l10n from day one
- ARB: `apps/arif/lib/l10n/app_en.arb`, `app_zh.arb`
- Runtime language switch in Settings

## Engine binary

Prefer official aria2-next release artifacts; shallow-fork only for mobile packaging / run patches. See `tool/fetch_engine.sh`.
