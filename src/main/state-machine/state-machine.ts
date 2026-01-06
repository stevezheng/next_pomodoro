import { EventEmitter } from 'events'
import { TimerState, EventType, Event, StateContext, TransitionResult, NotificationType } from '@shared/types'
import { IdleState } from './states/idle'
import { FocusState } from './states/focus'
import { SnoozeState } from './states/snooze'
import { BreakState } from './states/break'
import { State } from './states/state'

/**
 * 状态机核心类
 * 遵循原则：状态转换驱动一切，严禁 if-else 堆逻辑
 */
export class StateMachine extends EventEmitter {
  private currentState: TimerState
  private context: StateContext
  private states: Map<TimerState, State>

  constructor() {
    super()
    this.currentState = TimerState.IDLE
    this.states = new Map()
    this.context = this.initializeContext()
    this.registerStates()
  }

  /**
   * 初始化上下文
   */
  private initializeContext(): StateContext {
    return {
      currentState: TimerState.IDLE,
      timeLeft: 0,
      completedPomodoros: 0,
      snoozeCount: 0,
      snoozeMinutes: 0
    }
  }

  /**
   * 注册所有状态
   */
  private registerStates(): void {
    this.states.set(TimerState.IDLE, new IdleState())
    this.states.set(TimerState.FOCUS, new FocusState())
    this.states.set(TimerState.SNOOZE, new SnoozeState())
    this.states.set(TimerState.BREAK, new BreakState())
  }

  /**
   * 处理事件
   * @param event 触发的事件
   * @returns 状态转换结果
   */
  public handleEvent(event: Event): TransitionResult {
    const currentStateHandler = this.states.get(this.currentState)

    if (!currentStateHandler) {
      throw new Error(`Invalid state: ${this.currentState}`)
    }

    // 执行状态转换
    const result = currentStateHandler.handle(event, this.context)

    // 调用当前状态的 onExit
    if (currentStateHandler.onExit) {
      currentStateHandler.onExit(this.context)
    }

    // 更新状态和上下文
    const previousState = this.currentState
    this.currentState = result.nextState
    this.context.timeLeft = result.timeLeft

    // 处理推迟计数
    if (result.shouldResetSnooze !== undefined) {
      if (result.shouldResetSnooze) {
        this.context.snoozeCount = 0
        this.context.snoozeMinutes = 0
      }
    }

    // 调用新状态的 onEnter
    const newStateHandler = this.states.get(this.currentState)
    if (newStateHandler?.onEnter) {
      newStateHandler.onEnter(this.context)
    }

    // 如果完成了一个番茄（Focus → Snooze/Break）
    if (previousState === TimerState.FOCUS && this.currentState === TimerState.SNOOZE) {
      this.context.completedPomodoros++
    }

    // 触发状态变化事件
    this.emit('stateChanged', {
      previousState,
      currentState: this.currentState,
      context: { ...this.context }
    })

    // 触发提醒事件
    if (result.shouldNotify && result.notificationType) {
      this.emit('notification', {
        type: result.notificationType,
        context: { ...this.context }
      })
    }

    return result
  }

  /**
   * 更新剩余时间（由计时器调用）
   * @param timeLeft 剩余时间（秒）
   */
  public updateTimeLeft(timeLeft: number): void {
    this.context.timeLeft = timeLeft
    this.emit('tick', { timeLeft, context: { ...this.context } })
  }

  /**
   * 获取当前状态
   */
  public getCurrentState(): TimerState {
    return this.currentState
  }

  /**
   * 获取上下文
   */
  public getContext(): StateContext {
    return { ...this.context }
  }

  /**
   * 从持久化数据恢复状态
   * @param savedContext 保存的上下文
   */
  public restore(savedContext: Partial<StateContext>): void {
    if (savedContext.currentState !== undefined) {
      this.currentState = savedContext.currentState
    }
    if (savedContext.timeLeft !== undefined) {
      this.context.timeLeft = savedContext.timeLeft
    }
    if (savedContext.completedPomodoros !== undefined) {
      this.context.completedPomodoros = savedContext.completedPomodoros
    }
    if (savedContext.snoozeCount !== undefined) {
      this.context.snoozeCount = savedContext.snoozeCount
    }
    if (savedContext.snoozeMinutes !== undefined) {
      this.context.snoozeMinutes = savedContext.snoozeMinutes
    }
  }
}
