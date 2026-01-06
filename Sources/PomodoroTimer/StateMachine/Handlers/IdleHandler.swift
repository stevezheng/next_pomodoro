import Foundation

class IdleHandler: StateHandler {
    func handle(_ event: EventType, in context: StateMachineContext) -> TimerState {
        switch event {
        case .start:
            // 开始专注
            let focusContext = FocusContext(
                remainingSeconds: context.settings.focusDuration,
                totalSeconds: context.settings.focusDuration,
                isPaused: false,
                completedPomodoros: context.completedPomodoros
            )
            return .focus(focusContext)

        case .stop:
            return .idle

        default:
            return context.currentState
        }
    }
}
