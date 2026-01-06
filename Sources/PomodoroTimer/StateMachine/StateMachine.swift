import Foundation

// MARK: - 状态机协议
protocol StateHandler {
    func handle(_ event: EventType, in context: StateMachineContext) -> TimerState
}

// MARK: - 状态机上下文
class StateMachineContext {
    fileprivate(set) var currentState: TimerState
    fileprivate(set) var settings: Settings
    fileprivate(set) var completedPomodoros: Int

    var onStateChanged: ((TimerState) -> Void)?
    var onPomodorosUpdated: ((Int) -> Void)?

    init(
        initialState: TimerState = .idle,
        settings: Settings = .default,
        completedPomodoros: Int = 0
    ) {
        self.currentState = initialState
        self.settings = settings
        self.completedPomodoros = completedPomodoros
    }

    func transition(to newState: TimerState) {
        currentState = newState
        onStateChanged?(newState)
    }

    func updatePomodoros(_ count: Int) {
        completedPomodoros = count
        onPomodorosUpdated?(count)
    }

    func updateSettings(_ settings: Settings) {
        self.settings = settings
    }
}

// MARK: - 状态机
class StateMachine {
    private var context: StateMachineContext
    private var handlers: [TimerState: StateHandler] = [:]

    var onStateChanged: ((TimerState) -> Void)? {
        get { context.onStateChanged }
        set { context.onStateChanged = newValue }
    }

    var onPomodorosUpdated: ((Int) -> Void)? {
        get { context.onPomodorosUpdated }
        set { context.onPomodorosUpdated = newValue }
    }

    var currentState: TimerState {
        context.currentState
    }

    var completedPomodoros: Int {
        context.completedPomodoros
    }

    init(settings: Settings = .default) {
        self.context = StateMachineContext(settings: settings)
        setupHandlers()
    }

    private func setupHandlers() {
        handlers = [
            .idle: IdleHandler(),
            .focus(FocusContext(remainingSeconds: 0, totalSeconds: 0, completedPomodoros: 0)): FocusHandler(),
            .snooze(SnoozeContext(accumulatedSeconds: 0, snoozeCount: 0, completedPomodoros: 0, focusTotalSeconds: 0)): SnoozeHandler(),
            .breakTime(BreakContext(remainingSeconds: 0, totalSeconds: 0, completedPomodoros: 0)): BreakHandler()
        ]
    }

    func handle(_ event: EventType) {
        let newState = handler(for: context.currentState).handle(event, in: context)
        context.transition(to: newState)
    }

    func getContext() -> TimerState {
        context.currentState
    }

    func restoreState(_ state: TimerState, pomodoros: Int) {
        context.currentState = state
        context.completedPomodoros = pomodoros
        onStateChanged?(state)
        onPomodorosUpdated?(pomodoros)
    }

    private func handler(for state: TimerState) -> StateHandler {
        switch state {
        case .idle:
            return handlers[.idle]!
        case .focus:
            return handlers[.focus(FocusContext(remainingSeconds: 0, totalSeconds: 0, completedPomodoros: 0)) ]!
        case .snooze:
            return handlers[.snooze(SnoozeContext(accumulatedSeconds: 0, snoozeCount: 0, completedPomodoros: 0, focusTotalSeconds: 0)) ]!
        case .breakTime:
            return handlers[.breakTime(BreakContext(remainingSeconds: 0, totalSeconds: 0, completedPomodoros: 0)) ]!
        }
    }
}
