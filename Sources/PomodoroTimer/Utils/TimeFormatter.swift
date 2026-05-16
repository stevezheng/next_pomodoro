import Foundation

/// 时间格式化工具
enum TimeFormatter {

    /// 将秒数格式化为 mm:ss 格式
    /// - Parameter seconds: 总秒数
    /// - Returns: 格式化后的时间字符串，如 "25:00"
    static func format(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}
