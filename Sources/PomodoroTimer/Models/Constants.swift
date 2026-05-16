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
        let longBreak = "🌴"
    }

    /// 持久化存储 Key
    enum StorageKey {
        static let appData = "appData"
        static let timerState = "timerState"
        static let completedPomodoros = "completedPomodoros"
        static let settings = "settings"
        static let todayPomodoros = "todayPomodoros"
        static let lastResetDate = "lastResetDate"
    }

    /// 更新频率
    static let updateInterval: TimeInterval = 1.0  // 每秒更新一次

    /// 最大推迟次数
    static let maxSnoozeCount = 3

    /// 长休息触发条件（每完成多少个番茄后触发长休息）
    static let longBreakInterval = 4

    /// 休息结束后未开始下一轮番茄的默认提醒间隔
    static let idleReminderDefaultInterval = 3

    /// 休息后提醒最小间隔
    static let idleReminderMinimumInterval = 1

    // MARK: - 推迟相关常量

    /// 推迟惩罚比例：每 N 秒推迟增加 1 秒休息（测试模式）
    static let snoozePenaltyRatioTest = 5

    /// 推迟惩罚比例：每 N 秒推迟增加 M 秒休息（正常模式）
    /// 正常模式：每 5 分钟(300秒)推迟增加 1 分钟(60秒)休息
    static let snoozePenaltySecondsNormal = 300
    static let snoozePenaltyBonusSecondsNormal = 60

    /// 推迟时间选项（秒）
    enum SnoozeDuration {
        static let short = 5      // 测试模式 5 秒，正常模式 5 分钟
        static let medium = 10    // 测试模式 10 秒，正常模式 10 分钟
        static let long = 15      // 测试模式 15 秒，正常模式 15 分钟
    }

    /// 正常模式下的分钟转秒数
    static let secondsPerMinute = 60
}
