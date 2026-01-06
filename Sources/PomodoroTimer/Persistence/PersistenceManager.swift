import Foundation

/// 数据持久化管理器
class PersistenceManager {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - 保存

    func saveAppState(state: TimerState, pomodoros: Int, settings: Settings) {
        let data = AppData(
            timerState: state,
            completedPomodoros: pomodoros,
            settings: settings
        )

        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: Constants.StorageKey.appData)
        }
    }

    // MARK: - 读取

    func loadAppState() -> (TimerState, Int, Settings)? {
        guard let data = userDefaults.data(forKey: Constants.StorageKey.appData),
              let appData = try? JSONDecoder().decode(AppData.self, from: data) else {
            return nil
        }

        return (appData.timerState, appData.completedPomodoros, appData.settings)
    }

    // MARK: - 清除

    func clear() {
        userDefaults.removeObject(forKey: Constants.StorageKey.appData)
    }
}
