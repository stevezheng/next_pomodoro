import Foundation

/// 数据持久化管理器
/// 支持本地存储（UserDefaults）和 iCloud 同步（NSUbiquitousKeyValueStore）
class PersistenceManager {
    private let userDefaults: UserDefaults
    private let cloudStore: NSUbiquitousKeyValueStore?
    private let enableiCloud: Bool

    init(userDefaults: UserDefaults = .standard, enableiCloud: Bool = true) {
        self.userDefaults = userDefaults
        self.enableiCloud = enableiCloud
        self.cloudStore = enableiCloud ? NSUbiquitousKeyValueStore.default : nil

        if enableiCloud {
            setupCloudSync()
        }
    }

    // MARK: - iCloud 同步设置

    private func setupCloudSync() {
        // 监听 iCloud 变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudStoreDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloudStore
        )

        // 同步到 iCloud
        cloudStore?.synchronize()

        Log.info("iCloud 同步已启用")
    }

    @objc private func iCloudStoreDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let changeReason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int
        else {
            return
        }

        // 处理外部变化（其他设备的修改）
        if changeReason == NSUbiquitousKeyValueStoreServerChange
            || changeReason == NSUbiquitousKeyValueStoreInitialSyncChange
        {

            if let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] {
                Log.info("检测到 iCloud 数据变化: \(changedKeys.joined(separator: ", "))")

                // 从 iCloud 同步到本地
                for key in changedKeys {
                    syncFromCloud(key: key)
                }
            }
        }
    }

    /// 从 iCloud 同步指定键的数据到本地
    private func syncFromCloud(key: String) {
        guard let cloudStore = cloudStore else { return }

        if let cloudData = cloudStore.data(forKey: key) {
            userDefaults.set(cloudData, forKey: key)
            Log.debug("已从 iCloud 同步 \(key) 到本地")
        }
    }

    /// 保存数据到本地和 iCloud
    private func saveData(_ data: Data, forKey key: String) {
        // 保存到本地
        userDefaults.set(data, forKey: key)

        // 保存到 iCloud
        if enableiCloud {
            cloudStore?.set(data, forKey: key)
            cloudStore?.synchronize()
            Log.debug("已保存 \(key) 到本地和 iCloud")
        } else {
            Log.debug("已保存 \(key) 到本地")
        }
    }

    /// 从本地或 iCloud 加载数据（优先使用本地，但会与 iCloud 比较时间戳）
    private func loadData(forKey key: String) -> Data? {
        let localData = userDefaults.data(forKey: key)

        // 如果没有启用 iCloud 或没有本地数据，直接返回
        guard enableiCloud, let cloudStore = cloudStore else {
            return localData
        }

        // 如果有 iCloud 数据，比较并选择最新的
        if let cloudData = cloudStore.data(forKey: key) {
            // 如果本地没有数据，使用 iCloud 数据
            if localData == nil {
                Log.info("本地无数据，使用 iCloud 数据")
                userDefaults.set(cloudData, forKey: key)
                return cloudData
            }

            // 如果数据不同，使用 iCloud 的（假设 iCloud 是最新的）
            if localData != cloudData {
                Log.info("检测到数据差异，使用 iCloud 数据")
                userDefaults.set(cloudData, forKey: key)
                return cloudData
            }
        }

        return localData
    }

    // MARK: - 保存

    func saveAppState(state: TimerState, pomodoros: Int, settings: Settings) {
        let data = AppData(
            timerState: state,
            completedPomodoros: pomodoros,
            settings: settings
        )

        if let encoded = try? JSONEncoder().encode(data) {
            saveData(encoded, forKey: Constants.StorageKey.appData)
        }
    }

    // MARK: - 读取

    func loadAppState() -> (TimerState, Int, Settings)? {
        guard let data = loadData(forKey: Constants.StorageKey.appData),
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
            saveData(encoded, forKey: Constants.StorageKey.settings)
        }
    }

    func loadSettings() -> Settings? {
        guard let data = loadData(forKey: Constants.StorageKey.settings),
            let settings = try? JSONDecoder().decode(Settings.self, from: data)
        else {
            return nil
        }
        return settings
    }

    // MARK: - iCloud 状态

    /// 检查 iCloud 是否可用
    func isiCloudAvailable() -> Bool {
        return cloudStore != nil && FileManager.default.ubiquityIdentityToken != nil
    }

    /// 手动触发 iCloud 同步
    func syncWithiCloud() {
        cloudStore?.synchronize()
        Log.info("手动触发 iCloud 同步")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
