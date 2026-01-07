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
- ✅ **声音提醒**：番茄完成、休息开始/结束的声音提示
- ✅ **长休息**：每 4 个番茄自动触发长休息
- ✅ **每日统计**：跟踪每日完成的番茄数量
- ✅ **Bark 推送**：支持 iOS 设备推送通知（需配置 Bark）

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

### 基本设置

点击菜单栏中的 "⚙️ 设置" 打开设置窗口，可配置：

- **时间设置**：专注时长、短休息、长休息时长
- **声音设置**：启用声音提醒和音量调节
- **Bark 推送**：配置 iOS 推送通知
- **测试模式**：使用秒代替分钟进行快速测试

### Bark 推送配置

Bark 是一个 iOS 推送通知工具，可以让你在手机上收到番茄完成和休息结束的通知。

#### 设置步骤

1. **安装 Bark App**
   - 在 iPhone/iPad 的 App Store 搜索并安装 "Bark"
   - 打开 App，会自动生成一个推送 Key

2. **复制 Bark Key**
   - 在 Bark App 中，复制你的 Key（类似：`aBc123XyZ`）
   - 或者复制完整的测试 URL 中的 Key 部分：`https://api.day.app/aBc123XyZ/测试`

3. **在番茄钟中配置**
   - 打开番茄钟的设置窗口
   - 勾选 "启用 Bark 推送"
   - 将复制的 Key 粘贴到 "Bark Key" 输入框
   - 点击 "测试" 按钮验证配置是否成功
   - 点击 "保存"

4. **接收推送**
   - 番茄完成时：收到 "🍅 番茄完成" 推送
   - 休息结束时：收到 "☕️ 休息结束" 或 "🌴 长休息结束" 推送

#### Bark 文档
- 官方文档：https://bark.day.app
- 支持自定义服务器和更多高级功能

## 推迟机制

- 每轮番茄最多推迟 3 次
- 推迟选项：5 秒 / 10 秒 / 15 秒（测试模式）
- 休息时间计算：`基础休息 + floor(累计推迟秒 ÷ 5)`

## 已完成功能

- ✅ 自定义番茄时长
- ✅ 声音提醒
- ✅ 统计功能（每日番茄数）
- ✅ 长休息机制
- ✅ Bark 推送通知

## 未来规划

- [ ] 自定义 Menu Bar 图标
- [ ] 更多统计图表

## License

MIT
