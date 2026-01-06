import Foundation

class SnoozeHandler: StateHandler {
    func handle(_ event: EventType, in context: StateMachineContext) -> TimerState {
        guard case .snooze(let snoozeCtx) = context.currentState else {
            return context.currentState
        }

        switch event {
        case .snooze(let seconds):
            // 增加推迟时间
            var newCtx = snoozeCtx
            newCtx.accumulatedSeconds += seconds
            newCtx.snoozeCount += 1
            return .snooze(newCtx)

        case .timeUp:
            // 推迟时间结束
            if snoozeCtx.snoozeCount < Constants.maxSnoozeCount {
                // 还可以继续推迟，保持当前状态
                return context.currentState
            } else {
                // 达到最大推迟次数，强制开始休息
                let breakDuration = context.settings.calculateBreakDuration(
                    snoozeSeconds: snoozeCtx.accumulatedSeconds
                )
                let breakContext = BreakContext(
                    remainingSeconds: breakDuration,
                    totalSeconds: breakDuration,
                    isPaused: false,
                    completedPomodoros: snoozeCtx.completedPomodoros
                )
                return .breakTime(breakContext)
            }

        case .startBreak:
            // 用户主动开始休息
            let breakDuration = context.settings.calculateBreakDuration(
                snoozeSeconds: snoozeCtx.accumulatedSeconds
            )
            let breakContext = BreakContext(
                remainingSeconds: breakDuration,
                totalSeconds: breakDuration,
                isPaused: false,
                completedPomodoros: snoozeCtx.completedPomodoros
            )
            return .breakTime(breakContext)

        case .stop:
            // 取消推迟，回到空闲状态
            return .idle

        default:
            return context.currentState
        }
    }
}
