#!/bin/bash

# 查看应用日志脚本

echo "📋 查看 PomodoroTimer 日志..."
echo ""

# 实时查看日志
log stream --predicate 'subsystem == "com.pomodoro.timer"' --level debug
