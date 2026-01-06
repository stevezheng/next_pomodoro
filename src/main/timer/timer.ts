/**
 * 精确计时器
 * 使用目标时间法避免累积误差
 */

type TimerCallback = (timeLeft: number) => void
type CompleteCallback = () => void

export class Timer {
  private intervalId: NodeJS.Timeout | null = null
  private expectedEndTime: number | null = null
  private onTickCallback: TimerCallback | null = null
  private onCompleteCallback: CompleteCallback | null = null
  private isRunning: boolean = false

  /**
   * 启动计时器
   * @param duration 持续时间（秒）
   * @param onTick 每秒回调
   * @param onComplete 完成回调
   */
  public start(
    duration: number,
    onTick: TimerCallback,
    onComplete: CompleteCallback
  ): void {
    if (this.isRunning) {
      this.stop()
    }

    this.onTickCallback = onTick
    this.onCompleteCallback = onComplete
    this.isRunning = true
    this.expectedEndTime = Date.now() + duration * 1000

    // 立即回调一次初始时间
    onTick(duration)

    // 使用较短的间隔检查时间，保证精度
    this.intervalId = setInterval(() => {
      const now = Date.now()
      const remaining = Math.max(0, Math.ceil((this.expectedEndTime! - now) / 1000))

      // 只在秒数变化时回调
      if (this.onTickCallback && remaining > 0) {
        this.onTickCallback(remaining)
      }

      if (remaining === 0) {
        this.stop()
        if (this.onCompleteCallback) {
          this.onCompleteCallback()
        }
      }
    }, 100) // 100ms 检查一次，保证精度
  }

  /**
   * 停止计时器
   */
  public stop(): void {
    if (this.intervalId) {
      clearInterval(this.intervalId)
      this.intervalId = null
    }
    this.isRunning = false
    this.expectedEndTime = null
  }

  /**
   * 暂停计时器
   * @returns 剩余时间（秒）
   */
  public pause(): number {
    if (!this.isRunning || !this.expectedEndTime) {
      return 0
    }

    const now = Date.now()
    const remaining = Math.max(0, Math.ceil((this.expectedEndTime - now) / 1000))
    this.stop()
    return remaining
  }

  /**
   * 恢复计时器
   * @param remainingTime 剩余时间（秒）
   * @param onTick 每秒回调
   * @param onComplete 完成回调
   */
  public resume(
    remainingTime: number,
    onTick: TimerCallback,
    onComplete: CompleteCallback
  ): void {
    this.start(remainingTime, onTick, onComplete)
  }

  /**
   * 检查是否正在运行
   */
  public isActive(): boolean {
    return this.isRunning
  }
}
