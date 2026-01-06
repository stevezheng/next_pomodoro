#!/bin/bash

# 生成 Xcode 项目

echo "📦 生成 Xcode 项目..."

# 生成 Xcode 项目
swift package generate-xcodeproj

echo "✅ Xcode 项目已生成！"
echo ""
echo "使用 Xcode 打开："
echo "  open PomodoroTimer.xcodeproj"
echo ""
echo "然后在 Xcode 中："
echo "  1. 选择 PomodoroTimer scheme"
echo "  2. 点击 ▶️ 运行按钮或按 Cmd+R"
echo "  3. 设置断点进行调试"
