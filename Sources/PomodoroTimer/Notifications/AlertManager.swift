import AppKit

/// 弹窗提醒管理器
class AlertManager {

    // MARK: - 专注完成提醒

    static func showFocusComplete(snoozeCount: Int, response: @escaping (SnoozeResponse) -> Void) {
        Log.debug("显示专注完成弹窗，推迟次数: \(snoozeCount)")

        DispatchQueue.main.async {
            let alert = NSAlert()

            // 添加按钮
            alert.addButton(withTitle: "开始休息")

            if snoozeCount < Constants.maxSnoozeCount {
                alert.addButton(withTitle: "推迟 5 秒")
                alert.addButton(withTitle: "推迟 10 秒")
                alert.addButton(withTitle: "推迟 15 秒")
            }

            // 设置弹窗属性
            alert.messageText = self.getMessageText(for: snoozeCount)
            alert.informativeText = self.getInformativeText(for: snoozeCount)
            alert.alertStyle = .warning
            alert.icon = self.getIcon(for: snoozeCount)

            // 强制弹窗显示在最前面
            alert.window.level = NSWindow.Level.floating
            NSApp.activate(ignoringOtherApps: true)

            Log.debug("弹窗即将显示，窗口级别: \(alert.window.level.rawValue)")

            let responseCode = alert.runModal()

            Log.debug("用户响应: \(responseCode.rawValue)")

            let result: SnoozeResponse
            // NSAlert 返回值从 1000 开始，对应按钮索引
            switch responseCode.rawValue {
            case 1000:  // 第一个按钮
                result = .startBreak
            case 1001:  // 第二个按钮
                result = .snooze(5)
            case 1002:  // 第三个按钮
                result = .snooze(10)
            case 1003:  // 第四个按钮
                result = .snooze(15)
            default:
                Log.error("未知的响应代码: \(responseCode.rawValue)")
                result = .startBreak
            }

            Log.debug("最终结果: \(result)")
            response(result)
        }
    }

    // MARK: - 推迟时间结束提醒

    static func showSnoozeTimeUp(snoozeCount: Int, response: @escaping (SnoozeResponse) -> Void) {
        showFocusComplete(snoozeCount: snoozeCount, response: response)
    }

    // MARK: - 休息开始提醒

    static func showBreakStart(breakDuration: Int, isLongBreak: Bool = false) {
        Log.debug("显示休息开始弹窗 - 休息时长: \(breakDuration)秒, 是否长休息: \(isLongBreak)")
        DispatchQueue.main.async {
            let alert = NSAlert()
            let breakType = isLongBreak ? "长休息" : "休息"
            let icon = isLongBreak ? Constants.icons.longBreak : Constants.icons.breakTime
            alert.messageText = "\(breakType)时间到！"
            alert.informativeText = "你可以休息 \(breakDuration) 秒。\(isLongBreak ? "🎉 恭喜完成一个周期！" : "")"
            alert.alertStyle = .informational
            alert.icon = icon.toImage()
            alert.addButton(withTitle: "好的")
            alert.window.level = NSWindow.Level.floating
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }

    // MARK: - 休息结束提醒

    static func showBreakComplete(completedCount: Int) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "休息结束"
            alert.informativeText = "已完成 \(completedCount) 个番茄钟。准备好开始下一个了吗？"
            alert.alertStyle = .informational
            alert.icon = Constants.icons.idle.toImage()
            alert.addButton(withTitle: "好的")
            alert.window.level = NSWindow.Level.floating
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }

    // MARK: - 辅助方法

    private static func getMessageText(for snoozeCount: Int) -> String {
        switch snoozeCount {
        case 0:
            return "专注时间完成"
        case 1:
            return "你还在工作？"
        case 2:
            return "最后一次警告！"
        case 3:
            return "强制休息！"
        default:
            return "休息时间到！"
        }
    }

    private static func getInformativeText(for snoozeCount: Int) -> String {
        switch snoozeCount {
        case 0:
            return "该休息了"
        case 1:
            return "立即停止工作，休息一下"
        case 2:
            return "这是最后一次推迟机会"
        case 3:
            return "你已经推迟太久了，现在必须休息"
        default:
            return ""
        }
    }

    private static func getIcon(for snoozeCount: Int) -> NSImage? {
        let iconString: String
        switch snoozeCount {
        case 0:
            iconString = Constants.icons.focus
        case 1:
            iconString = Constants.icons.warning
        case 2:
            iconString = Constants.icons.stop
        case 3:
            iconString = Constants.icons.stop
        default:
            iconString = Constants.icons.idle
        }
        return iconString.toImage()
    }
}

// MARK: - 推迟响应

enum SnoozeResponse {
    case startBreak
    case snooze(Int)  // 推迟秒数
}
