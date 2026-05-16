import Foundation

/// Bark 推送管理器
class BarkManager {
    static let shared = BarkManager()

    private var isEnabled: Bool = false
    private var barkKey: String = ""
    private let baseURL = "https://api.day.app"

    private init() {}

    /// 配置 Bark
    func configure(enabled: Bool, key: String) {
        self.isEnabled = enabled
        self.barkKey = key.trimmingCharacters(in: .whitespacesAndNewlines)

        Log.info("Bark 配置更新 - 启用: \(enabled), Key: \(key.isEmpty ? "未设置" : "已设置")")
    }

    /// 发送番茄完成通知
    func sendFocusComplete(count: Int) {
        guard isEnabled, !barkKey.isEmpty else {
            Log.debug("Bark 未启用或 Key 未设置，跳过推送")
            return
        }

        let title = "🍅 番茄完成"
        let body = "恭喜！你已完成第 \(count) 个番茄钟"
        let sound = "bell"

        sendNotification(title: title, body: body, sound: sound, group: "pomodoro")
    }

    /// 发送休息完成通知
    func sendBreakComplete(count: Int, isLongBreak: Bool) {
        guard isEnabled, !barkKey.isEmpty else {
            Log.debug("Bark 未启用或 Key 未设置，跳过推送")
            return
        }

        let title = isLongBreak ? "🌴 长休息结束" : "☕️ 休息结束"
        let body = "休息结束！准备开始新的番茄钟吧（已完成 \(count) 个）"
        let sound = "chime"

        sendNotification(title: title, body: body, sound: sound, group: "pomodoro")
    }

    /// 发送空闲提醒
    func sendIdleReminder() {
        guard isEnabled, !barkKey.isEmpty else { return }

        sendNotification(
            title: "🍅 还没有开始番茄钟",
            body: "休息已经结束，记得开始下一轮专注。",
            sound: "bell",
            group: "pomodoro"
        )
    }

    /// 发送推迟警告通知
    func sendSnoozeWarning(count: Int) {
        guard isEnabled, !barkKey.isEmpty else { return }

        let title = "⏰ 推迟时间到"
        let body = "推迟时间已结束，是否开始休息？（已推迟 \(count) 次）"
        let sound = "alarm"

        sendNotification(
            title: title, body: body, sound: sound, level: "timeSensitive", group: "pomodoro")
    }

    /// 发送通用 Bark 通知
    private func sendNotification(
        title: String,
        body: String,
        sound: String? = nil,
        level: String = "active",
        group: String = "default"
    ) {
        // 构建 POST 请求
        guard let url = URL(string: "\(baseURL)/push") else {
            Log.error("无效的 Bark URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        // 构建请求体
        var params: [String: Any] = [
            "device_key": barkKey,
            "title": title,
            "body": body,
            "level": level,
            "group": group,
            "isArchive": "1",  // 保存推送记录
        ]

        if let sound = sound {
            params["sound"] = sound
        }

        // 转换为 JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: params) else {
            Log.error("无法序列化 Bark 请求参数")
            return
        }

        request.httpBody = jsonData

        // 发送请求
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Log.error("Bark 推送失败: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    Log.info("Bark 推送成功: \(title)")
                } else {
                    Log.warning("Bark 推送响应异常: HTTP \(httpResponse.statusCode)")
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        Log.debug("响应内容: \(responseString)")
                    }
                }
            }
        }

        task.resume()
    }

    /// 测试 Bark 推送
    func testNotification() {
        guard !barkKey.isEmpty else {
            Log.warning("Bark Key 未设置，无法测试")
            return
        }

        sendNotification(
            title: "🍅 番茄钟测试",
            body: "Bark 推送配置成功！",
            sound: "bell",
            group: "pomodoro"
        )
    }
}
