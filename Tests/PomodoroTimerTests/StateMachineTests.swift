import XCTest
@testable import PomodoroTimer

final class StateMachineTests: XCTestCase {

    var stateMachine: StateMachine!

    override func setUp() {
        super.setUp()
        stateMachine = StateMachine(settings: Settings.default)
    }

    override func tearDown() {
        stateMachine = nil
        super.tearDown()
    }

    // MARK: - 初始状态测试

    func testInitialStateIsIdle() {
        XCTAssertEqual(stateMachine.currentState, .idle)
    }

    func testInitialPomodorosCountIsZero() {
        XCTAssertEqual(stateMachine.completedPomodoros, 0)
    }

    // MARK: - Idle 状态测试

    func testIdleToFocusOnStart() {
        stateMachine.handle(.start)

        if case .focus(let ctx) = stateMachine.currentState {
            XCTAssertEqual(ctx.remainingSeconds, Settings.default.focusDuration)
            XCTAssertFalse(ctx.isPaused)
        } else {
            XCTFail("Expected focus state")
        }
    }

    func testIdleStaysIdleOnStop() {
        stateMachine.handle(.stop)
        XCTAssertEqual(stateMachine.currentState, .idle)
    }

    // MARK: - Focus 状态测试

    func testFocusToSnoozeOnTimeUp() {
        stateMachine.handle(.start)
        stateMachine.handle(.timeUp)

        if case .snooze(let ctx) = stateMachine.currentState {
            XCTAssertEqual(ctx.snoozeCount, 0)
            XCTAssertEqual(ctx.accumulatedSeconds, 0)
        } else {
            XCTFail("Expected snooze state")
        }
    }

    func testFocusToIdleOnStop() {
        stateMachine.handle(.start)
        stateMachine.handle(.stop)

        XCTAssertEqual(stateMachine.currentState, .idle)
        XCTAssertEqual(stateMachine.completedPomodoros, 0, "Stop should not increment pomodoros")
    }

    func testFocusPauseAndResume() {
        stateMachine.handle(.start)

        // 暂停
        stateMachine.handle(.pause)
        if case .focus(let ctx) = stateMachine.currentState {
            XCTAssertTrue(ctx.isPaused)
        } else {
            XCTFail("Expected focus state")
        }

        // 恢复
        stateMachine.handle(.resume)
        if case .focus(let ctx) = stateMachine.currentState {
            XCTAssertFalse(ctx.isPaused)
        } else {
            XCTFail("Expected focus state")
        }
    }

    // MARK: - Snooze 状态测试

    func testSnoozeAccumulatesTime() {
        stateMachine.handle(.start)
        stateMachine.handle(.timeUp)

        // 第一次推迟
        stateMachine.handle(.snooze(5))

        if case .snooze(let ctx) = stateMachine.currentState {
            XCTAssertEqual(ctx.snoozeCount, 1)
            XCTAssertEqual(ctx.accumulatedSeconds, 5)
        } else {
            XCTFail("Expected snooze state")
        }

        // 第二次推迟
        stateMachine.handle(.snooze(10))

        if case .snooze(let ctx) = stateMachine.currentState {
            XCTAssertEqual(ctx.snoozeCount, 2)
            XCTAssertEqual(ctx.accumulatedSeconds, 15)
        } else {
            XCTFail("Expected snooze state")
        }
    }

    func testSnoozeToBreakOnStartBreak() {
        stateMachine.handle(.start)
        stateMachine.handle(.timeUp)
        stateMachine.handle(.startBreak)

        if case .breakTime(let ctx) = stateMachine.currentState {
            XCTAssertEqual(ctx.remainingSeconds, Settings.default.baseBreakDuration)
        } else {
            XCTFail("Expected breakTime state")
        }
    }

    func testMaxSnoozeCountForcesBreak() {
        stateMachine.handle(.start)
        stateMachine.handle(.timeUp)

        // 推迟3次
        for _ in 0..<3 {
            stateMachine.handle(.snooze(5))
        }

        // 第4次 timeUp 应该强制进入休息
        stateMachine.handle(.timeUp)

        if case .breakTime = stateMachine.currentState {
            // 成功
        } else {
            XCTFail("Expected breakTime state after max snooze")
        }
    }

    // MARK: - Break 状态测试

    func testBreakToIdleOnTimeUp() {
        stateMachine.handle(.start)
        stateMachine.handle(.timeUp)
        stateMachine.handle(.startBreak)
        stateMachine.handle(.timeUp)

        XCTAssertEqual(stateMachine.currentState, .idle)
        XCTAssertEqual(stateMachine.completedPomodoros, 1, "Should increment pomodoros after break")
    }

    func testBreakPauseAndResume() {
        stateMachine.handle(.start)
        stateMachine.handle(.timeUp)
        stateMachine.handle(.startBreak)

        // 暂停
        stateMachine.handle(.pause)
        if case .breakTime(let ctx) = stateMachine.currentState {
            XCTAssertTrue(ctx.isPaused)
        } else {
            XCTFail("Expected breakTime state")
        }

        // 恢复
        stateMachine.handle(.resume)
        if case .breakTime(let ctx) = stateMachine.currentState {
            XCTAssertFalse(ctx.isPaused)
        } else {
            XCTFail("Expected breakTime state")
        }
    }

    // MARK: - 长休息测试

    func testLongBreakAfterFourPomodoros() {
        // 完成4个番茄
        for i in 0..<4 {
            stateMachine.handle(.start)
            stateMachine.handle(.timeUp)
            stateMachine.handle(.startBreak)

            if i == 3 {
                // 第4个番茄后应该是长休息
                if case .breakTime(let ctx) = stateMachine.currentState {
                    XCTAssertTrue(ctx.isLongBreak, "Fourth pomodoro should trigger long break")
                } else {
                    XCTFail("Expected breakTime state")
                }
            }

            stateMachine.handle(.timeUp)
        }

        XCTAssertEqual(stateMachine.completedPomodoros, 4)
    }

    // MARK: - 推迟后休息时间测试

    func testSnoozeIncreasesBreakDuration() {
        let settings = Settings(focusDuration: 10, baseBreakDuration: 5, testMode: true)
        stateMachine.updateSettings(settings)

        stateMachine.handle(.start)
        stateMachine.handle(.timeUp)

        // 推迟10秒
        stateMachine.handle(.snooze(10))

        // 开始休息
        stateMachine.handle(.startBreak)

        if case .breakTime(let ctx) = stateMachine.currentState {
            // 基础休息5秒 + 推迟10秒的奖励(10/5=2秒) = 7秒
            XCTAssertEqual(ctx.totalSeconds, 7, "Break duration should be 5 + (10/5) = 7 seconds")
            XCTAssertEqual(ctx.remainingSeconds, 7, "Remaining seconds should equal total seconds at start")
        } else {
            XCTFail("Expected breakTime state")
        }
    }
}
