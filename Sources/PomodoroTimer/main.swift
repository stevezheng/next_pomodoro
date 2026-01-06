import AppKit

// MARK: - 应用代理
class AppDelegate: NSObject, NSApplicationDelegate {
    // 必须强引用持有 PomodoroApp，否则会被释放
    var pomodoroApp: PomodoroApp!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 初始化番茄钟应用
        pomodoroApp = PomodoroApp()

        // 使用 regular 策略以确保弹窗能正常获得焦点
        // 但不显示在 Dock 中（通过 LSUIElement = true 在 Info.plist 中设置）
        NSApp.setActivationPolicy(.regular)

        print("番茄钟已启动")
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("番茄钟已退出")
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return true
    }

    // 当应用被激活时，确保能显示弹窗
    func applicationDidBecomeActive(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
}

// MARK: - 主入口
// 必须保持对 AppDelegate 的强引用
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
