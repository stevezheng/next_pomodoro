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
    var isLongBreak: Bool = false  // 是否为长休息
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
    case interrupt  // 打断（被外部因素中断）
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
    var focusDuration: Int  // 番茄时长（秒）
    var baseBreakDuration: Int  // 基础休息时长（秒）
    var longBreakDuration: Int  // 长休息时长（秒）
    var longBreakInterval: Int  // 每多少个番茄后触发长休息
    var testMode: Bool  // 测试模式
    var soundEnabled: Bool  // 是否启用声音
    var soundVolume: Float  // 声音音量 (0.0 - 1.0)
    var barkEnabled: Bool  // 是否启用 Bark 推送
    var barkKey: String  // Bark 推送 Key

    static let `default` = Settings()

    init(
        focusDuration: Int = 25,
        baseBreakDuration: Int = 5,
        longBreakDuration: Int = 15,
        longBreakInterval: Int = 4,
        testMode: Bool = true,
        soundEnabled: Bool = true,
        soundVolume: Float = 0.8,
        barkEnabled: Bool = false,
        barkKey: String = ""
    ) {
        // 根据测试模式调整时长
        self.testMode = testMode
        self.focusDuration = testMode ? focusDuration : focusDuration * 60
        self.baseBreakDuration = testMode ? baseBreakDuration : baseBreakDuration * 60
        self.longBreakDuration = testMode ? longBreakDuration : longBreakDuration * 60
        self.longBreakInterval = longBreakInterval
        self.soundEnabled = soundEnabled
        self.soundVolume = soundVolume
        self.barkEnabled = barkEnabled
        self.barkKey = barkKey
    }

    /// 获取推迟选项（秒）
    var snoozeOptions: [Int] {
        testMode ? [5, 10, 15] : [5 * 60, 10 * 60, 15 * 60]
    }

    /// 计算休息时间（含额外休息奖励）
    /// 规则：总休息时间 = 基础休息 + (累计推迟时间 ÷ 5)
    func calculateBreakDuration(snoozeSeconds: Int, isLongBreak: Bool = false) -> Int {
        let baseDuration = isLongBreak ? longBreakDuration : baseBreakDuration
        // 测试模式：每5秒推迟增加1秒休息
        // 正常模式：每5分钟(300秒)推迟增加1分钟(60秒)休息
        let bonus = testMode ? (snoozeSeconds / 5) : (snoozeSeconds / 300) * 60
        return baseDuration + bonus
    }
}
