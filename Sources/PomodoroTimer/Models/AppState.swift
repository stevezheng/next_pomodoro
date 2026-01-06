import Foundation

// MARK: - 应用状态
enum TimerState: Equatable, Hashable, Codable {
    case idle
    case focus(FocusContext)
    case snooze(SnoozeContext)
    case breakTime(BreakContext)

    var displayName: String {
        switch self {
        case .idle: return "空闲"
        case .focus: return "专注中"
        case .snooze: return "推迟中"
        case .breakTime: return "休息中"
        }
    }

    var isPaused: Bool {
        switch self {
        case .focus(let ctx): return ctx.isPaused
        case .breakTime(let ctx): return ctx.isPaused
        default: return false
        }
    }
}

// MARK: - 状态上下文
struct FocusContext: Equatable, Hashable, Codable {
    var remainingSeconds: Int
    var totalSeconds: Int
    var isPaused: Bool = false
    var completedPomodoros: Int
}

struct SnoozeContext: Equatable, Hashable, Codable {
    var accumulatedSeconds: Int
    var snoozeCount: Int
    var maxSnoozeCount: Int = 3
    var completedPomodoros: Int
    var focusTotalSeconds: Int
}

struct BreakContext: Equatable, Hashable, Codable {
    var remainingSeconds: Int
    var totalSeconds: Int
    var isPaused: Bool = false
    var completedPomodoros: Int
}

// MARK: - 事件类型
enum EventType {
    case start
    case stop
    case pause
    case resume
    case timeUp
    case snooze(Int)  // 推迟秒数
    case startBreak
    case interrupt    // 打断（被外部因素中断）
}

// MARK: - 应用数据
struct AppData: Codable {
    var timerState: TimerState
    var completedPomodoros: Int
    var settings: Settings

    static let empty = AppData(
        timerState: .idle,
        completedPomodoros: 0,
        settings: Settings()
    )
}

// MARK: - 设置
struct Settings: Codable, Equatable {
    var focusDuration: Int      // 番茄时长（秒）
    var baseBreakDuration: Int  // 基础休息时长（秒）
    var testMode: Bool          // 测试模式

    static let `default` = Settings()

    init(
        focusDuration: Int = 25,
        baseBreakDuration: Int = 5,
        testMode: Bool = true
    ) {
        // 根据测试模式调整时长
        self.testMode = testMode
        self.focusDuration = testMode ? focusDuration : focusDuration * 60
        self.baseBreakDuration = testMode ? baseBreakDuration : baseBreakDuration * 60
    }

    /// 获取推迟选项（秒）
    var snoozeOptions: [Int] {
        testMode ? [5, 10, 15] : [5 * 60, 10 * 60, 15 * 60]
    }

    /// 计算休息时间（含惩罚）
    func calculateBreakDuration(snoozeSeconds: Int) -> Int {
        let penalty = testMode ? snoozeSeconds / 5 : snoozeSeconds / 300
        return baseBreakDuration + penalty
    }
}
