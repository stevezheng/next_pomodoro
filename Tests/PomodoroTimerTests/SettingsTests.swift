import XCTest
@testable import PomodoroTimer

final class SettingsTests: XCTestCase {

    // MARK: - 初始化测试

    func testDefaultSettingsInTestMode() {
        let settings = Settings()

        XCTAssertTrue(settings.testMode)
        XCTAssertEqual(settings.focusDuration, 25) // 秒（测试模式）
        XCTAssertEqual(settings.baseBreakDuration, 5)
        XCTAssertEqual(settings.longBreakDuration, 15)
    }

    func testSettingsInProductionMode() {
        let settings = Settings(
            focusDuration: 25,
            baseBreakDuration: 5,
            longBreakDuration: 15,
            testMode: false
        )

        XCTAssertFalse(settings.testMode)
        XCTAssertEqual(settings.focusDuration, 25 * 60) // 分钟转秒
        XCTAssertEqual(settings.baseBreakDuration, 5 * 60)
        XCTAssertEqual(settings.longBreakDuration, 15 * 60)
    }

    // MARK: - 推迟选项测试

    func testSnoozeOptionsInTestMode() {
        let settings = Settings(testMode: true)

        XCTAssertEqual(settings.snoozeOptions, [5, 10, 15])
    }

    func testSnoozeOptionsInProductionMode() {
        let settings = Settings(testMode: false)

        XCTAssertEqual(settings.snoozeOptions, [5 * 60, 10 * 60, 15 * 60])
    }

    // MARK: - 休息时间计算测试

    func testCalculateBreakDurationWithNoSnooze() {
        let settings = Settings(baseBreakDuration: 5, testMode: true)

        let duration = settings.calculateBreakDuration(snoozeSeconds: 0, isLongBreak: false)

        XCTAssertEqual(duration, 5)
    }

    func testCalculateBreakDurationWithSnoozePenalty() {
        let settings = Settings(baseBreakDuration: 5, testMode: true)

        // 推迟10秒，惩罚 = 10 / 5 = 2秒
        let duration = settings.calculateBreakDuration(snoozeSeconds: 10, isLongBreak: false)

        XCTAssertEqual(duration, 7) // 5 + 2
    }

    func testCalculateLongBreakDuration() {
        let settings = Settings(baseBreakDuration: 5, longBreakDuration: 15, testMode: true)

        let duration = settings.calculateBreakDuration(snoozeSeconds: 0, isLongBreak: true)

        XCTAssertEqual(duration, 15)
    }

    func testCalculateLongBreakDurationWithPenalty() {
        let settings = Settings(baseBreakDuration: 5, longBreakDuration: 15, testMode: true)

        // 推迟15秒，惩罚 = 15 / 5 = 3秒
        let duration = settings.calculateBreakDuration(snoozeSeconds: 15, isLongBreak: true)

        XCTAssertEqual(duration, 18) // 15 + 3
    }

    // MARK: - 声音设置测试

    func testDefaultSoundSettings() {
        let settings = Settings()

        XCTAssertTrue(settings.soundEnabled)
        XCTAssertEqual(settings.soundVolume, 0.8)
    }

    func testCustomSoundSettings() {
        let settings = Settings(soundEnabled: false, soundVolume: 0.3)

        XCTAssertFalse(settings.soundEnabled)
        XCTAssertEqual(settings.soundVolume, 0.3)
    }

    // MARK: - 空闲提醒测试

    func testDefaultIdleReminderSettings() {
        let settings = Settings()

        XCTAssertTrue(settings.idleReminderEnabled)
        XCTAssertEqual(settings.idleReminderIntervalMinutes, Constants.idleReminderDefaultInterval)
        XCTAssertEqual(settings.idleReminderInterval, Constants.idleReminderDefaultInterval)
    }

    func testIdleReminderIntervalInProductionMode() {
        let settings = Settings(testMode: false, idleReminderInterval: 3)

        XCTAssertEqual(settings.idleReminderInterval, 3 * 60)
    }

    func testIdleReminderIntervalHasMinimumValue() {
        let settings = Settings(idleReminderInterval: 0)

        XCTAssertEqual(settings.idleReminderIntervalMinutes, Constants.idleReminderMinimumInterval)
    }

    func testSettingsDecodeWithMissingIdleReminderFields() throws {
        let json = """
            {
                "focusDurationMinutes": 25,
                "baseBreakDurationMinutes": 5,
                "longBreakDurationMinutes": 15,
                "longBreakInterval": 4,
                "testMode": true,
                "soundEnabled": true,
                "soundVolume": 0.8,
                "barkEnabled": false,
                "barkKey": ""
            }
            """
        let settings = try JSONDecoder().decode(Settings.self, from: Data(json.utf8))

        XCTAssertTrue(settings.idleReminderEnabled)
        XCTAssertEqual(settings.idleReminderIntervalMinutes, Constants.idleReminderDefaultInterval)
    }
}
