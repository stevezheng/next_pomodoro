import AppKit
import UserNotifications

/// 系统通知管理器
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() {
        super.init()
        setupNotifications()
    }

    private func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        // 请求通知权限
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                Log.info("通知权限已授予")
            } else if let error = error {
                Log.error("通知权限请求失败: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 发送通知

    /// 发送专注完成通知
    func sendFocusCompleteNotification() {
        sendNotification(
            title: "🍅 专注时间完成",
            body: "该休息了！点击查看选项。",
            identifier: "focus-complete"
        )
    }

    /// 发送休息开始通知
    func sendBreakStartNotification(duration: Int, isLongBreak: Bool) {
        let breakType = isLongBreak ? "长休息" : "休息"
        let icon = isLongBreak ? "🌴" : "☕"
        sendNotification(
            title: "\(icon) \(breakType)时间开始",
            body: "你可以休息 \(duration) 秒。",
            identifier: "break-start"
        )
    }

    /// 发送休息结束通知
    func sendBreakCompleteNotification(completedCount: Int) {
        sendNotification(
            title: "🍅 休息结束",
            body: "已完成 \(completedCount) 个番茄钟。准备好开始下一个了吗？",
            identifier: "break-complete"
        )
    }

    /// 发送推迟警告通知
    func sendSnoozeWarningNotification(snoozeCount: Int) {
        let warnings = ["⚠️ 你还在工作？", "⛔ 最后一次警告！", "🚫 强制休息！"]
        let warningIndex = min(snoozeCount, warnings.count - 1)
        sendNotification(
            title: warnings[warningIndex],
            body: "立即停止工作，休息一下。",
            identifier: "snooze-warning"
        )
    }

    private func sendNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil  // 立即发送
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Log.error("发送通知失败: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// 当应用在前台时也显示通知
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) ->
            Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// 用户点击通知时的处理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        Log.info("用户点击了通知: \(identifier)")

        // 激活应用
        NSApp.activate(ignoringOtherApps: true)

        completionHandler()
    }
}
