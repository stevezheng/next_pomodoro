# CloudKit 准实时同步实施方案

> 实现 macOS 和 iOS 番茄钟应用的准实时倒计时同步（1-5秒延迟）

## 目录

- [概述](#概述)
- [技术选型](#技术选型)
- [架构设计](#架构设计)
- [CloudKit 数据模型](#cloudkit-数据模型)
- [同步机制](#同步机制)
- [冲突解决策略](#冲突解决策略)
- [实施步骤](#实施步骤)
- [核心代码框架](#核心代码框架)
- [性能指标](#性能指标)
- [潜在挑战](#潜在挑战)

---

## 概述

### 目标

实现 macOS 和 iOS 版本番茄钟应用的准实时倒计时同步，支持：
- **同步延迟**：1-5 秒
- **冲突处理**：协同模式（智能合并）
- **离线支持**：本地优先，云端同步

### 当前架构

- **技术栈**：原生 macOS 应用（Swift + AppKit）
- **状态管理**：基于状态机（StateMachine）模式
- **现有同步**：`NSUbiquitousKeyValueStore`（延迟大，约几分钟）

### 现有问题

| 问题 | 影响 |
|------|------|
| 同步延迟大 | `NSUbiquitousKeyValueStore` 可能需要几分钟 |
| 冲突处理简单 | 优先使用 iCloud 数据，无智能合并 |
| 无实时机制 | 依赖系统推送，无法保证 1-5 秒延迟 |

---

## 技术选型

### CloudKit vs 其他方案

| 方案 | 优点 | 缺点 | 选择 |
|------|------|------|------|
| **CloudKit** | 原生集成、免费、推送通知 | 配额限制 | ✅ |
| `NSUbiquitousKeyValueStore` | 简单易用 | 延迟大、无冲突解决 | ❌ |
| Firebase | 跨平台、实时性强 | 需要自建后端 | ❌ |
| WebSocket | 最低延迟 | 需要自建服务器 | ❌ |

### 为什么选择 CloudKit？

1. **原生集成**：无需额外依赖，直接使用 Apple 基础设施
2. **免费额度**：合理配额满足个人应用需求
3. **推送通知**：支持静默推送，实现准实时同步
4. **iCloud 账号**：用户无需额外注册

---

## 架构设计

### 系统架构图

```
┌─────────────────────────────────────────────────────────────┐
│                      用户设备                                │
├─────────────────────────────────────────────────────────────┤
│  macOS                    iOS                              │
│  ┌──────────────┐         ┌──────────────┐                │
│  │ StateMachine │         │ StateMachine │                │
│  └──────┬───────┘         └──────┬───────┘                │
│         │                        │                          │
│         ▼                        ▼                          │
│  ┌──────────────┐         ┌──────────────┐                │
│  │ SyncManager  │         │ SyncManager  │                │
│  └──────┬───────┘         └──────┬───────┘                │
│         │                        │                          │
│         └────────────┬───────────┘                          │
│                      ▼                                      │
│              ┌───────────────┐                              │
│              │ Persistence   │                              │
│              │ Manager       │                              │
│              └───────────────┘                              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                   CloudKit 服务                             │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐               │
│  │ Private Database│    │ Push Notification│               │
│  │  PomodoroZone   │◄───┤     Service      │               │
│  └─────────────────┘    └─────────────────┘               │
│                                                             │
│  ┌─────────────────────────────────────────────┐           │
│  │ CD_TimerState (记录类型)                     │           │
│  │ - deviceID, stateType, stateData            │           │
│  │ - timestamp, isPaused, completedPomodoros   │           │
│  └─────────────────────────────────────────────┘           │
│                                                             │
│  ┌─────────────────────────────────────────────┐           │
│  │ CD_Settings (记录类型)                       │           │
│  │ - deviceID, settingsData, timestamp         │           │
│  └─────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

### 三层同步机制

| 层级 | 触发条件 | 延迟 | 机制 | 用途 |
|------|----------|------|------|------|
| **Layer 1** | 用户操作 | < 1秒 | 直接调用 CloudKit save | 立即推送 |
| **Layer 2** | CloudKit 推送 | 1-5秒 | CKQuerySubscription + 静默通知 | 准实时同步 |
| **Layer 3** | 定期轮询 | 30秒 | 应用进入前台时兜底 | 容错机制 |

---

## CloudKit 数据模型

### 1. CD_TimerState（计时器状态记录）

| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `recordID` | `CKRecord.ID` | 自动生成 | 自动 |
| `deviceID` | `String` | 设备唯一标识 | "MacBook-Pro-2024" |
| `stateType` | `String` | 状态类型 | "focus", "idle", "breakTime", "snooze" |
| `stateData` | `Data` | JSON 编码的 Context | `FocusContext` 编码后的数据 |
| `timestamp` | `Date` | 状态更新时间戳 | `2024-01-07 12:00:00` |
| `isPaused` | `Bool` | 是否暂停 | `false` |
| `completedPomodoros` | `Int64` | 完成的番茄数 | `5` |
| `version` | `Int64` | 版本号（冲突解决） | `1704600000` |

### 2. CD_Settings（设置记录）

| 字段 | 类型 | 说明 |
|------|------|------|
| `recordID` | `CKRecord.ID` | 自动生成 |
| `deviceID` | `String` | 设备唯一标识 |
| `settingsData` | `Data` | JSON 编码的 Settings |
| `timestamp` | `Date` | 更新时间戳 |
| `version` | `Int64` | 版本号 |

### 3. CD_DeviceInfo（设备信息，辅助记录）

| 字段 | 类型 | 说明 |
|------|------|------|
| `recordID` | `CKRecord.ID` | 使用 deviceID 作为 ID |
| `deviceName` | `String` | 设备名称 |
| `lastSeen` | `Date` | 最后活跃时间 |
| `platform` | `String` | "macOS" 或 "iOS" |
| `appVersion` | `String` | 应用版本 |

---

## 同步机制

### CloudKit 配置

#### Custom Zone（自定义区域）

```swift
Zone Name: "PomodoroZone"
Zone Type: CKRecordZone
Purpose: 隔离应用数据，提高查询性能
```

**为什么使用 Custom Zone？**
- 支持更细粒度的查询订阅
- 减少 CloudKit 流量消耗
- 提高同步性能

#### Subscriptions（订阅）

**1. Query Subscription - 状态变化（主要）**

```swift
Type: CKQuerySubscription
RecordType: "CD_TimerState"
Predicate: NSPredicate(value: true)
SubscriptionID: "timerStateChanges"
Options: [.firesOnRecordCreation, .firesOnRecordUpdate]

NotificationInfo:
  - shouldSendContentAvailable: true  // 静默推送
  - shouldBadge: false
  - soundName: nil
```

**2. Database Subscription - 数据库变化（兜底）**

```swift
Type: CKDatabaseSubscription
Scope: Private
Zone: PomodoroZone
SubscriptionID: "databaseChanges"

NotificationInfo:
  - shouldSendContentAvailable: true
```

### 同步流程

#### 上传流程

```
用户操作（开始/暂停/停止）
    │
    ▼
StateMachine 更新
    │
    ▼
SyncManager.uploadTimerState()
    │
    ├─→ 编码状态为 JSON
    ├─→ 创建 CKRecord
    └─→ 调用 CKDatabase.save()
         │
         ▼
    CloudKit 保存
         │
         ▼
    触发推送通知
         │
         ▼
    其他设备接收
```

#### 下载流程

```
接收 APNs 推送
    │
    ▼
AppDelegate.handleRemoteNotification()
    │
    ▼
SyncManager.fetchLatestTimerState()
    │
    ├─→ 查询最新记录
    ├─→ 解码 JSON
    └─→ 冲突解决
         │
         ▼
    StateMachine.restoreState()
         │
         ▼
    UI 更新
```

---

## 冲突解决策略（协同模式）

### 冲突场景

当两个设备在短时间内（< 5秒）同时修改状态时，需要智能合并：

```
设备 A: 开始专注 (12:00:00)
设备 B: 开始休息 (12:00:03)
→ 冲突！需要合并
```

### 合并规则

#### 1. 时间戳比较（Last-Write-Wins）

```swift
if remoteTimestamp > localTimestamp + 5秒 {
    // 远程更新，使用远程状态
    return remoteState
} else if localTimestamp > remoteTimestamp + 5秒 {
    // 本地更新，保留本地状态
    return localState
}
// 5秒内，需要智能合并
```

#### 2. 智能合并（5秒内的冲突）

```swift
func mergeConflictingStates(local: TimerState, remote: TimerState) -> TimerState {
    // 规则 1: 番茄数取最大值（防止回退）
    let maxPomodoros = max(local.completedPomodoros, remote.completedPomodoros)

    // 规则 2: 状态优先级
    switch (local, remote) {
    case (.idle, .focus), (.focus, .idle):
        // 优先使用 focus 状态
        return focusState

    case (.focus(let a), .focus(let b)):
        // 使用剩余时间更少的（更接近完成）
        return a.remainingSeconds < b.remainingSeconds ? local : remote

    case (.breakTime(let a), .breakTime(let b)):
        // 使用剩余时间更少的
        return a.remainingSeconds < b.remainingSeconds ? local : remote

    default:
        // 默认使用时间戳更新的
        return localTimestamp > remoteTimestamp ? local : remote
    }
}
```

### 状态优先级

```
focus > breakTime > snooze > idle

理由：
- focus 和 breakTime 是活跃状态，用户正在使用
- idle 表示空闲，优先级最低
- snooze 是推迟状态，优先级介于 breakTime 和 idle 之间
```

---

## 实施步骤

### Phase 1: CloudKit 基础设施（1-2周）

**目标**：建立 CloudKit 数据模型和同步机制

#### 1.1 配置 CloudKit

- [ ] 在 Apple Developer 创建 Container
  - Container ID: `iCloud.com.pomodoro.timer`
  - 启用 CloudKit 服务

- [ ] 更新 Entitlements
  ```xml
  <!-- Resources/PomodoroTimer.entitlements -->
  <key>com.apple.developer.icloud-container-identifiers</key>
  <array>
      <string>iCloud.com.pomodoro.timer</string>
  </array>
  <key>com.apple.developer.icloud-services</key>
  <array>
      <string>CloudKit</string>
  </array>
  <key>com.apple.developer.push-notification</key>
  <true/>
  ```

- [ ] 实现 `CloudKitContainer.swift`
  ```swift
  // 初始化 CloudKit Container
  let container = CKContainer(identifier: "iCloud.com.pomodoro.timer")
  ```

#### 1.2 创建数据模型

- [ ] 实现 `CloudKitModels.swift`
  - `TimerStateRecord` 结构体
  - `SettingsRecord` 结构体
  - 编码/解码方法

- [ ] 实现 `CloudKitExtensions.swift`
  - `CKRecord` 扩展
  - `CKQuery` 辅助方法

- [ ] 实现 `DeviceIdentifier.swift`
  - 生成唯一设备 ID
  - 使用 `vendorID` + `UUID`

#### 1.3 实现核心同步

- [ ] 实现 `CloudKitSyncManager.swift`
  - 初始化 Zone 和 Subscriptions
  - `uploadTimerState()` 方法
  - `fetchLatestTimerState()` 方法

- [ ] 实现 `StateSyncDelegate.swift`
  - 定义同步协议
  - 回调接口

**验收标准：**
- [ ] 可以成功创建 Zone
- [ ] 可以成功创建 Subscriptions
- [ ] 可以上传状态到 CloudKit
- [ ] 可以从 CloudKit 下载状态

---

### Phase 2: 冲突处理和准实时同步（1-2周）

**目标**：实现 1-5 秒延迟和智能冲突解决

#### 2.1 冲突解决

- [ ] 实现 `ConflictResolver.swift`
  - 时间戳比较逻辑
  - 状态合并策略
  - 单元测试

- [ ] 实现 `SyncCoordinator.swift`
  - 协调本地持久化和 CloudKit 同步
  - 决定何时同步、何时合并

#### 2.2 推送通知

- [ ] 实现 `CKQuerySubscription`
  - 监听 `CD_TimerState` 变化
  - 配置静默推送

- [ ] 处理远程推送通知
  ```swift
  // macOS
  func applicationDidFinishLaunching(_ notification: Notification) {
      // 注册推送通知
  }

  func application(_ application: NSApplication,
                  didReceiveRemoteNotification: [String: Any]) {
      // 处理 CloudKit 推送
  }
  ```

#### 2.3 性能优化

- [ ] 批量操作
  - 减少请求数量
  - 合并多个更新

- [ ] 错误重试机制
  - 指数退避
  - 最大重试次数

**验收标准：**
- [ ] 推送通知可以在 5 秒内到达
- [ ] 冲突解决正确率 > 95%
- [ ] 网络错误可以自动恢复

---

### Phase 3: iOS 适配（1-2周）

**目标**：创建 iOS 应用，实现跨平台同步

#### 3.1 代码重构

- [ ] 提取共享代码到 `PomodoroCore`
  ```
  Sources/
  ├── PomodoroCore/          # 共享核心逻辑
  │   ├── Models/
  │   ├── StateMachine/
  │   ├── Persistence/
  │   └── Extensions/
  ├── PomodoroMac/           # macOS 特定代码
  └── PomodoriOS/            # iOS 特定代码
  ```

- [ ] 更新 `Package.swift`
  ```swift
  platforms: [
      .macOS(.v13),
      .iOS(.v16)
  ]
  ```

#### 3.2 iOS UI 实现

- [ ] 主界面（计时器显示）
  ```swift
  // Sources/PomodoriOS/Views/PomodoroView.swift
  struct PomodoroView: View {
      @ObservedObject var stateMachine: StateMachine

      var body: some View {
          VStack {
              Text(stateMachine.currentState.displayName)
              Button("Start") { /* ... */ }
          }
      }
  }
  ```

- [ ] 设置界面
- [ ] 推送通知集成

#### 3.3 跨平台测试

- [ ] macOS → iOS 同步测试
- [ ] iOS → macOS 同步测试
- [ ] 并发操作测试

**验收标准：**
- [ ] iOS 应用可以正常运行
- [ ] 跨平台同步延迟 < 5 秒
- [ ] UI 在两个平台上一致

---

### Phase 4: 测试和优化（1-2周）

**目标**：完善错误处理和用户体验

#### 4.1 错误处理

- [ ] 网络错误恢复
  - 离线队列
  - 自动重试

- [ ] CloudKit 配额管理
  - 限流处理
  - 降级策略

- [ ] 实现 `CloudKitError.swift`
  - 定义错误类型
  - 错误处理辅助方法

#### 4.2 用户体验

- [ ] 同步状态指示器
  - 显示"正在同步..."
  - 显示最后同步时间

- [ ] 离线模式支持
  - 本地优先
  - 联网后自动同步

#### 4.3 测试

- [ ] 单元测试
  - CloudKit 编码/解码测试
  - 冲突解决测试

- [ ] 集成测试
  - 端到端同步测试
  - 多设备测试

**验收标准：**
- [ ] 单元测试覆盖率 > 80%
- [ ] 所有集成测试通过
- [ ] 用户体验流畅

---

## 核心代码框架

### 1. CloudKitSyncManager.swift

```swift
import CloudKit

/// CloudKit 同步管理器
class CloudKitSyncManager {
    // MARK: - Dependencies
    private let container: CKContainer
    private let privateDB: CKDatabase
    private let zone: CKRecordZone
    private let deviceID: String

    // MARK: - Delegates
    weak var stateDelegate: StateSyncDelegate?
    weak var settingsDelegate: SettingsSyncDelegate?

    // MARK: - State
    private var lastSyncTimestamp: Date?
    private var syncInProgress: Bool = false

    // MARK: - Initialization
    init() {
        self.container = CKContainer(identifier: "iCloud.com.pomodoro.timer")
        self.privateDB = container.privateCloudDatabase
        self.zone = CKRecordZone(zoneName: "PomodoroZone")
        self.deviceID = Self.getDeviceID()

        setupZoneAndSubscriptions()
    }

    // MARK: - Public Methods

    /// 上传状态到 CloudKit
    func uploadTimerState(_ state: TimerState, pomodoros: Int) async throws {
        let record = CKRecord(recordType: "CD_TimerState", zoneID: zone.zoneID)

        // 编码状态数据
        let encoder = JSONEncoder()
        let stateData = try encoder.encode(state)

        // 设置字段
        record["deviceID"] = deviceID
        record["stateType"] = state.displayName
        record["stateData"] = stateData
        record["timestamp"] = Date()
        record["isPaused"] = state.isPaused
        record["completedPomodoros"] = Int64(pomodoros)
        record["version"] = Int64(Date().timeIntervalSince1970)

        // 保存到 CloudKit
        try await privateDB.save(record)
        Log.info("Timer state uploaded to CloudKit")

        // 更新本地时间戳
        lastSyncTimestamp = Date()
    }

    /// 从 CloudKit 拉取最新状态
    func fetchLatestTimerState() async throws -> CKRecord {
        let query = CKQuery(recordType: "CD_TimerState", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        let (records, _) = try await privateDB.records(matching: query)
        guard let latestRecord = records.first?.1 else {
            throw SyncError.noRecordsFound
        }

        return latestRecord
    }

    // MARK: - Private Methods

    private func setupZoneAndSubscriptions() {
        // 创建 Zone 和 Subscriptions
        // ... 详见完整实现
    }

    private static func getDeviceID() -> String {
        // 生成唯一设备 ID
        // ... 详见完整实现
    }
}

// MARK: - SyncDelegate Protocol
protocol StateSyncDelegate: AnyObject {
    func didReceiveRemoteState(_ state: TimerState)
    func syncDidFail(_ error: Error)
}
```

### 2. ConflictResolver.swift

```swift
/// 冲突解决器
class ConflictResolver {
    /// 合并冲突状态
    static func merge(
        local: TimerState,
        remote: TimerState,
        localTimestamp: Date,
        remoteTimestamp: Date,
        localPomodoros: Int,
        remotePomodoros: Int
    ) -> (state: TimerState, pomodoros: Int) {

        // 1. 时间戳比较
        let timeDiff = abs(localTimestamp.timeIntervalSince(remoteTimestamp))

        if timeDiff > 5 {
            // 超过 5 秒，使用时间戳更新的
            if remoteTimestamp > localTimestamp {
                return (remote, max(localPomodoros, remotePomodoros))
            } else {
                return (local, max(localPomodoros, remotePomodoros))
            }
        }

        // 2. 5 秒内，智能合并
        let mergedState = mergeConflictingStates(local: local, remote: remote)
        let maxPomodoros = max(localPomodoros, remotePomodoros)

        return (mergedState, maxPomodoros)
    }

    /// 智能合并冲突状态
    private static func mergeConflictingStates(
        local: TimerState,
        remote: TimerState
    ) -> TimerState {
        switch (local, remote) {
        case (.idle, .idle):
            return .idle

        case (.idle, .focus), (.focus, .idle):
            // 优先使用 focus 状态
            if case .focus(let ctx) = remote {
                return .focus(ctx)
            } else if case .focus(let ctx) = local {
                return .focus(ctx)
            }
            return local

        case (.focus(let localCtx), .focus(let remoteCtx)):
            // 使用剩余时间更少的
            return localCtx.remainingSeconds < remoteCtx.remainingSeconds
                ? .focus(localCtx)
                : .focus(remoteCtx)

        case (.breakTime(let localCtx), .breakTime(let remoteCtx)):
            // 使用剩余时间更少的
            return localCtx.remainingSeconds < remoteCtx.remainingSeconds
                ? .breakTime(localCtx)
                : .breakTime(remoteCtx)

        default:
            // 默认使用远程状态
            return remote
        }
    }
}
```

### 3. CloudKitModels.swift

```swift
import CloudKit

/// CloudKit Record 类型映射
struct TimerStateRecord {
    let recordID: CKRecord.ID
    let deviceID: String
    let stateType: String
    let stateData: Data
    let timestamp: Date
    let isPaused: Bool
    let completedPomodoros: Int64
    let version: Int64

    init?(record: CKRecord) {
        guard let deviceID = record["deviceID"] as? String,
              let stateType = record["stateType"] as? String,
              let stateData = record["stateData"] as? Data,
              let timestamp = record["timestamp"] as? Date,
              let isPaused = record["isPaused"] as? Bool,
              let completedPomodoros = record["completedPomodoros"] as? Int64,
              let version = record["version"] as? Int64
        else {
            return nil
        }

        self.recordID = record.recordID
        self.deviceID = deviceID
        self.stateType = stateType
        self.stateData = stateData
        self.timestamp = timestamp
        self.isPaused = isPaused
        self.completedPomodoros = completedPomodoros
        self.version = version
    }

    func decodeTimerState() throws -> TimerState {
        let decoder = JSONDecoder()
        return try decoder.decode(TimerState.self, from: stateData)
    }
}
```

---

## 性能指标

### 目标指标

| 指标 | 目标值 | 测量方法 |
|------|--------|----------|
| **同步延迟** | < 5 秒 | 上传 → 推送 → 下载时间差 |
| **冲突解决率** | > 95% | 并发操作测试成功率 |
| **CloudKit 请求数** | < 100 次/小时 | CKOperation 计数 |
| **流量消耗** | < 1 MB/天 | Record 大小累加 |
| **电池影响** | < 2%/小时 | iOS 能效日志 |

### CloudKit 配额

| 资源 | 免费额度 | 预估使用 |
|------|----------|----------|
| 存储空间 | 1 GB | < 10 MB |
| 每日请求 | 40 次/秒 | < 1 次/分钟 |
| 每月带宽 | 200 GB | < 1 GB |

---

## 潜在挑战

### 挑战 1: CloudKit 延迟不可控

**问题**：CloudKit 推送通知可能延迟超过 5 秒

**解决方案**：
1. 使用 `CKFetchNotificationChangesOperation` 主动拉取
2. 应用进入前台时立即同步
3. 每 30 秒兜底轮询

```swift
// 应用进入前台时同步
func applicationDidBecomeActive(_ notification: Notification) {
    Task {
        try? await syncManager.fetchLatestTimerState()
    }
}
```

### 挑战 2: 冲突解决复杂

**问题**：两个设备同时操作可能导致数据不一致

**解决方案**：
1. 5 秒内的冲突视为并发，需要合并
2. 番茄数永远取最大值（防止回退）
3. 状态转换优先级：focus/break > idle

### 挑战 3: CloudKit 配额限制

**问题**：免费账户有读写限制

**解决方案**：
1. 只同步必要数据（状态 + 设置）
2. 批量操作减少请求次数
3. 使用缓存减少查询

### 挑战 4: iOS 和 macOS UI 差异

**问题**：Menu Bar 应用无法直接移植到 iOS

**解决方案**：
1. 提取核心逻辑到共享模块
2. iOS 使用 UIKit/SwiftUI 重建 UI
3. 保持状态机和同步逻辑一致

---

## 相关文档

- [iCloud 同步配置](./icloud-sync.md) - 现有的 iCloud 同步实现
- [数据持久化设计](./persistence-and-icloud.md) - 数据持久化架构
- [持久化测试](./testing-persistence.md) - 测试策略

---

## 总结

本方案通过 CloudKit 实现了 macOS 和 iOS 番茄钟应用的准实时同步：

1. **准实时推送**：CKQuerySubscription + 静默通知，延迟 1-5 秒
2. **智能冲突解决**：时间戳比较 + 状态合并，实现协同模式
3. **代码复用**：提取核心逻辑到共享模块，支持跨平台
4. **渐进式实施**：分 4 个阶段，每个阶段 1-2 周

**总预计开发时间：6-8 周**
