import AppKit

/// Menu Bar 管理器
class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem?
    private var stateMachine: StateMachine?
    private var persistenceManager: PersistenceManager?

    /// 设置按钮回调
    var onOpenSettings: (() -> Void)?

    override init() {
        super.init()
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = formatIdleTitle()
        updateMenu(for: .idle)
    }

    func configure(with stateMachine: StateMachine, persistenceManager: PersistenceManager? = nil) {
        self.stateMachine = stateMachine
        self.persistenceManager = persistenceManager
        // 初始化时更新 UI
        updateUI(for: stateMachine.currentState)
    }

    /// 更新 UI（供外部调用）
    func refreshUI() {
        guard let state = stateMachine?.currentState else { return }
        updateUI(for: state)
    }

    // MARK: - UI 更新

    private func updateUI(for state: TimerState) {
        updateTitle(for: state)
        updateMenu(for: state)
    }

    /// 仅更新标题（用于 timer tick，避免触发完整的状态变化）
    func updateTitleOnly(_ title: String) {
        DispatchQueue.main.async { [weak self] in
            self?.statusItem?.button?.title = title
        }
    }

    private func updateTitle(for state: TimerState) {
        let title = formatTitle(for: state)
        DispatchQueue.main.async { [weak self] in
            self?.statusItem?.button?.title = title
        }
    }

    private func updateMenu(for state: TimerState) {
        let menu = buildMenu(for: state)
        DispatchQueue.main.async { [weak self] in
            self?.statusItem?.menu = menu
        }
    }

    // MARK: - 标题格式化

    private func formatTitle(for state: TimerState) -> String {
        switch state {
        case .idle:
            return formatIdleTitle()

        case .focus(let ctx):
            let pauseIndicator = ctx.isPaused ? " (已暂停)" : ""
            return "\(Constants.icons.focus) \(TimeFormatter.format(ctx.remainingSeconds))\(pauseIndicator)"

        case .snooze(let ctx):
            return "\(Constants.icons.snooze) +\(TimeFormatter.format(ctx.accumulatedSeconds))"

        case .breakTime(let ctx):
            let pauseIndicator = ctx.isPaused ? " (已暂停)" : ""
            let icon = ctx.isLongBreak ? Constants.icons.longBreak : Constants.icons.breakTime
            return "\(icon) \(TimeFormatter.format(ctx.remainingSeconds))\(pauseIndicator)"
        }
    }

    private func formatIdleTitle() -> String {
        Constants.icons.idle
    }

    // MARK: - 菜单构建

    private func buildMenu(for state: TimerState) -> NSMenu {
        let menu = NSMenu()

        switch state {
        case .idle:
            let startItem = NSMenuItem(
                title: "开始番茄钟", action: #selector(handleStart), keyEquivalent: "s")
            startItem.target = self
            menu.addItem(startItem)
            addStatsToMenu(menu)
            menu.addItem(NSMenuItem.separator())
            let settingsItem = NSMenuItem(
                title: "设置...", action: #selector(handleSettings), keyEquivalent: ",")
            settingsItem.target = self
            menu.addItem(settingsItem)
            let quitItem = NSMenuItem(
                title: "退出", action: #selector(handleQuit), keyEquivalent: "q")
            quitItem.target = self
            menu.addItem(quitItem)

        case .focus(let ctx):
            if ctx.isPaused {
                let resumeItem = NSMenuItem(
                    title: "继续", action: #selector(handleResume), keyEquivalent: "r")
                resumeItem.target = self
                menu.addItem(resumeItem)
            } else {
                let pauseItem = NSMenuItem(
                    title: "暂停", action: #selector(handlePause), keyEquivalent: "p")
                pauseItem.target = self
                menu.addItem(pauseItem)
            }
            let stopItem = NSMenuItem(
                title: "停止", action: #selector(handleStop), keyEquivalent: "s")
            stopItem.target = self
            menu.addItem(stopItem)
            addStatsToMenu(menu)
            menu.addItem(NSMenuItem.separator())
            let settingsItem = NSMenuItem(
                title: "设置...", action: #selector(handleSettings), keyEquivalent: "")
            settingsItem.target = self
            menu.addItem(settingsItem)
            let quitItem = NSMenuItem(
                title: "退出", action: #selector(handleQuit), keyEquivalent: "q")
            quitItem.target = self
            menu.addItem(quitItem)

        case .snooze:
            let startBreakItem = NSMenuItem(
                title: "开始休息", action: #selector(handleStartBreak), keyEquivalent: "b")
            startBreakItem.target = self
            menu.addItem(startBreakItem)
            let stopItem = NSMenuItem(
                title: "停止", action: #selector(handleStop), keyEquivalent: "s")
            stopItem.target = self
            menu.addItem(stopItem)
            addStatsToMenu(menu)
            menu.addItem(NSMenuItem.separator())
            let settingsItem = NSMenuItem(
                title: "设置...", action: #selector(handleSettings), keyEquivalent: "")
            settingsItem.target = self
            menu.addItem(settingsItem)
            let quitItem = NSMenuItem(
                title: "退出", action: #selector(handleQuit), keyEquivalent: "q")
            quitItem.target = self
            menu.addItem(quitItem)

        case .breakTime(let ctx):
            if ctx.isPaused {
                let resumeItem = NSMenuItem(
                    title: "继续", action: #selector(handleResume), keyEquivalent: "r")
                resumeItem.target = self
                menu.addItem(resumeItem)
            } else {
                let pauseItem = NSMenuItem(
                    title: "暂停", action: #selector(handlePause), keyEquivalent: "p")
                pauseItem.target = self
                menu.addItem(pauseItem)
            }
            let stopItem = NSMenuItem(
                title: "停止", action: #selector(handleStop), keyEquivalent: "s")
            stopItem.target = self
            menu.addItem(stopItem)
            addStatsToMenu(menu)
            menu.addItem(NSMenuItem.separator())
            let settingsItem = NSMenuItem(
                title: "设置...", action: #selector(handleSettings), keyEquivalent: "")
            settingsItem.target = self
            menu.addItem(settingsItem)
            let quitItem = NSMenuItem(
                title: "退出", action: #selector(handleQuit), keyEquivalent: "q")
            quitItem.target = self
            menu.addItem(quitItem)
        }

        return menu
    }

    private func completedPomodoros() -> Int {
        stateMachine?.completedPomodoros ?? 0
    }

    private func todayPomodoros() -> Int {
        persistenceManager?.getTodayPomodoros() ?? 0
    }

    /// 添加统计信息到菜单
    private func addStatsToMenu(_ menu: NSMenu) {
        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            NSMenuItem(title: "今日完成: \(todayPomodoros()) 🍅", action: nil, keyEquivalent: ""))
        menu.addItem(
            NSMenuItem(title: "总完成数: \(completedPomodoros())", action: nil, keyEquivalent: ""))
    }

    // MARK: - 事件处理

    @objc private func handleStart() {
        stateMachine?.handle(.start)
    }

    @objc private func handleStop() {
        stateMachine?.handle(.stop)
    }

    @objc private func handleInterrupt() {
        stateMachine?.handle(.interrupt)
    }

    @objc private func handlePause() {
        stateMachine?.handle(.pause)
    }

    @objc private func handleResume() {
        stateMachine?.handle(.resume)
    }

    @objc private func handleStartBreak() {
        stateMachine?.handle(.startBreak)
    }

    @objc private func handleSettings() {
        onOpenSettings?()
    }

    @objc private func handleQuit() {
        NSApplication.shared.terminate(nil)
    }
}
