/**
 * 番茄时钟状态枚举
 */
export enum TimerState {
  IDLE = 'idle',
  FOCUS = 'focus',
  SNOOZE = 'snooze',
  BREAK = 'break'
}

/**
 * 状态机上下文接口
 * 存储当前运行时的所有状态数据
 */
export interface StateContext {
  /** 当前状态 */
  currentState: TimerState
  /** 剩余时间（秒） */
  timeLeft: number
  /** 完成的番茄数 */
  completedPomodoros: number
  /** 当前轮次的推迟次数 */
  snoozeCount: number
  /** 当前轮次的累计推迟分钟数 */
  snoozeMinutes: number
}

/**
 * 事件类型枚举
 */
export enum EventType {
  /** 开始番茄钟 */
  START = 'start',
  /** 时间到 */
  TIME_UP = 'time_up',
  /** 推迟 */
  SNOOZE = 'snooze',
  /** 开始休息 */
  START_BREAK = 'start_break',
  /** 休息完成 */
  BREAK_COMPLETE = 'break_complete',
  /** 手动停止/打断 */
  STOP = 'stop'
}

/**
 * 事件接口
 */
export interface Event {
  type: EventType
  payload?: any
}

/**
 * 状态转换结果
 */
export interface TransitionResult {
  /** 下一个状态 */
  nextState: TimerState
  /** 剩余时间（秒） */
  timeLeft: number
  /** 是否需要显示提醒 */
  shouldNotify: boolean
  /** 提醒类型 */
  notificationType?: NotificationType
  /** 是否重置推迟计数 */
  shouldResetSnooze?: boolean
}

/**
 * 提醒类型
 */
export enum NotificationType {
  /** 番茄完成 */
  FOCUS_COMPLETE = 'focus_complete',
  /** 推迟完成 */
  SNOOZE_COMPLETE = 'snooze_complete',
  /** 强制休息 */
  FORCE_BREAK = 'force_break',
  /** 休息完成 */
  BREAK_COMPLETE = 'break_complete'
}

/**
 * 推迟选择结果
 */
export interface SnoozeChoice {
  action: 'break' | 'snooze'
  minutes: number
}
