import os.log

/// 简单的日志工具
class Log {
    static let subsystem = "com.pomodoro.timer"
    static let category = "PomodoroTimer"

    static let logger = OSLog(subsystem: subsystem, category: category)

    static func debug(_ message: String) {
        os_log("%{public}@", log: logger, type: .debug, message)
    }

    static func info(_ message: String) {
        os_log("%{public}@", log: logger, type: .info, message)
    }

    static func error(_ message: String) {
        os_log("%{public}@", log: logger, type: .error, message)
    }
}
