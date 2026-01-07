#!/bin/bash

# 番茄钟 macOS 原生应用构建脚本

set -e

echo "🍅 构建番茄钟 macOS 原生应用..."

# 清理旧构建
echo "清理旧构建..."
rm -rf .build
rm -rf PomodoroTimer.app

# 使用 Swift Package Manager 构建
echo "编译应用..."
swift build -c release --product PomodoroTimer

# 创建 App Bundle
echo "创建 App Bundle..."
mkdir -p PomodoroTimer.app/Contents/MacOS
mkdir -p PomodoroTimer.app/Contents/Resources

# 复制可执行文件
cp .build/release/PomodoroTimer PomodoroTimer.app/Contents/MacOS/

# 复制 Info.plist
cp Resources/Info.plist PomodoroTimer.app/Contents/

# 复制应用图标
cp Resources/AppIcon.icns PomodoroTimer.app/Contents/Resources/

# 设置可执行权限
chmod +x PomodoroTimer.app/Contents/MacOS/PomodoroTimer

echo "✅ 构建完成！"
echo "应用位置: PomodoroTimer.app"
echo ""
echo "运行应用："
echo "  open PomodoroTimer.app"
