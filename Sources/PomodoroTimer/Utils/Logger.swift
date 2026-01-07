import Foundation
import os.log

/// 日志级别
enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// 简单的日志工具
class Log {
    static let subsystem = "com.pomodoro.timer"
    static let category = "PomodoroTimer"

    static let logger = OSLog(subsystem: subsystem, category: category)

    /// 当前日志级别（debug 模式下输出所有日志，release 模式下只输出 warning 及以上）
    #if DEBUG
        static var minLevel: LogLevel = .debug
    #else
        static var minLevel: LogLevel = .warning
    #endif

    /// 是否启用文件日志
    static var fileLoggingEnabled: Bool = false

    /// 日志文件路径
    private static var logFileURL: URL? {
        let fileManager = FileManager.default
        guard
            let appSupport = fileManager.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first
        else {
            return nil
        }
        let logDir = appSupport.appendingPathComponent("PomodoroTimer/Logs")
        try? fileManager.createDirectory(at: logDir, withIntermediateDirectories: true)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())

        return logDir.appendingPathComponent("pomodoro-\(dateString).log")
    }

    static func debug(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        log(level: .debug, message: message, file: file, function: function, line: line)
    }

    static func info(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }

    static func warning(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }

    static func error(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        log(level: .error, message: message, file: file, function: function, line: line)
    }

    private static func log(
        level: LogLevel, message: String, file: String, function: String, line: Int
    ) {
        guard level >= minLevel else { return }

        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(levelString(level))] [\(fileName):\(line)] \(function) - \(message)"

        // 输出到系统日志
        let osLogType: OSLogType
        switch level {
        case .debug: osLogType = .debug
        case .info: osLogType = .info
        case .warning: osLogType = .default
        case .error: osLogType = .error
        }
        os_log("%{public}@", log: logger, type: osLogType, logMessage)

        // 输出到控制台（debug 模式）
        #if DEBUG
            print(logMessage)
        #endif

        // 写入文件
        if fileLoggingEnabled {
            writeToFile(logMessage)
        }
    }

    private static func levelString(_ level: LogLevel) -> String {
        switch level {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARN"
        case .error: return "ERROR"
        }
    }

    private static func writeToFile(_ message: String) {
        guard let fileURL = logFileURL else { return }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = dateFormatter.string(from: Date())

        let logLine = "[\(timestamp)] \(message)\n"

        if let data = logLine.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let handle = try? FileHandle(forWritingTo: fileURL) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                try? data.write(to: fileURL)
            }
        }
    }

    /// 配置日志系统
    static func configure(minLevel: LogLevel, enableFileLogging: Bool) {
        self.minLevel = minLevel
        self.fileLoggingEnabled = enableFileLogging
    }
}
