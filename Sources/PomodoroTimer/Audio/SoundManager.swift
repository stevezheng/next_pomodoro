import AVFoundation
import AppKit

/// 声音提醒管理器
class SoundManager {
    static let shared = SoundManager()

    private var audioPlayer: AVAudioPlayer?

    /// 声音设置
    var isEnabled: Bool = true
    var volume: Float = 0.8  // 0.0 - 1.0

    private init() {}

    // MARK: - 播放系统声音

    /// 播放专注结束提示音
    func playFocusComplete() {
        guard isEnabled else { return }
        playSystemSound(.glass)
    }

    /// 播放休息结束提示音
    func playBreakComplete() {
        guard isEnabled else { return }
        playSystemSound(.ping)
    }

    /// 播放推迟警告音
    func playSnoozeWarning() {
        guard isEnabled else { return }
        playSystemSound(.basso)
    }

    /// 播放休息开始提示音
    func playBreakStart() {
        guard isEnabled else { return }
        playSystemSound(.hero)
    }

    // MARK: - 系统声音

    enum SystemSound: String {
        case glass = "Glass"
        case ping = "Ping"
        case basso = "Basso"
        case hero = "Hero"
        case funk = "Funk"
        case pop = "Pop"
        case sosumi = "Sosumi"
        case tink = "Tink"
        case blow = "Blow"
        case bottle = "Bottle"
        case frog = "Frog"
        case morse = "Morse"
        case purr = "Purr"
        case submarine = "Submarine"
    }

    private func playSystemSound(_ sound: SystemSound) {
        let soundPath = "/System/Library/Sounds/\(sound.rawValue).aiff"
        let url = URL(fileURLWithPath: soundPath)

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = volume
            audioPlayer?.play()
        } catch {
            Log.error("无法播放声音: \(error.localizedDescription)")
            // 备用方案：使用 NSSound
            if let nsSound = NSSound(named: NSSound.Name(sound.rawValue)) {
                nsSound.volume = volume
                nsSound.play()
            }
        }
    }

    // MARK: - 配置

    func configure(enabled: Bool, volume: Float) {
        self.isEnabled = enabled
        self.volume = max(0.0, min(1.0, volume))
    }
}
