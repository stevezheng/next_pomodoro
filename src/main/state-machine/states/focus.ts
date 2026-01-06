import { State } from './state'
import { Event, StateContext, TransitionResult, TimerState, EventType, NotificationType } from '@shared/types'

/**
 * Focus 状态实现
 * 正常番茄专注状态
 */
export class FocusState extends State {
  public handle(event: Event, context: StateContext): TransitionResult {
    if (event.type === EventType.TIME_UP) {
      // 番茄时间结束，进入推迟状态（让用户选择）
      return {
        nextState: TimerState.SNOOZE,
        timeLeft: 0,
        shouldNotify: true,
        notificationType: NotificationType.FOCUS_COMPLETE
      }
    }

    // 其他事件保持当前状态
    return {
      nextState: TimerState.FOCUS,
      timeLeft: context.timeLeft,
      shouldNotify: false
    }
  }
}
