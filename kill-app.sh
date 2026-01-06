#!/bin/bash

# 快速关闭应用脚本

echo "🛑 关闭 PomodoroTimer..."

# 尝试优雅关闭
killall PomodoroTimer 2>/dev/null

# 等待 1 秒
sleep 1

# 如果还在运行，强制关闭
if pgrep -x "PomodoroTimer" > /dev/null; then
    echo "强制关闭..."
    killall -9 PomodoroTimer
fi

echo "✅ 应用已关闭"
