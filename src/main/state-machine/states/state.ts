import { Event, StateContext, TransitionResult } from '@shared/types'

/**
 * 状态基类
 * 所有具体状态必须实现此接口
 */
export abstract class State {
  /**
   * 处理事件并返回状态转换结果
   * @param event 触发的事件
   * @param context 当前上下文
   * @returns 状态转换结果
   */
  public abstract handle(event: Event, context: StateContext): TransitionResult

  /**
   * 进入状态时的钩子（可选）
   * @param context 当前上下文
   */
  public onEnter?(context: StateContext): void

  /**
   * 离开状态时的钩子（可选）
   * @param context 当前上下文
   */
  public onExit?(context: StateContext): void
}
