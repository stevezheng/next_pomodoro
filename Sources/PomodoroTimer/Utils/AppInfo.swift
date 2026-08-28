import Foundation

enum AppInfo {
    static let privacyPolicyURL = URL(string: "https://tomatoruler.seo10.de/privacy")!

    static var displayVersion: String {
        let version =
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "未知版本"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        guard let build, !build.isEmpty else {
            return version
        }
        return "\(version) (\(build))"
    }
}
