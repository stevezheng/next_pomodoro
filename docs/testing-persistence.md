# 持久化和 iCloud 同步测试指南

## 快速验证步骤

### 1. 验证基本持久化（已修复）

**测试 Bark 设置持久化：**

```bash
# 1. 打开应用，进入设置
# 2. 启用 Bark 推送，输入一个测试 Key（如 "test123"）
# 3. 保存设置
# 4. 完全退出应用
./kill-app.sh

# 5. 重新启动应用
open ./PomodoroTimer.app

# 6. 再次打开设置，验证 Bark Key 是否还在
# ✅ 如果 Key 保持，说明持久化成功
# ❌ 如果 Key 消失，说明还有问题
```

**测试所有设置持久化：**

```bash
# 1. 修改以下设置：
#    - 专注时长：30 分钟
#    - 短休息：8 分钟
#    - 启用声音，音量 50%
#    - 启用 Bark，输入 Key
# 2. 保存并退出应用
./kill-app.sh

# 3. 重新构建（模拟重新编译）
./build.sh

# 4. 启动新构建的应用
open ./PomodoroTimer.app

# 5. 打开设置验证所有配置是否保持
# ✅ 所有设置应该都还在
```

### 2. 验证 iCloud 同步状态

**检查 iCloud 是否可用：**

```bash
# 1. 打开应用设置
# 2. 查看底部的 "iCloud 同步" 状态

# 可能的状态：
# ✅ 状态：已启用（设置将自动同步到 iCloud）
#    → iCloud 正常工作
#
# ⚠️ 状态：未启用（请在系统设置中登录 iCloud）
#    → 需要登录 iCloud 或应用权限问题
```

**验证 iCloud 登录：**

```bash
# 检查 iCloud 登录状态
defaults read MobileMeAccounts Accounts

# 或在终端检查
echo $ICLOUD_ACCOUNT
```

### 3. 验证数据保存位置

**检查本地存储：**

```bash
# 查看所有保存的数据
defaults read com.pomodoro.timer

# 查看设置数据（如果存在独立的 settings key）
defaults read com.pomodoro.timer settings 2>/dev/null | xxd -r -p 2>/dev/null || echo "Settings embedded in appData"

# 查看应用状态数据
defaults read com.pomodoro.timer appData 2>/dev/null | xxd -r -p 2>/dev/null || echo "Binary data"
```

**检查 iCloud 存储：**

```bash
# iCloud Key-Value Store 的数据通常不直接可见
# 但可以通过代码日志确认

# 查看最近的 iCloud 相关日志
log show --predicate 'processImagePath contains "PomodoroTimer"' \
  --last 5m --level info 2>/dev/null | grep -i icloud
```

### 4. 测试持久化的完整流程

```bash
#!/bin/bash

echo "=== 番茄钟持久化测试 ==="
echo ""

echo "步骤 1：清除旧数据（可选）"
defaults delete com.pomodoro.timer 2>/dev/null || echo "无旧数据"
echo ""

echo "步骤 2：构建并启动应用"
./kill-app.sh
./build.sh
open ./PomodoroTimer.app
echo "✓ 应用已启动，请配置以下设置："
echo "  - Bark Key: test-key-123"
echo "  - 专注时长: 25 分钟"
echo "  - 启用声音"
echo ""
read -p "配置完成后按 Enter 继续..."

echo ""
echo "步骤 3：验证数据已保存"
echo "本地存储中的数据："
defaults read com.pomodoro.timer 2>/dev/null | head -20
echo ""

echo "步骤 4：重启应用测试持久化"
./kill-app.sh
sleep 2
open ./PomodoroTimer.app
echo "✓ 应用已重启"
echo ""
echo "请打开设置窗口验证配置是否保持"
echo ""
read -p "验证完成后按 Enter 继续..."

echo ""
echo "步骤 5：重新编译测试"
./kill-app.sh
./build.sh
open ./PomodoroTimer.app
echo "✓ 应用已重新编译"
echo ""
echo "请再次打开设置窗口验证配置是否保持"
echo ""

echo "=== 测试完成 ==="
echo "如果所有设置都保持不变，说明持久化工作正常！"
```

### 5. 多设备同步测试（需要两台 Mac）

**设备 A 操作：**
```bash
# 1. 确保已登录 iCloud
# 2. 启动应用，配置设置
# 3. 修改 Bark Key 为 "device-a-test"
# 4. 保存
# 5. 查看日志确认已同步到 iCloud
log show --predicate 'processImagePath contains "PomodoroTimer"' \
  --last 1m | grep -i "已保存.*icloud"
```

**设备 B 操作：**
```bash
# 1. 确保使用相同的 Apple ID 登录 iCloud
# 2. 等待 10-20 秒
# 3. 启动应用
# 4. 打开设置，检查 Bark Key 是否为 "device-a-test"
# 5. 如果是，说明同步成功！
```

**来回测试：**
```bash
# 在设备 A 和设备 B 之间来回修改设置
# 验证双向同步是否正常工作
```

### 6. 离线测试

```bash
# 1. 断开网络连接
sudo ifconfig en0 down  # WiFi
# 或手动在系统设置中关闭

# 2. 修改设置
# 3. 重启应用，验证设置保持（使用本地存储）
# 4. 恢复网络
sudo ifconfig en0 up

# 5. 等待一会儿，检查是否同步到 iCloud
```

## 预期结果

### ✅ 成功的表现

1. **持久化正常：**
   - 应用重启后设置保持
   - 重新编译后设置保持
   - Bark Key 不会丢失

2. **iCloud 同步正常：**
   - 设置窗口显示 "✅ 已启用"
   - 日志中可以看到 "iCloud 同步已启用"
   - 多设备间设置自动同步

3. **离线正常：**
   - 离线时可以修改设置
   - 数据保存在本地
   - 恢复网络后自动同步

### ❌ 可能的问题

1. **设置丢失：**
   - 检查是否正确调用了 saveSettings()
   - 查看日志是否有错误
   - 验证 UserDefaults 是否正常

2. **iCloud 未启用：**
   - 检查是否登录 iCloud
   - 检查 entitlements 配置
   - 查看是否需要代码签名

3. **同步延迟：**
   - iCloud 同步可能需要几秒到几分钟
   - 网络问题可能导致延迟
   - 这是正常现象，不是 bug

## 调试技巧

### 查看详细日志

```bash
# 实时查看应用日志
log stream --predicate 'processImagePath contains "PomodoroTimer"' --level debug

# 查看最近的错误
log show --predicate 'processImagePath contains "PomodoroTimer"' \
  --last 10m --level error

# 搜索特定关键词
log show --predicate 'processImagePath contains "PomodoroTimer"' \
  --last 5m | grep -E "(保存|iCloud|设置)"
```

### 手动检查数据

```bash
# 查看完整的 UserDefaults 数据
defaults read com.pomodoro.timer

# 导出为 plist 文件
defaults export com.pomodoro.timer ~/Desktop/pomodoro-settings.plist

# 查看 plist 文件
plutil -p ~/Desktop/pomodoro-settings.plist
```

### 重置数据（测试用）

```bash
# 完全清除所有数据
defaults delete com.pomodoro.timer

# 清除特定键
defaults delete com.pomodoro.timer settings
defaults delete com.pomodoro.timer appData

# 重新开始测试
```

## 已知限制

1. **iCloud 需要网络：**
   - 首次同步需要网络连接
   - 断网时只能使用本地存储

2. **同步延迟：**
   - iCloud Key-Value Store 的同步由系统控制
   - 不是实时的，可能有延迟

3. **存储限制：**
   - 1MB 总容量（足够使用）
   - 单个键最大 1MB

4. **需要 iCloud 账户：**
   - 用户必须登录 iCloud
   - 开发版本可能需要签名

## 故障排除清单

- [ ] 应用能正常启动
- [ ] 设置窗口可以打开
- [ ] 可以修改设置
- [ ] 重启应用后设置保持
- [ ] 重新编译后设置保持
- [ ] iCloud 状态显示正确
- [ ] 日志中没有错误信息
- [ ] UserDefaults 中有数据
- [ ] （可选）多设备同步正常

## 成功标准

**核心功能：**
✅ Bark Key 和其他设置在重启/重编译后保持不变

**增强功能：**
✅ iCloud 同步状态正确显示
✅ 多设备间自动同步（如果可用）
✅ 离线模式正常工作

如果以上都正常，说明持久化和 iCloud 同步功能已完美实现！
