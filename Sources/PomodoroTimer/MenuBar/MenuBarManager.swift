import AppKit

/// Menu Bar 管理器
class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem?
    private var stateMachine: StateMachine?

    override init() {
        super.init()
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = formatIdleTitle()
        updateMenu(for: .idle)
    }

    func configure(with stateMachine: StateMachine) {
        self.stateMachine = stateMachine

        stateMachine.onStateChanged = { [weak self] state in
            self?.updateUI(for: state)
        }
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
            return "\(Constants.icons.focus) \(formatTime(ctx.remainingSeconds))\(pauseIndicator)"

        case .snooze(let ctx):
            return "\(Constants.icons.snooze) +\(ctx.accumulatedSeconds)s"

        case .breakTime(let ctx):
            let pauseIndicator = ctx.isPaused ? " (已暂停)" : ""
            return
                "\(Constants.icons.breakTime) \(formatTime(ctx.remainingSeconds))\(pauseIndicator)"
        }
    }

    private func formatIdleTitle() -> String {
        Constants.icons.idle
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
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
            menu.addItem(NSMenuItem.separator())
            menu.addItem(
                NSMenuItem(title: "完成数: \(completedPomodoros())", action: nil, keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
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
            menu.addItem(NSMenuItem.separator())
            menu.addItem(
                NSMenuItem(title: "完成数: \(completedPomodoros())", action: nil, keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
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
            menu.addItem(NSMenuItem.separator())
            menu.addItem(
                NSMenuItem(title: "完成数: \(completedPomodoros())", action: nil, keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
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
            menu.addItem(NSMenuItem.separator())
            menu.addItem(
                NSMenuItem(title: "完成数: \(completedPomodoros())", action: nil, keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
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

    // MARK: - 事件处理

    @objc private func handleStart() {
        stateMachine?.handle(.start)
    }

    @objc private func handleStop() {
        stateMachine?.handle(.stop)
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

    @objc private func handleQuit() {
        NSApplication.shared.terminate(nil)
    }
}
