# 🍅 番茄钟 · macOS Menu Bar App

一个为 macOS 设计的强制休息番茄钟应用。

**核心设计理念：它不奖励自律，只惩罚不休息。**

## 特性

- ✅ **状态机驱动**：清晰的状态转换逻辑（Idle → Focus → Snooze → Break）
- ✅ **强提醒系统**：系统级弹窗强制打断当前工作
- ✅ **推迟机制**：最多 3 次推迟机会，强度递增警告
- ✅ **动态惩罚**：休息时间随推迟时间自动增加
- ✅ **暂停/恢复**：Focus 和 Break 阶段可暂停
- ✅ **数据持久化**：应用重启后自动恢复状态
- ✅ **原生性能**：纯 Swift 实现，无 Electron 依赖

## 状态机

```
Idle
├─ Start → Focus
└─ Stop → Idle

Focus
├─ TimeUp → Snooze
├─ Stop → Idle（不计完成数）
└─ Pause/Resume

Snooze
├─ TimeUp（< 3次）→ 再 Snooze
├─ TimeUp（= 3次）→ 强制 Break
├─ StartBreak → Break
└─ Stop → Idle

Break
├─ TimeUp → Idle（+1 完成数）
├─ Stop → Idle（+1 完成数）
└─ Pause/Resume
```

## 开发

### 环境要求

- macOS 13.0+
- Xcode Command Line Tools
- Swift 5.9+

### 构建

```bash
# 编译
swift build

# 创建 App Bundle
./build.sh

# 运行应用
open PomodoroTimer.app
```

### 项目结构

```
Sources/PomodoroTimer/
├── Models/                    # 数据模型
│   ├── AppState.swift         # 状态定义
│   └── Constants.swift        # 常量配置
├── StateMachine/              # 状态机核心
│   ├── StateMachine.swift
│   └── Handlers/              # 状态处理器
│       ├── IdleHandler.swift
│       ├── FocusHandler.swift
│       ├── SnoozeHandler.swift
│       └── BreakHandler.swift
├── Timer/                     # 精确计时器
│   └── PreciseTimer.swift
├── MenuBar/                   # Menu Bar 管理
│   └── MenuBarManager.swift
├── Notifications/             # 弹窗提醒
│   └── AlertManager.swift
├── Persistence/               # 数据持久化
│   └── PersistenceManager.swift
├── Extensions/                # 扩展
│   └── StringExtensions.swift
├── PomodoroApp.swift          # 主应用
└── main.swift                 # 入口
```

## 技术栈

- **语言**：Swift 5.9+
- **框架**：AppKit + Foundation
- **架构**：状态机模式 + 事件驱动
- **持久化**：UserDefaults
- **计时**：DispatchSourceTimer（目标时间法）

## 配置

当前为**测试模式**，可在 `Models/AppState.swift` 中修改：

```swift
Settings(
    focusDuration: 25,     // 番茄时长（秒）
    baseBreakDuration: 5,  // 基础休息时长（秒）
    testMode: true         // 测试模式
)
```

- **测试模式**：25 秒番茄，5 秒休息
- **正常模式**：25 分钟番茄，5 分钟休息

## 推迟机制

- 每轮番茄最多推迟 3 次
- 推迟选项：5 秒 / 10 秒 / 15 秒（测试模式）
- 休息时间计算：`基础休息 + floor(累计推迟秒 ÷ 5)`

## 未来规划

- [ ] 自定义番茄时长
- [ ] 声音提醒
- [ ] 自定义 Menu Bar 图标
- [ ] 统计功能

## License

MIT
