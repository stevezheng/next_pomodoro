import Foundation

class FocusHandler: StateHandler {
    func handle(_ event: EventType, in context: StateMachineContext) -> TimerState {
        guard case .focus(let focusCtx) = context.currentState else {
            return context.currentState
        }

        switch event {
        case .timeUp:
            // 专注时间结束，进入推迟状态
            let snoozeContext = SnoozeContext(
                accumulatedSeconds: 0,
                snoozeCount: 0,
                completedPomodoros: focusCtx.completedPomodoros,
                focusTotalSeconds: focusCtx.totalSeconds
            )
            return .snooze(snoozeContext)

        case .stop:
            // 手动停止，不增加完成数
            return .idle

        case .interrupt:
            // 被打断，不增加完成数
            return .idle

        case .pause:
            // 暂停
            var pausedCtx = focusCtx
            pausedCtx.isPaused = true
            return .focus(pausedCtx)

        case .resume:
            // 恢复
            var resumedCtx = focusCtx
            resumedCtx.isPaused = false
            return .focus(resumedCtx)

        default:
            return context.currentState
        }
    }
}
