/**
 * 应用常量配置
 */
import { TimerState } from './types'

/** 番茄时长（秒） */
export const POMODORO_TIME = 25 * 60

/** 基础休息时间（秒） */
export const BASE_BREAK_TIME = 5 * 60

/** 最大推迟次数 */
export const MAX_SNOOZE_COUNT = 3

/** 推迟选项（分钟） */
export const SNOOZE_OPTIONS = [5, 10, 15]

/** 状态图标 */
export const STATE_ICONS = {
  [TimerState.IDLE]: '🍅',
  [TimerState.FOCUS]: '🍅',
  [TimerState.SNOOZE]: '⛔',
  [TimerState.BREAK]: '☕'
} as const

/** 提醒标题配置 */
export const ALERT_TITLES = {
  neutral: '🍅',
  warning: '⚠️',
  lastWarning: '⛔',
  forceBreak: '🚫',
  breakComplete: '☕'
} as const

/** 菜单项文本 */
export const MENU_ITEMS = {
  START: '开始番茄钟',
  PAUSE: '暂停',
  RESUME: '继续',
  STOP: '停止',
  QUIT: '退出'
} as const

/** 存储键名 */
export const STORAGE_KEYS = {
  COMPLETED_POMODOROS: 'completedPomodoros',
  CURRENT_STATE: 'currentState',
  TIME_LEFT: 'timeLeft',
  SNOOZE_COUNT: 'snoozeCount',
  SNOOZE_MINUTES: 'snoozeMinutes'
} as const
