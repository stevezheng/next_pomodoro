import Store from 'electron-store'
import { StateContext } from '@shared/types'
import { STORAGE_KEYS } from '@shared/constants'

/**
 * 持久化存储接口
 */
export interface PersistedState {
  [STORAGE_KEYS.COMPLETED_POMODOROS]: number
  [STORAGE_KEYS.CURRENT_STATE]: string
  [STORAGE_KEYS.TIME_LEFT]: number
  [STORAGE_KEYS.SNOOZE_COUNT]: number
  [STORAGE_KEYS.SNOOZE_MINUTES]: number
}

/**
 * 数据持久化管理器
 * 使用 electron-store 保存应用状态
 */
export class PersistenceStore {
  private store: Store<PersistedState>

  constructor() {
    this.store = new Store<PersistedState>({
      name: 'pomodoro-timer-state',
      defaults: {
        [STORAGE_KEYS.COMPLETED_POMODOROS]: 0,
        [STORAGE_KEYS.CURRENT_STATE]: 'idle',
        [STORAGE_KEYS.TIME_LEFT]: 0,
        [STORAGE_KEYS.SNOOZE_COUNT]: 0,
        [STORAGE_KEYS.SNOOZE_MINUTES]: 0
      }
    })
  }

  /**
   * 保存状态上下文
   * @param context 状态上下文
   */
  public saveContext(context: StateContext): void {
    this.store.set(STORAGE_KEYS.COMPLETED_POMODOROS, context.completedPomodoros)
    this.store.set(STORAGE_KEYS.CURRENT_STATE, context.currentState)
    this.store.set(STORAGE_KEYS.TIME_LEFT, context.timeLeft)
    this.store.set(STORAGE_KEYS.SNOOZE_COUNT, context.snoozeCount)
    this.store.set(STORAGE_KEYS.SNOOZE_MINUTES, context.snoozeMinutes)
  }

  /**
   * 加载状态上下文
   * @returns 状态上下文（部分可能为 undefined）
   */
  public loadContext(): Partial<StateContext> {
    return {
      completedPomodoros: this.store.get(STORAGE_KEYS.COMPLETED_POMODOROS, 0),
      currentState: this.store.get(STORAGE_KEYS.CURRENT_STATE, 'idle') as any,
      timeLeft: this.store.get(STORAGE_KEYS.TIME_LEFT, 0),
      snoozeCount: this.store.get(STORAGE_KEYS.SNOOZE_COUNT, 0),
      snoozeMinutes: this.store.get(STORAGE_KEYS.SNOOZE_MINUTES, 0)
    }
  }

  /**
   * 清除所有保存的数据
   */
  public clear(): void {
    this.store.clear()
  }

  /**
   * 获取完成的番茄数
   */
  public getCompletedPomodoros(): number {
    return this.store.get(STORAGE_KEYS.COMPLETED_POMODOROS, 0)
  }

  /**
   * 增加完成的番茄数
   */
  public incrementCompletedPomodoros(): void {
    const current = this.getCompletedPomodoros()
    this.store.set(STORAGE_KEYS.COMPLETED_POMODOROS, current + 1)
  }
}
