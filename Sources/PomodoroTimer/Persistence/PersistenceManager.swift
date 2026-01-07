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
            let appData = try? JSONDecoder().decode(AppData.self, from: data)
        else {
            return nil
        }

        return (appData.timerState, appData.completedPomodoros, appData.settings)
    }

    // MARK: - 清除

    func clear() {
        userDefaults.removeObject(forKey: Constants.StorageKey.appData)
    }

    // MARK: - 今日统计

    /// 获取今日完成的番茄数
    func getTodayPomodoros() -> Int {
        checkAndResetDailyCount()
        return userDefaults.integer(forKey: Constants.StorageKey.todayPomodoros)
    }

    /// 增加今日番茄数
    func incrementTodayPomodoros() {
        checkAndResetDailyCount()
        let current = userDefaults.integer(forKey: Constants.StorageKey.todayPomodoros)
        userDefaults.set(current + 1, forKey: Constants.StorageKey.todayPomodoros)
    }

    /// 检查并在跨天时重置计数
    private func checkAndResetDailyCount() {
        let today = Calendar.current.startOfDay(for: Date())

        if let lastResetData = userDefaults.object(forKey: Constants.StorageKey.lastResetDate)
            as? Date
        {
            let lastResetDay = Calendar.current.startOfDay(for: lastResetData)
            if lastResetDay < today {
                // 跨天了，重置计数
                userDefaults.set(0, forKey: Constants.StorageKey.todayPomodoros)
                userDefaults.set(today, forKey: Constants.StorageKey.lastResetDate)
                Log.info("检测到跨天，已重置今日番茄计数")
            }
        } else {
            // 首次运行，设置今天的日期
            userDefaults.set(today, forKey: Constants.StorageKey.lastResetDate)
        }
    }

    // MARK: - 设置

    func saveSettings(_ settings: Settings) {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: Constants.StorageKey.settings)
        }
    }

    func loadSettings() -> Settings? {
        guard let data = userDefaults.data(forKey: Constants.StorageKey.settings),
            let settings = try? JSONDecoder().decode(Settings.self, from: data)
        else {
            return nil
        }
        return settings
    }
}
