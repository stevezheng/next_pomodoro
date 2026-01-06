import { State } from './state'
import { Event, StateContext, TransitionResult, TimerState, EventType, NotificationType } from '@shared/types'

/**
 * Break 状态实现
 * 休息状态
 */
export class BreakState extends State {
  public handle(event: Event, context: StateContext): TransitionResult {
    if (event.type === EventType.TIME_UP) {
      // 休息结束，回到空闲状态
      return {
        nextState: TimerState.IDLE,
        timeLeft: 0,
        shouldNotify: true,
        notificationType: NotificationType.BREAK_COMPLETE,
        shouldResetSnooze: true
      }
    }

    // 其他事件保持当前状态
    return {
      nextState: TimerState.BREAK,
      timeLeft: context.timeLeft,
      shouldNotify: false
    }
  }
}
