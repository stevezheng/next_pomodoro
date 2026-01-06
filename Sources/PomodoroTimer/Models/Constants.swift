import Foundation

enum Constants {
    /// Menu Bar 图标
    static let icons = Icons()

    struct Icons {
        let idle = "🍅"
        let focus = "🍅"
        let snooze = "⛔"
        let breakTime = "☕"
        let warning = "⚠️"
        let stop = "🚫"
    }

    /// 持久化存储 Key
    enum StorageKey {
        static let appData = "appData"
        static let timerState = "timerState"
        static let completedPomodoros = "completedPomodoros"
        static let settings = "settings"
    }

    /// 更新频率
    static let updateInterval: TimeInterval = 1.0  // 每秒更新一次

    /// 最大推迟次数
    static let maxSnoozeCount = 3
}
