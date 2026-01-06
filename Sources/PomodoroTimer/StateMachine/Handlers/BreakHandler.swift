import Foundation

class BreakHandler: StateHandler {
    func handle(_ event: EventType, in context: StateMachineContext) -> TimerState {
        guard case .breakTime(let breakCtx) = context.currentState else {
            return context.currentState
        }

        switch event {
        case .timeUp:
            // 休息结束，增加完成番茄数
            let newCount = breakCtx.completedPomodoros + 1
            context.updatePomodoros(newCount)
            return .idle

        case .stop:
            // 提前结束休息，也计入完成
            let newCount = breakCtx.completedPomodoros + 1
            context.updatePomodoros(newCount)
            return .idle

        case .pause:
            // 暂停休息
            var pausedCtx = breakCtx
            pausedCtx.isPaused = true
            return .breakTime(pausedCtx)

        case .resume:
            // 恢复休息
            var resumedCtx = breakCtx
            resumedCtx.isPaused = false
            return .breakTime(resumedCtx)

        default:
            return context.currentState
        }
    }
}
