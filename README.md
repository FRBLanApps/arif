# arif

Flutter 跨平台 **aria2-next** 下载管理器（AriaNg 风格原生壳）。

## 平台（V1）

| 平台 | 本地引擎 | 备注 |
| --- | --- | --- |
| Linux | 进程 + JSON-RPC | |
| Windows | 进程 + JSON-RPC | |
| Android | 进程 + 前台服务 + JSON-RPC | |
| iOS | FFI + **激进保活** | **仅侧载 / 越狱**，见 [docs/ios-keep-alive.md](docs/ios-keep-alive.md) |

所有平台均支持连接**远程** aria2 / aria2-next RPC。

## 引擎

[aria2-next](https://github.com/AnInsomniacy/aria2-next)（GPLv2）。浅 fork 仅用于构建与移动端补丁。

## 开发

需要 [FVM](https://fvm.app/)（本地轻量检查）。**完整编译请走 GitHub Actions，不要在开发机上重型 build。**

```bash
fvm use            # 使用 .fvmrc 中的 stable
fvm flutter pub get
# 可选：dart run melos bootstrap
cd apps/arif && fvm flutter analyze
```

### 远程 CI / 编译（推荐）

仓库：https://github.com/FRBLanApps/arif

```bash
./tool/ci_trigger.sh ci                      # analyze + test
./tool/ci_trigger.sh build                   # linux + android
./tool/ci_trigger.sh build all               # linux,android,windows,ios
./tool/ci_trigger.sh watch
./tool/ci_trigger.sh download tool/dist/ci-artifacts
```

详见 [docs/ci.md](docs/ci.md)。

### 结构

```
apps/arif            # UI + i18n (en / zh)
packages/arif_rpc    # JSON-RPC 客户端
packages/arif_core   # 领域模型
packages/arif_engine # 本地引擎宿主
docs/                # 架构 / CI / iOS 保活
tool/                # CI 触发、引擎下载脚本
.github/workflows/   # ci.yml + build.yml
```

### i18n

```bash
cd apps/arif && fvm flutter gen-l10n
```

ARB：`apps/arif/lib/l10n/app_en.arb`、`app_zh.arb`。

## 文档

- [CI 远程构建](docs/ci.md)
- [架构](docs/architecture.md)
- [引擎](docs/engine.md)
- [iOS 保活（必读）](docs/ios-keep-alive.md)


## 许可

见 [LICENSE](LICENSE)。捆绑的 aria2-next 遵循其 GPLv2。
