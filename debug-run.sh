#!/bin/bash

# 调试运行脚本

echo "🐛 启动调试模式..."
echo ""

# 构建
swift build

echo ""
echo "📝 查看 console 日志："
echo "  log stream --predicate 'processImagePath contains \"PomodoroTimer\"'"
echo ""

# 运行应用
.build/debug/PomodoroTimer
