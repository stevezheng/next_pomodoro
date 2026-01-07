# iCloud 同步功能说明

## 功能概述

番茄钟应用现在支持通过 iCloud 自动同步你的设置，包括：
- 专注时长设置
- 休息时长设置
- 声音设置
- Bark 推送设置
- 测试模式开关
- 应用状态（当前计时器状态、已完成的番茄数）

## 工作原理

### 双存储机制
- **本地存储**：使用 UserDefaults，保证数据即使在离线时也能访问
- **iCloud 存储**：使用 NSUbiquitousKeyValueStore，在多台设备间同步

### 自动同步
- 每次保存设置时，会同时保存到本地和 iCloud
- 当其他设备修改设置后，本设备会自动接收更新
- 采用"最新优先"策略：如果本地和云端数据不一致，优先使用 iCloud 数据

### 冲突解决
- 启动时会比较本地和 iCloud 数据
- 如果本地没有数据，从 iCloud 恢复
- 如果数据不同，使用 iCloud 数据（假设它是最新的）

## 使用说明

### 启用 iCloud 同步

1. **在 macOS 系统设置中登录 iCloud**
   - 打开"系统设置" > "Apple ID"
   - 确保已登录你的 Apple ID
   - 确保 iCloud Drive 已启用

2. **检查同步状态**
   - 打开番茄钟设置窗口
   - 查看底部的"iCloud 同步"状态
   - ✅ 表示已启用并正常工作
   - ⚠️ 表示未启用或需要登录 iCloud

### 多设备同步

1. 在所有设备上安装相同版本的番茄钟应用
2. 确保所有设备都使用相同的 Apple ID 登录
3. 设置会在几秒内自动同步到所有设备

### 注意事项

#### iCloud 配额限制
- NSUbiquitousKeyValueStore 有 1MB 的存储限制
- 每个键最大 1MB
- 最多 1024 个键
- 番茄钟的设置数据很小，远低于这些限制

#### 同步延迟
- iCloud 同步不是实时的，可能有几秒到几分钟的延迟
- 如果网络较慢，延迟可能更长
- 应用会在启动时主动同步一次

#### 离线使用
- 即使没有 iCloud 或离线，应用仍然可以正常工作
- 数据会保存到本地 UserDefaults
- 恢复网络后会自动同步到 iCloud

## 开发说明

### 代码签名要求

为了在实际发布时使用 iCloud，需要：

1. **添加开发团队**
   - 在 Xcode 中配置开发团队
   - 或使用命令行签名工具

2. **配置 Entitlements**
   - 已创建 `Resources/PomodoroTimer.entitlements`
   - 包含必要的 iCloud 权限

3. **更新 Bundle Identifier**
   - 确保与 entitlements 中的一致
   - 当前为：`com.pomodoro.timer`

### 测试 iCloud 同步

```bash
# 在一台设备上修改设置
# 然后在另一台设备上检查
defaults read com.pomodoro.timer

# 查看 iCloud 存储
defaults read NSGlobalDomain NSUbiquitousKeyValueStore
```

### 调试日志

在代码中已添加详细的日志：
- "iCloud 同步已启用" - iCloud 初始化成功
- "检测到 iCloud 数据变化" - 其他设备修改了设置
- "已从 iCloud 同步 XXX 到本地" - 数据同步完成
- "已保存 XXX 到本地和 iCloud" - 数据保存成功

## 故障排除

### iCloud 显示未启用

**可能原因：**
1. 未登录 iCloud 账户
2. iCloud Drive 未启用
3. 应用没有 iCloud 权限

**解决方法：**
1. 检查系统设置 > Apple ID
2. 确保 iCloud Drive 已开启
3. 检查应用的 entitlements 配置

### 设置没有同步

**可能原因：**
1. 网络连接问题
2. iCloud 服务延迟
3. 多台设备使用不同的 Apple ID

**解决方法：**
1. 检查网络连接
2. 等待几分钟让 iCloud 同步
3. 确保所有设备使用相同的 Apple ID
4. 在设置窗口中手动检查同步状态

### 数据冲突

**当前策略：**
- 优先使用 iCloud 数据
- 这意味着云端的修改会覆盖本地修改
- 这是简单但有效的策略

**未来改进：**
- 可以添加时间戳比较
- 可以添加冲突解决 UI
- 可以添加合并策略

## 隐私说明

- 所有数据都通过 Apple 的 iCloud 服务同步
- 数据端到端加密
- 只有你的设备可以访问
- 开发者无法访问你的 iCloud 数据
- Bark Key 等敏感信息会随设置一起加密同步
