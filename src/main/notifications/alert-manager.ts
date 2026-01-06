import { dialog, BrowserWindow } from 'electron'
import { SnoozeChoice } from '@shared/types'
import { SNOOZE_OPTIONS, ALERT_TITLES, MAX_SNOOZE_COUNT } from '@shared/constants'

/**
 * 系统弹窗管理器
 * 使用 macOS 原生 API，覆盖当前工作窗口
 */
export class AlertManager {
  private mainWindow: BrowserWindow | null = null

  constructor(mainWindow: BrowserWindow | null = null) {
    this.mainWindow = mainWindow
  }

  /**
   * 显示番茄完成弹窗（可推迟）
   * @param snoozeCount 当前推迟次数
   * @returns 用户选择
   */
  public async showSnoozeAlert(snoozeCount: number): Promise<SnoozeChoice> {
    const isLastChance = snoozeCount >= MAX_SNOOZE_COUNT - 1

    // 根据推迟次数确定语气
    let title = ALERT_TITLES.neutral
    let message = '本轮专注已结束'
    let detail = ''

    if (snoozeCount === 0) {
      title = ALERT_TITLES.neutral
      message = '🍅 本轮专注已结束'
    } else if (snoozeCount === 1) {
      title = ALERT_TITLES.warning
      message = '⚠️ 你已经推迟了一次'
    } else if (snoozeCount === 2) {
      title = ALERT_TITLES.lastWarning
      message = '⛔ 最后警告'
      detail = '这是最后一次推迟机会\n之后系统将强制进入休息'
    }

    // 构建按钮
    const buttons = isLastChance
      ? ['开始休息 ⭐', '推迟 5 分钟', '推迟 10 分钟', '推迟 15 分钟（最后一次）']
      : ['开始休息 ⭐', '推迟 5 分钟', '推迟 10 分钟', '推迟 15 分钟']

    const response = await dialog.showMessageBox(this.mainWindow || undefined, {
      type: isLastChance ? 'warning' : snoozeCount > 0 ? 'warning' : 'info',
      title,
      message,
      detail,
      buttons,
      defaultId: 0,
      cancelId: -1,
      noLink: true
    })

    const buttonIndex = response.response

    if (buttonIndex === 0) {
      return { action: 'break', minutes: 0 }
    } else {
      return {
        action: 'snooze',
        minutes: SNOOZE_OPTIONS[buttonIndex - 1]
      }
    }
  }

  /**
   * 显示强制休息弹窗（第3次推迟后）
   */
  public async showForceBreakAlert(): Promise<void> {
    await dialog.showMessageBox(this.mainWindow || undefined, {
      type: 'error',
      title: ALERT_TITLES.forceBreak,
      message: '🚫 已达到最大推迟次数',
      detail: '系统已强制进入休息\n你已经连续工作太久了\n现在必须休息',
      buttons: ['我知道了'],
      defaultId: 0,
      noLink: true
    })
  }

  /**
   * 显示休息完成弹窗
   */
  public async showBreakCompleteAlert(): Promise<void> {
    await dialog.showMessageBox(this.mainWindow || undefined, {
      type: 'info',
      title: ALERT_TITLES.breakComplete,
      message: '☕ 休息时间结束',
      detail: '休息完成了\n准备好开始下一个番茄了吗？',
      buttons: ['好的'],
      defaultId: 0,
      noLink: true
    })
  }

  /**
   * 显示番茄完成通知（非阻塞）
   */
  public showFocusCompleteNotification(): void {
    const notification = new Notification({
      title: '🍅 番茄完成',
      body: '专注时间结束，该休息了',
      silent: false
    })
    notification.show()
  }

  /**
   * 显示推迟完成通知（非阻塞）
   * @param snoozeCount 当前推迟次数
   */
  public showSnoozeCompleteNotification(snoozeCount: number): void {
    const notification = new Notification({
      title: snoozeCount >= 2 ? '⛔ 最后警告' : '⚠️ 推迟时间结束',
      body: snoozeCount >= 2 ? '最后一次机会！' : '请尽快开始休息',
      silent: false
    })
    notification.show()
  }

  /**
   * 显示休息完成通知（非阻塞）
   */
  public showBreakCompleteNotification(): void {
    const notification = new Notification({
      title: '☕ 休息完成',
      body: '准备好开始下一个番茄了吗？',
      silent: false
    })
    notification.show()
  }
}
