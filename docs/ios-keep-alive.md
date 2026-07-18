# iOS 后台保活说明（给用户 / 给开发者）

> **一句话**：iOS 版 arif **只面向侧载与越狱**。为了让本地下载引擎在切后台后仍尽量继续跑，我们会**主动滥用**系统保活相关能力。这**不能**上架 App Store，也**不能**保证永远不被系统杀掉。

---

## 1. 为什么要和用户说清楚

普通 iOS App 在进入后台后很快被挂起，网络与 CPU 时间被严格限制。  
aria2-next 这类引擎（多连接 HTTP、BT、ED2K 等）需要**长时间持续运行**，官方“合规后台”接口（BackgroundTasks、后台 URLSession 等）**做不到**桌面级下载器体验。

因此 arif 的 iOS 策略是：

| 渠道 | 策略 |
| --- | --- |
| App Store | **不做**本地引擎真后台 |
| 侧载（TrollStore / 企业签 / 开发者签等） | 使用激进保活，尽力而为 |
| 越狱 | 可进一步放宽进程生命周期，最接近“真常驻” |

用户安装前应知道：

1. **耗电、发热**会明显高于普通 App  
2. 系统在内存紧张、低电量、热管理时仍可能杀进程  
3. 系统版本升级可能让某类保活手法失效  
4. 这是**工程取舍**，不是“系统官方推荐用法”

应用内设置页提供了摘要与入口（`IosKeepAlivePage`），并随 **i18n** 切换语言。

---

## 2. “滥用保活 API”指什么

这里的“滥用”不是破解系统内核（越狱方案另论），而是：

- 把**设计用途很窄**的后台模式，用到**下载引擎常驻**上  
- 组合多种手段，尽量推迟挂起 / 被杀  
- **不**声称符合 App Review 指南

### 侧载环境常见手段（规划，非承诺清单）

| 手段 | 作用 | 代价 / 风险 |
| --- | --- | --- |
| `UIBackgroundModes`（audio / voip / location / fetch / processing 等） | 延长后台执行窗口 | 审核必拒；部分需真实 entitlement |
| 静音音频会话 / 无声播放 | 骗取 audio 后台 | 耗电；系统策略变化即失效 |
| 后台任务 + 自行续命 | 争取更多执行切片 | 时间有限，不可靠 |
| 本地通知 / 前台服务式常驻提示 | 提高用户感知与部分机型存活率 | 体验打扰 |
| 网络保活（长连接、定时流量） | 降低被判定“空闲”的概率 | 耗电、耗流量 |
| 越狱：禁用挂起、常驻 daemon、LaunchDaemon | 接近桌面进程模型 | 仅越狱设备 |

**引擎形态**：iOS 使用 **libaria2 + FFI** 跑在 App 进程内（不能像 Android/桌面那样随便 spawn `aria2-next` 子进程并长期托管）。保活的对象是**整个 App 进程**。

---

## 3. 和 Android / 桌面的差异

| | Linux / Windows | Android | iOS |
| --- | --- | --- | --- |
| 本地引擎 | `aria2-next` 子进程 | 子进程 + Foreground Service | FFI 进程内 |
| 后台 | 系统正常允许 | 前台服务 + 通知 | 激进保活 / 越狱 |
| 远程 RPC | 支持 | 支持 | 支持（最稳妥的“手机当遥控”方式） |

若用户无法接受 iOS 本地保活的副作用，应优先：**手机只连 NAS/电脑上的 aria2-next（远程 RPC）**。

---

## 4. 产品文案原则

- 设置 / 关于 / 首次 iOS 启动：展示保活摘要  
- 不使用“官方后台下载”“低耗电常驻”等误导表述  
- 文档与 UI 统一指向本文与 `docs/architecture.md`

### 建议对用户说的短句（中）

> iOS 版仅支持侧载与越狱。为保持下载在后台继续，arif 会使用非常规系统保活手段，可能导致耗电升高，且无法保证不被系统中断。无法上架 App Store。

### Short copy (EN)

> The iOS build is for sideload/jailbreak only. Keep-alive deliberately stretches system background APIs so downloads can continue; expect higher battery use and no App Store compliance.

---

## 5. 开发者实现边界（后续代码）

1. 保活逻辑集中在 `packages/arif_engine` 的 iOS 实现 + 少量 Platform Channel，避免散落在 UI  
2. 用编译开关 / flavor 区分 `sideload` 与 `jailbreak` 能力集  
3. 远程-only 模式始终可用，作为保活失败时的退路  
4. 崩溃与被杀：session 恢复依赖 aria2 会话文件 / 任务状态落盘  

---

## 6. 许可与分发

- 引擎：aria2-next，**GPLv2**  
- iOS 侧载包分发时需在说明中保留引擎版权与 GPL 提示  
- 本文不构成法律意见；上架与签名风险由分发者自行承担
