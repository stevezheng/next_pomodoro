import { State } from './state'
import { Event, StateContext, TransitionResult, TimerState, EventType } from '@shared/types'
import { POMODORO_TIME } from '@shared/constants'

/**
 * Idle 状态实现
 * 未开始状态，等待用户启动番茄钟
 */
export class IdleState extends State {
  public handle(event: Event, context: StateContext): TransitionResult {
    switch (event.type) {
      case EventType.START:
        return {
          nextState: TimerState.FOCUS,
          timeLeft: POMODORO_TIME,
          shouldNotify: false
        }

      default:
        return {
          nextState: TimerState.IDLE,
          timeLeft: 0,
          shouldNotify: false
        }
    }
  }
}
