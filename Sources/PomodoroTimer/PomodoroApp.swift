import AppKit
import Foundation

/// 番茄钟主应用
class PomodoroApp: NSObject {
    private var stateMachine: StateMachine!
    private var timer: PreciseTimer!
    private var menuBarManager: MenuBarManager!
    private var persistenceManager: PersistenceManager!
    private var soundManager: SoundManager!

    private var currentSnoozeDeadline: DispatchWorkItem?
    private var snoozeTimer: PreciseTimer?  // 用于推迟期间的倒计时显示
    private var settingsWindowController: SettingsWindowController?

    override init() {
        super.init()
        setupCore()
        setupPersistence()
    }

    private func setupCore() {
        // 先加载设置
        persistenceManager = PersistenceManager()
        let savedSettings = persistenceManager.loadSettings() ?? Settings.default

        Log.info(
            "加载设置 - baseBreakDuration: \(savedSettings.baseBreakDuration)秒, testMode: \(savedSettings.testMode)"
        )

        // 使用加载的设置初始化状态机
        stateMachine = StateMachine(settings: savedSettings)
        timer = PreciseTimer()
        menuBarManager = MenuBarManager()
        soundManager = SoundManager.shared

        menuBarManager.configure(with: stateMachine, persistenceManager: persistenceManager)

        // 设置打开设置窗口回调
        menuBarManager.onOpenSettings = { [weak self] in
            self?.openSettings()
        }

        // 配置声音和 Bark
        soundManager.configure(
            enabled: savedSettings.soundEnabled, volume: savedSettings.soundVolume)
        BarkManager.shared.configure(enabled: savedSettings.barkEnabled, key: savedSettings.barkKey)

        // 监听状态变化
        stateMachine.onStateChanged = { [weak self] state in
            self?.handleStateChange(to: state)
        }

        stateMachine.onPomodorosUpdated = { [weak self] count in
            self?.persistenceManager.incrementTodayPomodoros()
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

    private var previousState: TimerState = .idle

    private func handleStateChange(to newState: TimerState) {
        let oldState = previousState
        previousState = newState

        // 更新菜单栏 UI
        menuBarManager.refreshUI()

        // 检测是否是暂停/恢复事件
        if case .focus(let newCtx) = newState {
            if case .focus(let oldCtx) = oldState {
                // 检测暂停
                if !oldCtx.isPaused && newCtx.isPaused {
                    // 暂停计时器并获取剩余时间
                    let remaining = timer.pause()
                    // 更新状态中的剩余时间
                    var updatedCtx = newCtx
                    updatedCtx.remainingSeconds = remaining
                    stateMachine.updateCurrentState(.focus(updatedCtx))
                    // 刷新菜单栏显示
                    menuBarManager.refreshUI()
                    saveState()
                    return
                }
                // 检测恢复
                if oldCtx.isPaused && !newCtx.isPaused {
                    startFocusTimer(remainingSeconds: newCtx.remainingSeconds)
                    saveState()
                    return
                }
            }
        } else if case .breakTime(let newCtx) = newState {
            if case .breakTime(let oldCtx) = oldState {
                // 检测暂停
                if !oldCtx.isPaused && newCtx.isPaused {
                    // 暂停计时器并获取剩余时间
                    let remaining = timer.pause()
                    // 更新状态中的剩余时间
                    var updatedCtx = newCtx
                    updatedCtx.remainingSeconds = remaining
                    stateMachine.updateCurrentState(.breakTime(updatedCtx))
                    // 刷新菜单栏显示
                    menuBarManager.refreshUI()
                    saveState()
                    return
                }
                // 检测恢复
                if oldCtx.isPaused && !newCtx.isPaused {
                    startBreakTimer(remainingSeconds: newCtx.remainingSeconds)
                    saveState()
                    return
                }
            }
        }

        // 状态转换，停止当前计时器
        timer.stop()
        currentSnoozeDeadline?.cancel()

        switch newState {
        case .idle:
            break

        case .focus(let ctx):
            if !ctx.isPaused {
                startFocusTimer(remainingSeconds: ctx.remainingSeconds)
            }

        case .snooze(let ctx):
            // 只有当从前一个状态切换到 snooze 状态时才显示弹窗
            // 如果已经在 snooze 状态中，不要重复显示弹窗
            if case .snooze(let oldCtx) = oldState {
                // 已经在 snooze 状态，说明用户点击了推迟按钮
                // 计算新增加的推迟时间并启动计时器
                let addedSeconds = ctx.accumulatedSeconds - oldCtx.accumulatedSeconds
                if addedSeconds > 0 {
                    startSnoozeTimer(seconds: addedSeconds)
                }
            } else {
                // 首次进入 snooze 状态，播放专注完成提示音并显示弹窗
                soundManager.playFocusComplete()
                // 发送 Bark 推送
                let completedCount = ctx.completedPomodoros + 1
                BarkManager.shared.sendFocusComplete(count: completedCount)
                handleSnoozeState(ctx)
                // 首次进入时，如果有累计时间，也需要启动计时器显示
                // 注意：这里不启动计时器，等待弹窗回调中用户选择后再启动
            }

        case .breakTime(let ctx):
            // 检测是否从非休息状态进入休息状态
            let isFirstEntry: Bool
            if case .breakTime = oldState {
                isFirstEntry = false
            } else {
                isFirstEntry = true
            }

            Log.info(
                "进入休息状态 - totalSeconds: \(ctx.totalSeconds), remainingSeconds: \(ctx.remainingSeconds), 首次进入: \(isFirstEntry)"
            )

            if isFirstEntry {
                // 首次进入休息状态
                if ctx.totalSeconds != ctx.remainingSeconds {
                    Log.error(
                        "BUG: totalSeconds(\(ctx.totalSeconds)) != remainingSeconds(\(ctx.remainingSeconds))"
                    )
                }
                // 停止推迟计时器
                snoozeTimer?.stop()
                snoozeTimer = nil
                // 播放休息开始提示音
                soundManager.playBreakStart()
                // 显示弹窗
                AlertManager.showBreakStart(
                    breakDuration: ctx.totalSeconds, isLongBreak: ctx.isLongBreak)
            }

            if !ctx.isPaused {
                // 首次进入时使用 totalSeconds，恢复时使用 remainingSeconds
                let breakTime = isFirstEntry ? ctx.totalSeconds : ctx.remainingSeconds
                Log.info("启动休息计时器 - 使用时间: \(breakTime)秒 (首次进入: \(isFirstEntry))")
                startBreakTimer(remainingSeconds: breakTime)
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
        Log.debug("开始休息计时器 - 剩余秒数: \(remainingSeconds)")
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
        snoozeTimer?.stop()

        // 创建一个新的计时器用于倒计时显示
        snoozeTimer = PreciseTimer()

        // 获取当前累计推迟秒数（用户已选择的推迟时长总和）
        guard case .snooze(let ctx) = stateMachine.getContext() else { return }
        let totalAccumulated = ctx.accumulatedSeconds  // 固定值，不随时间变化

        snoozeTimer?.start(
            durationSeconds: seconds,
            onTick: { [weak self] remaining in
                // 显示累计推迟时间（固定）和剩余倒计时
                self?.updateSnoozeTime(remaining: remaining, accumulated: totalAccumulated)
            },
            onComplete: { [weak self] in
                self?.handleSnoozeTimeUp()
            }
        )
    }

    /// 更新推迟状态显示
    private func updateSnoozeTime(remaining: Int, accumulated: Int) {
        // 显示格式：⛔ +累计秒s (剩余秒s)
        let title = "\(Constants.icons.snooze) +\(accumulated)s (\(remaining)s)"
        menuBarManager.updateTitleOnly(title)
    }

    /// 处理推迟时间结束
    private func handleSnoozeTimeUp() {
        snoozeTimer?.stop()
        snoozeTimer = nil

        // 播放推迟警告音
        soundManager.playSnoozeWarning()

        guard case .snooze(let ctx) = stateMachine.getContext() else { return }

        if ctx.snoozeCount < Constants.maxSnoozeCount {
            // 还可以继续推迟，显示弹窗
            AlertManager.showSnoozeTimeUp(snoozeCount: ctx.snoozeCount) { [weak self] response in
                switch response {
                case .startBreak:
                    self?.stateMachine?.handle(.startBreak)
                case .snooze(let seconds):
                    self?.stateMachine?.handle(.snooze(seconds))
                // 不在这里启动计时器，在状态变化中统一处理
                }
            }
        } else {
            // 达到最大推迟次数，强制休息
            showForceBreakAlert()
        }
    }

    // MARK: - 时间更新

    private func updateFocusTime(_ remaining: Int) {
        // 仅更新菜单栏标题，避免触发状态机回调导致无限递归
        let formattedTime = String(format: "%02d:%02d", remaining / 60, remaining % 60)
        let title = "\(Constants.icons.focus) \(formattedTime)"
        menuBarManager.updateTitleOnly(title)
    }

    private func updateBreakTime(_ remaining: Int) {
        // 仅更新菜单栏标题，避免触发状态机回调导致无限递归
        let formattedTime = String(format: "%02d:%02d", remaining / 60, remaining % 60)
        let title = "\(Constants.icons.breakTime) \(formattedTime)"
        menuBarManager.updateTitleOnly(title)
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
            // 不在这里启动计时器，在状态变化中统一处理
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
        // 播放休息结束提示音
        soundManager.playBreakComplete()

        let completedCount = stateMachine.completedPomodoros

        // 发送 Bark 推送
        if case .breakTime(let ctx) = stateMachine.getContext() {
            BarkManager.shared.sendBreakComplete(
                count: completedCount, isLongBreak: ctx.isLongBreak)
        }

        AlertManager.showBreakComplete(completedCount: completedCount)
        stateMachine?.handle(.timeUp)
    }

    // MARK: - 持久化

    private func saveState() {
        let state = stateMachine.getContext()
        let pomodoros = stateMachine.completedPomodoros
        let settings = persistenceManager.loadSettings() ?? Settings.default
        persistenceManager.saveAppState(state: state, pomodoros: pomodoros, settings: settings)
    }

    // MARK: - 设置

    private func openSettings() {
        let currentSettings = persistenceManager.loadSettings() ?? Settings.default

        settingsWindowController = SettingsWindowController(settings: currentSettings) {
            [weak self] newSettings in
            self?.applySettings(newSettings)
        }
        settingsWindowController?.showWindow()
    }

    private func applySettings(_ settings: Settings) {
        // 保存设置
        persistenceManager.saveSettings(settings)

        // 更新声音管理器
        soundManager.configure(enabled: settings.soundEnabled, volume: settings.soundVolume)

        // 更新 Bark 管理器
        BarkManager.shared.configure(enabled: settings.barkEnabled, key: settings.barkKey)

        // 更新状态机设置
        stateMachine.updateSettings(settings)

        Log.info(
            "设置已更新: focusDuration=\(settings.focusDuration)s, breakDuration=\(settings.baseBreakDuration)s, soundEnabled=\(settings.soundEnabled), barkEnabled=\(settings.barkEnabled)"
        )
    }
}
