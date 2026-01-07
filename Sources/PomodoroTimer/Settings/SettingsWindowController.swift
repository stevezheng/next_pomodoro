import AppKit

/// 设置窗口管理器
class SettingsWindowController: NSWindowController {

    private var focusDurationField: NSTextField!
    private var breakDurationField: NSTextField!
    private var longBreakDurationField: NSTextField!
    private var soundEnabledCheckbox: NSButton!
    private var soundVolumeSlider: NSSlider!
    private var testModeCheckbox: NSButton!

    private var currentSettings: Settings
    private var onSave: ((Settings) -> Void)?

    init(settings: Settings, onSave: @escaping (Settings) -> Void) {
        self.currentSettings = settings
        self.onSave = onSave

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 350),
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

        // 测试模式
        testModeCheckbox = NSButton(checkboxWithTitle: "测试模式（使用秒代替分钟）", target: nil, action: nil)
        stackView.addArrangedSubview(testModeCheckbox)

        // 按钮区域
        let buttonRow = NSStackView()
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 10

        let cancelButton = NSButton(title: "取消", target: self, action: #selector(cancelClicked))
        let saveButton = NSButton(title: "保存", target: self, action: #selector(saveClicked))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"

        buttonRow.addArrangedSubview(NSView())  // Spacer
        buttonRow.addArrangedSubview(cancelButton)
        buttonRow.addArrangedSubview(saveButton)

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
        textField.widthAnchor.constraint(equalToConstant: 80).isActive = true
        row.addArrangedSubview(textField)

        let unitLabel = NSTextField(labelWithString: "分钟")
        row.addArrangedSubview(unitLabel)

        return (row, textField)
    }

    private func loadCurrentSettings() {
        // 根据测试模式转换时间显示
        let divider = currentSettings.testMode ? 1 : 60
        focusDurationField.integerValue = currentSettings.focusDuration / divider
        breakDurationField.integerValue = currentSettings.baseBreakDuration / divider
        longBreakDurationField.integerValue = currentSettings.longBreakDuration / divider
        soundEnabledCheckbox.state = currentSettings.soundEnabled ? .on : .off
        soundVolumeSlider.floatValue = currentSettings.soundVolume
        testModeCheckbox.state = currentSettings.testMode ? .on : .off
    }

    @objc private func soundEnabledChanged() {
        soundVolumeSlider.isEnabled = soundEnabledCheckbox.state == .on
    }

    @objc private func cancelClicked() {
        window?.close()
    }

    @objc private func saveClicked() {
        let testMode = testModeCheckbox.state == .on

        let newSettings = Settings(
            focusDuration: focusDurationField.integerValue,
            baseBreakDuration: breakDurationField.integerValue,
            longBreakDuration: longBreakDurationField.integerValue,
            testMode: testMode,
            soundEnabled: soundEnabledCheckbox.state == .on,
            soundVolume: soundVolumeSlider.floatValue
        )

        onSave?(newSettings)
        window?.close()
    }

    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
