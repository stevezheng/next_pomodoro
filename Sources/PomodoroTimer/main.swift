import AppKit

// MARK: - 应用代理
class AppDelegate: NSObject, NSApplicationDelegate {
    private var pomodoroApp: PomodoroApp!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 初始化番茄钟应用
        pomodoroApp = PomodoroApp()

        // 设置应用为前台应用（虽然只显示 Menu Bar）
        NSApp.setActivationPolicy(.accessory)

        print("番茄钟已启动")
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("番茄钟已退出")
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return true
    }
}

// MARK: - 主入口
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
