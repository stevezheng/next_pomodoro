# Bark 推送配置指南

## 什么是 Bark？

Bark 是一个开源的 iOS 推送通知工具，可以让你的 Mac 应用向 iPhone/iPad 发送推送通知。

## 快速开始

### 1. 安装 Bark App

在 iPhone 或 iPad 上：
1. 打开 App Store
2. 搜索 "Bark - 给自己的推送工具"
3. 下载并安装

### 2. 获取 Bark Key

1. 打开 Bark App
2. 首次打开会自动生成一个 Key
3. 在首页可以看到类似这样的测试 URL：
   ```
   https://api.day.app/aBc123XyZ/测试内容
   ```
4. 其中 `aBc123XyZ` 就是你的 **Bark Key**

### 3. 配置番茄钟

1. 在 Mac 上运行番茄钟应用
2. 点击菜单栏中的番茄图标
3. 选择 "⚙️ 设置"
4. 在设置窗口中：
   - 勾选 "启用 Bark 推送"
   - 在 "Bark Key" 输入框中粘贴你的 Key
   - 点击 "测试" 按钮
5. 检查你的 iPhone 是否收到测试推送
6. 如果收到，点击 "保存" 完成配置

## 推送场景

番茄钟会在以下情况发送 Bark 推送：

### 🍅 番茄完成
- **时机**：当一个番茄钟倒计时结束时
- **标题**：🍅 番茄完成
- **内容**：恭喜！你已完成第 X 个番茄钟
- **声音**：bell

### ☕️ 休息结束
- **时机**：短休息倒计时结束时
- **标题**：☕️ 休息结束
- **内容**：休息结束！准备开始新的番茄钟吧（已完成 X 个）
- **声音**：chime

### 🌴 长休息结束
- **时机**：长休息（每 4 个番茄后）倒计时结束时
- **标题**：🌴 长休息结束
- **内容**：休息结束！准备开始新的番茄钟吧（已完成 X 个）
- **声音**：chime

## 常见问题

### Q: 没有收到推送？

**检查清单：**
1. ✅ 确认 iPhone 连接到互联网
2. ✅ 确认在番茄钟设置中勾选了 "启用 Bark 推送"
3. ✅ 确认 Bark Key 输入正确（没有多余的空格）
4. ✅ 点击 "测试" 按钮验证配置
5. ✅ 检查 Bark App 是否已授予通知权限

### Q: 推送延迟？

Bark 推送依赖网络连接，通常延迟在 1-3 秒。如果延迟较长：
- 检查网络连接质量
- 尝试切换 Wi-Fi 或移动网络

### Q: 可以自定义推送内容吗？

当前版本推送内容是固定的。如果需要自定义，可以修改源代码：
- 文件：`Sources/PomodoroTimer/Notifications/BarkManager.swift`
- 方法：`sendFocusComplete()`, `sendBreakComplete()`

### Q: 可以使用自建 Bark 服务器吗？

可以！在 `BarkManager.swift` 中修改 `baseURL`：

```swift
private let baseURL = "https://your-bark-server.com"  // 改为你的服务器地址
```

### Q: Bark 安全吗？

- Bark 是开源项目，代码透明
- 推送通过 Apple APNs 服务发送
- Key 只在你的设备间传递
- 建议不要分享你的 Bark Key

## 高级功能

Bark 支持更多高级功能，如：
- 自定义声音
- 推送图片
- 跳转 URL
- 推送分组
- 推送加密

查看 Bark 官方文档了解更多：https://bark.day.app

## 相关链接

- **Bark 官网**：https://bark.day.app
- **Bark GitHub**：https://github.com/Finb/Bark
- **服务端部署**：https://github.com/Finb/bark-server

## 反馈

如果遇到问题或有建议，请通过以下方式反馈：
- GitHub Issues
- 项目内日志：查看 `~/Library/Logs/PomodoroTimer/` 目录
