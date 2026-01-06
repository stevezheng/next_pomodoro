import { TimerState, StateContext } from '@shared/types'
import { formatTime } from '@shared/utils/time'
import { STATE_ICONS } from '@shared/constants'

/**
 * Menu Bar 标题格式化工具
 * 根据状态生成合适的显示文本
 */
export class TitleFormatter {
  /**
   * 格式化 Menu Bar 标题
   * @param state 当前状态
   * @param context 状态上下文
   * @returns 格式化后的标题
   */
  public static format(state: TimerState, context: StateContext): string {
    switch (state) {
      case TimerState.IDLE:
        return STATE_ICONS[TimerState.IDLE]

      case TimerState.FOCUS:
        return `${STATE_ICONS[TimerState.FOCUS]} ${formatTime(context.timeLeft)}`

      case TimerState.SNOOZE:
        // 显示累计推迟时间（测试模式：秒）
        return `${STATE_ICONS[TimerState.SNOOZE]} +${context.snoozeMinutes}s`

      case TimerState.BREAK:
        return `${STATE_ICONS[TimerState.BREAK]} ${formatTime(context.timeLeft)}`

      default:
        return '🍅'
    }
  }

  /**
   * 获取状态的简短描述
   * @param state 当前状态
   * @returns 状态描述
   */
  public static getStatusText(state: TimerState): string {
    switch (state) {
      case TimerState.IDLE:
        return '未开始'
      case TimerState.FOCUS:
        return '专注中'
      case TimerState.SNOOZE:
        return '推迟中'
      case TimerState.BREAK:
        return '休息中'
      default:
        return '未知状态'
    }
  }
}
