import XCTest
@testable import PomodoroTimer

final class PersistenceManagerTests: XCTestCase {

    var persistenceManager: PersistenceManager!
    var testUserDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // 使用独立的 UserDefaults 进行测试
        testUserDefaults = UserDefaults(suiteName: "com.pomodoro.tests")
        testUserDefaults?.removePersistentDomain(forName: "com.pomodoro.tests")
        persistenceManager = PersistenceManager(userDefaults: testUserDefaults!)
    }

    override func tearDown() {
        testUserDefaults?.removePersistentDomain(forName: "com.pomodoro.tests")
        persistenceManager = nil
        testUserDefaults = nil
        super.tearDown()
    }

    // MARK: - App State Tests

    func testSaveAndLoadAppState() {
        let state = TimerState.focus(FocusContext(
            remainingSeconds: 1500,
            totalSeconds: 1500,
            isPaused: false,
            completedPomodoros: 2
        ))
        let pomodoros = 5
        let settings = Settings.default

        persistenceManager.saveAppState(state: state, pomodoros: pomodoros, settings: settings)

        let loaded = persistenceManager.loadAppState()
        XCTAssertNotNil(loaded)

        if let (loadedState, loadedPomodoros, _) = loaded {
            XCTAssertEqual(loadedPomodoros, pomodoros)

            if case .focus(let ctx) = loadedState {
                XCTAssertEqual(ctx.remainingSeconds, 1500)
                XCTAssertEqual(ctx.completedPomodoros, 2)
            } else {
                XCTFail("Expected focus state")
            }
        }
    }

    func testLoadAppStateReturnsNilWhenEmpty() {
        let loaded = persistenceManager.loadAppState()
        XCTAssertNil(loaded)
    }

    func testClearAppState() {
        let state = TimerState.idle
        persistenceManager.saveAppState(state: state, pomodoros: 10, settings: Settings.default)

        persistenceManager.clear()

        let loaded = persistenceManager.loadAppState()
        XCTAssertNil(loaded)
    }

    // MARK: - Today Pomodoros Tests

    func testGetTodayPomodorosInitiallyZero() {
        let count = persistenceManager.getTodayPomodoros()
        XCTAssertEqual(count, 0)
    }

    func testIncrementTodayPomodoros() {
        persistenceManager.incrementTodayPomodoros()
        persistenceManager.incrementTodayPomodoros()
        persistenceManager.incrementTodayPomodoros()

        let count = persistenceManager.getTodayPomodoros()
        XCTAssertEqual(count, 3)
    }

    // MARK: - Settings Tests

    func testSaveAndLoadSettings() {
        let settings = Settings(
            focusDuration: 30,
            baseBreakDuration: 10,
            longBreakDuration: 20,
            testMode: true,
            soundEnabled: false,
            soundVolume: 0.5
        )

        persistenceManager.saveSettings(settings)

        let loaded = persistenceManager.loadSettings()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.focusDuration, 30)
        XCTAssertEqual(loaded?.baseBreakDuration, 10)
        XCTAssertEqual(loaded?.soundEnabled, false)
        XCTAssertEqual(loaded?.soundVolume, 0.5)
    }
}
