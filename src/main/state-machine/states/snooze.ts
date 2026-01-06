import { State } from './state'
import { Event, StateContext, TransitionResult, TimerState, EventType, NotificationType } from '@shared/types'
import { calculateBreakTime, minutesToSeconds } from '@shared/utils/time'
import { MAX_SNOOZE_COUNT } from '@shared/constants'

/**
 * Snooze 状态实现
 * 推迟状态（违规阶段）
 */
export class SnoozeState extends State {
  public handle(event: Event, context: StateContext): TransitionResult {
    if (event.type === EventType.TIME_UP) {
      // 推迟时间结束
      if (context.snoozeCount >= MAX_SNOOZE_COUNT) {
        // 已达到最大推迟次数，强制进入休息
        const breakTime = calculateBreakTime(context.snoozeMinutes)
        return {
          nextState: TimerState.BREAK,
          timeLeft: breakTime,
          shouldNotify: true,
          notificationType: NotificationType.FORCE_BREAK,
          shouldResetSnooze: true
        }
      } else {
        // 还可以继续推迟，再次询问
        return {
          nextState: TimerState.SNOOZE,
          timeLeft: 0,
          shouldNotify: true,
          notificationType: NotificationType.SNOOZE_COMPLETE
        }
      }
    }

    if (event.type === EventType.SNOOZE) {
      // 用户选择推迟
      const minutes = event.payload as number
      return {
        nextState: TimerState.SNOOZE,
        timeLeft: minutesToSeconds(minutes),
        shouldNotify: false
      }
    }

    if (event.type === EventType.START_BREAK) {
      // 用户选择开始休息
      const breakTime = calculateBreakTime(context.snoozeMinutes)
      return {
        nextState: TimerState.BREAK,
        timeLeft: breakTime,
        shouldNotify: false,
        shouldResetSnooze: true
      }
    }

    if (event.type === EventType.STOP) {
      // 手动停止，取消推迟，直接回到 Idle
      return {
        nextState: TimerState.IDLE,
        timeLeft: 0,
        shouldNotify: false,
        shouldResetSnooze: true
      }
    }

    // 其他事件保持当前状态
    return {
      nextState: TimerState.SNOOZE,
      timeLeft: context.timeLeft,
      shouldNotify: false
    }
  }
}
