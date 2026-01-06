import Foundation
import Dispatch

/// 精确计时器 - 使用目标时间法避免累积误差
class PreciseTimer {
    private var timer: DispatchSourceTimer?
    private var targetEndTime: Date?
    private var onTick: ((Int) -> Void)?
    private var onComplete: (() -> Void)?

    var isRunning: Bool {
        timer != nil
    }

    /// 启动计时器（目标时间法）
    /// - Parameters:
    ///   - durationSeconds: 总时长（秒）
    ///   - onTick: 每秒回调，返回剩余秒数
    ///   - onComplete: 完成回调
    func start(
        durationSeconds: Int,
        onTick: @escaping (Int) -> Void,
        onComplete: @escaping () -> Void
    ) {
        stop()

        self.onTick = onTick
        self.onComplete = onComplete
        self.targetEndTime = Date().addingTimeInterval(TimeInterval(durationSeconds))

        let queue = DispatchQueue(label: "com.pomodoro.timer", qos: .userInteractive)
        timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)

        timer?.schedule(
            deadline: .now(),
            repeating: .seconds(1),
            leeway: .milliseconds(100)
        )

        timer?.setEventHandler { [weak self] in
            guard let self = self,
                  let endTime = self.targetEndTime else { return }

            let now = Date()
            let remaining = max(0, Int(endTime.timeIntervalSince(now)))

            DispatchQueue.main.async {
                if remaining > 0 {
                    onTick(remaining)
                } else {
                    self.stop()
                    onComplete()
                }
            }
        }

        timer?.resume()

        // 立即触发一次
        onTick(durationSeconds)
    }

    /// 停止计时器
    func stop() {
        timer?.cancel()
        timer = nil
        targetEndTime = nil
    }

    /// 暂停计时器，返回剩余时间
    @discardableResult
    func pause() -> Int {
        guard let endTime = targetEndTime else { return 0 }
        let remaining = max(0, Int(endTime.timeIntervalSince(Date())))
        stop()
        return remaining
    }

    /// 从剩余时间继续
    func resume(remainingSeconds: Int) {
        start(
            durationSeconds: remainingSeconds,
            onTick: onTick ?? { _ in },
            onComplete: onComplete ?? { }
        )
    }

    deinit {
        stop()
    }
}
