# CI / remote builds

本机**不建议**做完整平台编译。使用 GitHub Actions + `gh`。

仓库：https://github.com/FRBLanApps/arif

## Workflows

| Workflow | 文件 | 触发 | 作用 |
| --- | --- | --- | --- |
| **CI** | `.github/workflows/ci.yml` | push / PR / 手动 | analyze + unit test |
| **Build** | `.github/workflows/build.yml` | 手动 / tag `v*` | 多平台产物 + artifact |

## 用 gh 触发

```bash
# 分析与测试
./tool/ci_trigger.sh ci

# 构建 Linux + Android（默认）
./tool/ci_trigger.sh build

# 指定平台
./tool/ci_trigger.sh build linux,android,windows
./tool/ci_trigger.sh build ios
./tool/ci_trigger.sh build all

# 查看 / 拉取产物
./tool/ci_trigger.sh watch
./tool/ci_trigger.sh download tool/dist/ci-artifacts
```

等价命令：

```bash
gh workflow run ci.yml --repo FRBLanApps/arif
gh workflow run build.yml --repo FRBLanApps/arif -f targets=linux,android -f profile=release
gh run list --repo FRBLanApps/arif --limit 5
gh run watch <run-id> --repo FRBLanApps/arif
gh run download <run-id> --repo FRBLanApps/arif --dir ./artifacts
```

## 产物说明

| Target | Runner | Artifact |
| --- | --- | --- |
| linux | ubuntu-latest | `arif-linux-x64.tar.gz` |
| android | ubuntu-latest | `arif-android-release.apk`（debug 签名） |
| windows | windows-latest | `arif-windows-x64.zip` |
| ios | macos-latest | `arif-ios-unsigned.tar.gz`（`--no-codesign`，侧载需自行签名） |

## 本地仅做轻量检查（可选）

```bash
fvm flutter pub get
(cd packages/arif_rpc && fvm dart test)
(cd apps/arif && fvm flutter analyze)
```

完整 `flutter build` 请走 CI。
