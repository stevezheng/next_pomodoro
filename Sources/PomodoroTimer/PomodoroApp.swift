import AppKit
import Foundation

/// 番茄钟主应用
class PomodoroApp: NSObject {
    private var stateMachine: StateMachine!
    private var timer: PreciseTimer!
    private var menuBarManager: MenuBarManager!
    private var persistenceManager: PersistenceManager!

    private var currentSnoozeDeadline: DispatchWorkItem?

    override init() {
        super.init()
        setupCore()
        setupPersistence()
    }

    private func setupCore() {
        stateMachine = StateMachine()
        timer = PreciseTimer()
        menuBarManager = MenuBarManager()
        persistenceManager = PersistenceManager()

        menuBarManager.configure(with: stateMachine)

        // 监听状态变化
        stateMachine.onStateChanged = { [weak self] state in
            self?.handleStateChange(to: state)
        }

        stateMachine.onPomodorosUpdated = { [weak self] count in
            self?.saveState()
        }
    }

    private func setupPersistence() {
        // 尝试恢复上次的状态
        if let (state, pomodoros, _) = persistenceManager.loadAppState() {
            stateMachine.restoreState(state, pomodoros: pomodoros)

            // 如果是计时状态，恢复计时
            if case .focus(let ctx) = state, !ctx.isPaused {
                startFocusTimer(remainingSeconds: ctx.remainingSeconds)
            } else if case .breakTime(let ctx) = state, !ctx.isPaused {
                startBreakTimer(remainingSeconds: ctx.remainingSeconds)
            }
        }
    }

    // MARK: - 状态变化处理

    private func handleStateChange(to newState: TimerState) {
        let oldState = stateMachine.getContext()

        // 检测是否是暂停/恢复事件
        if case .focus(let newCtx) = newState {
            if case .focus(let oldCtx) = oldState {
                // 检测暂停
                if !oldCtx.isPaused && newCtx.isPaused {
                    timer.stop()
                    saveState()
                    return
                }
                // 检测恢复
                if oldCtx.isPaused && !newCtx.isPaused {
                    startFocusTimer(remainingSeconds: newCtx.remainingSeconds)
                    return
                }
            }
        } else if case .breakTime(let newCtx) = newState {
            if case .breakTime(let oldCtx) = oldState {
                // 检测暂停
                if !oldCtx.isPaused && newCtx.isPaused {
                    timer.stop()
                    saveState()
                    return
                }
                // 检测恢复
                if oldCtx.isPaused && !newCtx.isPaused {
                    startBreakTimer(remainingSeconds: newCtx.remainingSeconds)
                    return
                }
            }
        }

        // 状态转换，停止当前计时器
        timer.stop()
        currentSnoozeDeadline?.cancel()

        switch newState {
        case .idle:
            saveState()

        case .focus(let ctx):
            if !ctx.isPaused {
                startFocusTimer(remainingSeconds: ctx.remainingSeconds)
            }

        case .snooze(let ctx):
            handleSnoozeState(ctx)

        case .breakTime(let ctx):
            if !ctx.isPaused {
                startBreakTimer(remainingSeconds: ctx.remainingSeconds)
            }
        }

        saveState()
    }

    // MARK: - 计时器管理

    private func startFocusTimer(remainingSeconds: Int) {
        timer.start(
            durationSeconds: remainingSeconds,
            onTick: { [weak self] remaining in
                self?.updateFocusTime(remaining)
            },
            onComplete: { [weak self] in
                self?.stateMachine?.handle(.timeUp)
            }
        )
    }

    private func startBreakTimer(remainingSeconds: Int) {
        timer.start(
            durationSeconds: remainingSeconds,
            onTick: { [weak self] remaining in
                self?.updateBreakTime(remaining)
            },
            onComplete: { [weak self] in
                self?.handleBreakComplete()
            }
        )
    }

    private func startSnoozeTimer(seconds: Int) {
        currentSnoozeDeadline?.cancel()

        let deadline = DispatchWorkItem { [weak self] in
            self?.stateMachine?.handle(.timeUp)
        }

        currentSnoozeDeadline = deadline
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(seconds), execute: deadline)
    }

    // MARK: - 时间更新

    private func updateFocusTime(_ remaining: Int) {
        guard case .focus(var ctx) = stateMachine.getContext() else { return }
        ctx.remainingSeconds = remaining
        // 触发 UI 更新
        stateMachine.onStateChanged?(.focus(ctx))
    }

    private func updateBreakTime(_ remaining: Int) {
        guard case .breakTime(var ctx) = stateMachine.getContext() else { return }
        ctx.remainingSeconds = remaining
        // 触发 UI 更新
        stateMachine.onStateChanged?(.breakTime(ctx))
    }

    // MARK: - 推迟状态处理

    private func handleSnoozeState(_ ctx: SnoozeContext) {
        if ctx.snoozeCount < Constants.maxSnoozeCount {
            // 显示推迟选择弹窗
            showSnoozeAlert(snoozeCount: ctx.snoozeCount)
        } else {
            // 强制开始休息
            showForceBreakAlert()
        }
    }

    private func showSnoozeAlert(snoozeCount: Int) {
        AlertManager.showFocusComplete(snoozeCount: snoozeCount) { [weak self] response in
            switch response {
            case .startBreak:
                self?.stateMachine?.handle(.startBreak)
            case .snooze(let seconds):
                self?.stateMachine?.handle(.snooze(seconds))
                self?.startSnoozeTimer(seconds: seconds)
            }
        }
    }

    private func showForceBreakAlert() {
        let alert = NSAlert()
        alert.messageText = "强制休息！"
        alert.informativeText = "你已经达到最大推迟次数，必须休息！"
        alert.alertStyle = .critical
        alert.addButton(withTitle: "开始休息")
        alert.runModal()

        stateMachine?.handle(.timeUp)
    }

    private func handleBreakComplete() {
        let completedCount = stateMachine.completedPomodoros
        AlertManager.showBreakComplete(completedCount: completedCount)
        stateMachine?.handle(.timeUp)
    }

    // MARK: - 持久化

    private func saveState() {
        let state = stateMachine.getContext()
        let pomodoros = stateMachine.completedPomodoros
        let settings = Settings.default
        persistenceManager.saveAppState(state: state, pomodoros: pomodoros, settings: settings)
    }
}
