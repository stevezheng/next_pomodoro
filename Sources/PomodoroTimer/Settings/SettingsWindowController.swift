import AppKit

/// 设置窗口管理器
class SettingsWindowController: NSWindowController {

    private var focusDurationField: NSTextField!
    private var breakDurationField: NSTextField!
    private var longBreakDurationField: NSTextField!
    private var longBreakIntervalField: NSTextField!
    private var soundEnabledCheckbox: NSButton!
    private var soundVolumeSlider: NSSlider!
    private var barkEnabledCheckbox: NSButton!
    private var barkKeyField: NSTextField!
    private var barkTestButton: NSButton!
    private var testModeCheckbox: NSButton!
    private var iCloudStatusLabel: NSTextField!
    private var persistenceManager: PersistenceManager?

    private var currentSettings: Settings
    private var onSave: ((Settings) -> Void)?

    init(
        settings: Settings, persistenceManager: PersistenceManager,
        onSave: @escaping (Settings) -> Void
    ) {
        self.currentSettings = settings
        self.persistenceManager = persistenceManager
        self.onSave = onSave

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 560),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "番茄钟设置"
        window.center()

        super.init(window: window)

        setupUI()
        loadCurrentSettings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
        ])

        // 标题
        let titleLabel = NSTextField(labelWithString: "⚙️ 番茄钟设置")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 18)
        stackView.addArrangedSubview(titleLabel)

        // 分隔线
        let separator1 = NSBox()
        separator1.boxType = .separator
        stackView.addArrangedSubview(separator1)

        // 时间设置区域
        let timeLabel = NSTextField(labelWithString: "时间设置（分钟）")
        timeLabel.font = NSFont.boldSystemFont(ofSize: 14)
        stackView.addArrangedSubview(timeLabel)

        // 专注时长
        let focusRow = createInputRow(label: "专注时长:", placeholder: "25")
        focusDurationField = focusRow.1
        stackView.addArrangedSubview(focusRow.0)

        // 短休息时长
        let breakRow = createInputRow(label: "短休息时长:", placeholder: "5")
        breakDurationField = breakRow.1
        stackView.addArrangedSubview(breakRow.0)

        // 长休息时长
        let longBreakRow = createInputRow(label: "长休息时长:", placeholder: "15")
        longBreakDurationField = longBreakRow.1
        stackView.addArrangedSubview(longBreakRow.0)

        // 长休息间隔
        let intervalRow = createIntervalRow()
        longBreakIntervalField = intervalRow.1
        stackView.addArrangedSubview(intervalRow.0)

        // 分隔线
        let separator2 = NSBox()
        separator2.boxType = .separator
        stackView.addArrangedSubview(separator2)

        // 声音设置区域
        let soundLabel = NSTextField(labelWithString: "声音设置")
        soundLabel.font = NSFont.boldSystemFont(ofSize: 14)
        stackView.addArrangedSubview(soundLabel)

        // 启用声音
        soundEnabledCheckbox = NSButton(
            checkboxWithTitle: "启用声音提醒", target: self, action: #selector(soundEnabledChanged))
        stackView.addArrangedSubview(soundEnabledCheckbox)

        // 音量滑块
        let volumeRow = NSStackView()
        volumeRow.orientation = .horizontal
        volumeRow.spacing = 10

        let volumeLabel = NSTextField(labelWithString: "音量:")
        volumeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        volumeRow.addArrangedSubview(volumeLabel)

        soundVolumeSlider = NSSlider(value: 0.8, minValue: 0, maxValue: 1, target: nil, action: nil)
        soundVolumeSlider.widthAnchor.constraint(equalToConstant: 200).isActive = true
        volumeRow.addArrangedSubview(soundVolumeSlider)

        stackView.addArrangedSubview(volumeRow)

        // 分隔线
        let separator3 = NSBox()
        separator3.boxType = .separator
        stackView.addArrangedSubview(separator3)

        // Bark 推送设置区域
        let barkLabel = NSTextField(labelWithString: "Bark 推送设置")
        barkLabel.font = NSFont.boldSystemFont(ofSize: 14)
        stackView.addArrangedSubview(barkLabel)

        // 启用 Bark
        barkEnabledCheckbox = NSButton(
            checkboxWithTitle: "启用 Bark 推送", target: self, action: #selector(barkEnabledChanged))
        stackView.addArrangedSubview(barkEnabledCheckbox)

        // Bark Key 输入
        let barkKeyRow = NSStackView()
        barkKeyRow.orientation = .horizontal
        barkKeyRow.spacing = 10

        let barkKeyLabel = NSTextField(labelWithString: "Bark Key:")
        barkKeyLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true
        barkKeyRow.addArrangedSubview(barkKeyLabel)

        barkKeyField = NSTextField()
        barkKeyField.placeholderString = "输入你的 Bark Key"
        barkKeyField.isEditable = true
        barkKeyField.isSelectable = true
        barkKeyField.isBordered = true
        barkKeyField.bezelStyle = .squareBezel
        barkKeyField.usesSingleLineMode = true
        barkKeyField.lineBreakMode = .byTruncatingTail
        // 启用标准编辑快捷键（Cmd+A, Cmd+C, Cmd+V 等）
        barkKeyField.allowsEditingTextAttributes = false
        barkKeyField.importsGraphics = false
        barkKeyField.widthAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true
        barkKeyRow.addArrangedSubview(barkKeyField)

        // 测试按钮
        barkTestButton = NSButton(title: "测试", target: self, action: #selector(testBarkClicked))
        barkTestButton.bezelStyle = .rounded
        barkKeyRow.addArrangedSubview(barkTestButton)

        stackView.addArrangedSubview(barkKeyRow)

        // Bark 提示信息
        let barkHintLabel = NSTextField(labelWithString: "提示：在 Bark App 中复制你的 Key")
        barkHintLabel.font = NSFont.systemFont(ofSize: 10)
        barkHintLabel.textColor = .secondaryLabelColor
        stackView.addArrangedSubview(barkHintLabel)

        // 分隔线
        let separator4 = NSBox()
        separator4.boxType = .separator
        stackView.addArrangedSubview(separator4)

        // 测试模式
        testModeCheckbox = NSButton(checkboxWithTitle: "测试模式（使用秒代替分钟）", target: nil, action: nil)
        stackView.addArrangedSubview(testModeCheckbox)

        // 分隔线
        let separator5 = NSBox()
        separator5.boxType = .separator
        stackView.addArrangedSubview(separator5)

        // iCloud 同步状态
        let iCloudLabel = NSTextField(labelWithString: "iCloud 同步")
        iCloudLabel.font = NSFont.boldSystemFont(ofSize: 14)
        stackView.addArrangedSubview(iCloudLabel)

        // iCloud 状态显示
        iCloudStatusLabel = NSTextField(labelWithString: "")
        iCloudStatusLabel.font = NSFont.systemFont(ofSize: 12)
        iCloudStatusLabel.textColor = .secondaryLabelColor
        stackView.addArrangedSubview(iCloudStatusLabel)
        updateiCloudStatus()

        let iCloudHintLabel = NSTextField(labelWithString: "提示：需要在系统设置中登录 iCloud 账户")
        iCloudHintLabel.font = NSFont.systemFont(ofSize: 10)
        iCloudHintLabel.textColor = .secondaryLabelColor
        stackView.addArrangedSubview(iCloudHintLabel)

        // 按钮区域
        let buttonRow = NSStackView()
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 10

        let cancelButton = NSButton(title: "取消", target: self, action: #selector(cancelClicked))
        let saveButton = NSButton(title: "保存", target: self, action: #selector(saveClickedNoClose))
        saveButton.bezelStyle = .rounded
        let okButton = NSButton(title: "确定", target: self, action: #selector(saveClicked))
        okButton.bezelStyle = .rounded
        okButton.keyEquivalent = "\r"

        buttonRow.addArrangedSubview(NSView())  // Spacer
        buttonRow.addArrangedSubview(cancelButton)
        buttonRow.addArrangedSubview(saveButton)
        buttonRow.addArrangedSubview(okButton)

        stackView.addArrangedSubview(buttonRow)
    }

    private func createInputRow(label: String, placeholder: String) -> (NSStackView, NSTextField) {
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 10

        let labelField = NSTextField(labelWithString: label)
        labelField.widthAnchor.constraint(equalToConstant: 100).isActive = true
        row.addArrangedSubview(labelField)

        let textField = NSTextField()
        textField.placeholderString = placeholder
        textField.isEditable = true
        textField.isSelectable = true
        textField.isBordered = true
        textField.bezelStyle = .squareBezel
        textField.widthAnchor.constraint(equalToConstant: 80).isActive = true
        row.addArrangedSubview(textField)

        let unitLabel = NSTextField(labelWithString: "分钟")
        row.addArrangedSubview(unitLabel)

        return (row, textField)
    }

    private func createIntervalRow() -> (NSStackView, NSTextField) {
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 10

        let labelField = NSTextField(labelWithString: "长休息间隔:")
        labelField.widthAnchor.constraint(equalToConstant: 100).isActive = true
        row.addArrangedSubview(labelField)

        let textField = NSTextField()
        textField.placeholderString = "4"
        textField.isEditable = true
        textField.isSelectable = true
        textField.isBordered = true
        textField.bezelStyle = .squareBezel
        textField.widthAnchor.constraint(equalToConstant: 80).isActive = true
        row.addArrangedSubview(textField)

        let unitLabel = NSTextField(labelWithString: "个番茄")
        row.addArrangedSubview(unitLabel)

        return (row, textField)
    }

    private func loadCurrentSettings() {
        // 直接使用存储的分钟数值，不需要转换
        focusDurationField.integerValue = currentSettings.focusDurationMinutes
        breakDurationField.integerValue = currentSettings.baseBreakDurationMinutes
        longBreakDurationField.integerValue = currentSettings.longBreakDurationMinutes
        longBreakIntervalField.integerValue = currentSettings.longBreakInterval
        soundEnabledCheckbox.state = currentSettings.soundEnabled ? .on : .off
        soundVolumeSlider.floatValue = currentSettings.soundVolume
        barkEnabledCheckbox.state = currentSettings.barkEnabled ? .on : .off
        barkKeyField.stringValue = currentSettings.barkKey
        testModeCheckbox.state = currentSettings.testMode ? .on : .off

        // 更新启用状态
        soundVolumeSlider.isEnabled = soundEnabledCheckbox.state == .on
        barkKeyField.isEnabled = barkEnabledCheckbox.state == .on
        barkTestButton.isEnabled = barkEnabledCheckbox.state == .on
    }

    @objc private func soundEnabledChanged() {
        soundVolumeSlider.isEnabled = soundEnabledCheckbox.state == .on
    }

    @objc private func barkEnabledChanged() {
        barkKeyField.isEnabled = barkEnabledCheckbox.state == .on
        barkTestButton.isEnabled = barkEnabledCheckbox.state == .on
    }

    @objc private func testBarkClicked() {
        // 保存当前设置并测试
        let key = barkKeyField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if key.isEmpty {
            showAlert(title: "错误", message: "请先输入 Bark Key")
            return
        }

        BarkManager.shared.configure(enabled: true, key: key)
        BarkManager.shared.testNotification()
        showAlert(title: "测试发送成功", message: "请检查你的 iOS 设备是否收到 Bark 推送")
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }

    private func updateiCloudStatus() {
        guard let persistenceManager = persistenceManager else {
            iCloudStatusLabel.stringValue = "状态：未知"
            return
        }

        if persistenceManager.isiCloudAvailable() {
            iCloudStatusLabel.stringValue = "✅ 状态：已启用（设置将自动同步到 iCloud）"
            iCloudStatusLabel.textColor = .systemGreen
        } else {
            iCloudStatusLabel.stringValue = "⚠️ 状态：未启用（请在系统设置中登录 iCloud）"
            iCloudStatusLabel.textColor = .systemOrange
        }
    }

    @objc private func cancelClicked() {
        window?.close()
    }

    @objc private func saveClickedNoClose() {
        let testMode = testModeCheckbox.state == .on

        // 验证长休息间隔，至少为 1
        let interval = max(1, longBreakIntervalField.integerValue)

        // 获取用户输入的值（分钟数）
        let focusMinutes = focusDurationField.integerValue
        let breakMinutes = breakDurationField.integerValue
        let longBreakMinutes = longBreakDurationField.integerValue

        let newSettings = Settings(
            focusDuration: focusMinutes,
            baseBreakDuration: breakMinutes,
            longBreakDuration: longBreakMinutes,
            longBreakInterval: interval,
            testMode: testMode,
            soundEnabled: soundEnabledCheckbox.state == .on,
            soundVolume: soundVolumeSlider.floatValue,
            barkEnabled: barkEnabledCheckbox.state == .on,
            barkKey: barkKeyField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        onSave?(newSettings)
        currentSettings = newSettings  // 更新当前设置引用
    }

    @objc private func saveClicked() {
        saveClickedNoClose()
        window?.close()
    }

    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
