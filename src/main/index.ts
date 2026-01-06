import { app, BrowserWindow } from 'electron'
import { StateMachine } from './state-machine'
import { Timer } from './timer'
import { AlertManager } from './notifications'
import { TrayManager } from './menu-bar'
import { PersistenceStore } from './persistence'
import { EventType, TimerState, NotificationType } from '@shared/types'

/**
 * 番茄时钟应用主类
 * 协调所有模块的工作
 */
class PomodoroApp {
  private stateMachine: StateMachine
  private timer: Timer
  private alertManager: AlertManager
  private trayManager: TrayManager
  private persistence: PersistenceStore
  private mainWindow: BrowserWindow | null = null

  constructor() {
    // 初始化所有模块
    this.stateMachine = new StateMachine()
    this.timer = new Timer()
    this.persistence = new PersistenceStore()
    this.mainWindow = this.createMainWindow()
    this.alertManager = new AlertManager(this.mainWindow)
    this.trayManager = new TrayManager()

    // 绑定事件
    this.bindEvents()
    this.bindStateMachineEvents()
    this.bindTrayEvents()

    // 尝试恢复之前的状态
    this.restoreState()
  }

  /**
   * 创建主窗口（隐藏，用于弹窗的父窗口）
   */
  private createMainWindow(): BrowserWindow {
    const win = new BrowserWindow({
      show: false,
      webPreferences: {
        nodeIntegration: true,
        contextIsolation: false
      }
    })
    return win
  }

  /**
   * 绑定状态机事件
   */
  private bindStateMachineEvents(): void {
    // 监听状态变化
    this.stateMachine.on('stateChanged', ({ currentState, context }) => {
      console.log(`状态变化: ${currentState}`)
      this.updateUI(currentState, context)
      this.saveState()
    })

    // 监听提醒事件
    this.stateMachine.on('notification', async ({ type, context }) => {
      await this.handleNotification(type, context)
    })

    // 监听时间变化
    this.stateMachine.on('tick', ({ timeLeft, context }) => {
      this.stateMachine.updateTimeLeft(timeLeft)
      this.trayManager.updateTitle(this.stateMachine.getCurrentState(), context)
    })
  }

  /**
   * 绑定 Tray 菜单事件
   */
  private bindTrayEvents(): void {
    this.trayManager.onAction((action: string) => {
      this.handleMenuAction(action)
    })
  }

  /**
   * 处理提醒事件
   */
  private async handleNotification(type: NotificationType, context: any): Promise<void> {
    switch (type) {
      case NotificationType.FOCUS_COMPLETE:
      case NotificationType.SNOOZE_COMPLETE:
        // 显示推迟选择弹窗
        const choice = await this.alertManager.showSnoozeAlert(context.snoozeCount)

        if (choice.action === 'break') {
          this.stateMachine.handleEvent({ type: EventType.START_BREAK })
        } else {
          // 更新上下文中的推迟数据
          const currentContext = this.stateMachine.getContext()
          const newContext = {
            ...currentContext,
            snoozeCount: currentContext.snoozeCount + 1,
            snoozeMinutes: currentContext.snoozeMinutes + choice.minutes
          }
          // 手动更新上下文
          ;(this.stateMachine as any).context = newContext

          this.stateMachine.handleEvent({
            type: EventType.SNOOZE,
            payload: choice.minutes
          })
        }
        break

      case NotificationType.FORCE_BREAK:
        // 显示强制休息弹窗
        await this.alertManager.showForceBreakAlert()
        // 状态已经在状态机中转换到 BREAK
        break

      case NotificationType.BREAK_COMPLETE:
        // 显示休息完成弹窗
        await this.alertManager.showBreakCompleteAlert()
        break
    }
  }

  /**
   * 处理菜单动作
   */
  private handleMenuAction(action: string): void {
    switch (action) {
      case 'start':
        this.startTimer()
        break
      case 'pause':
        this.pauseTimer()
        break
      case 'resume':
        this.resumeTimer()
        break
      case 'stop':
        this.stopTimer()
        break
      case 'startBreak':
        this.stateMachine.handleEvent({ type: EventType.START_BREAK })
        break
    }
  }

  /**
   * 更新 UI
   */
  private updateUI(state: TimerState, context: any): void {
    this.trayManager.updateTitle(state, context)
    this.trayManager.updateMenu(state)
  }

  /**
   * 启动计时器
   */
  private startTimer(): void {
    const result = this.stateMachine.handleEvent({ type: EventType.START })

    if (result.nextState === TimerState.FOCUS) {
      this.timer.start(
        result.timeLeft,
        (timeLeft) => {
          this.stateMachine.updateTimeLeft(timeLeft)
          this.trayManager.updateTitle(TimerState.FOCUS, this.stateMachine.getContext())
        },
        () => {
          this.stateMachine.handleEvent({ type: EventType.TIME_UP })
        }
      )
    }
  }

  /**
   * 暂停计时器
   */
  private pauseTimer(): void {
    const remaining = this.timer.pause()
    console.log(`计时器暂停，剩余 ${remaining} 秒`)
  }

  /**
   * 恢复计时器
   */
  private resumeTimer(): void {
    const context = this.stateMachine.getContext()
    this.timer.resume(
      context.timeLeft,
      (timeLeft) => {
        this.stateMachine.updateTimeLeft(timeLeft)
        this.trayManager.updateTitle(this.stateMachine.getCurrentState(), context)
      },
      () => {
        this.stateMachine.handleEvent({ type: EventType.TIME_UP })
      }
    )
  }

  /**
   * 停止计时器
   */
  private stopTimer(): void {
    this.timer.stop()
    // 重置到 Idle 状态
    ;(this.stateMachine as any).currentState = TimerState.IDLE
    ;(this.stateMachine as any).context.timeLeft = 0
    this.updateUI(TimerState.IDLE, this.stateMachine.getContext())
  }

  /**
   * 保存状态到持久化存储
   */
  private saveState(): void {
    this.persistence.saveContext(this.stateMachine.getContext())
  }

  /**
   * 恢复状态
   */
  private restoreState(): void {
    const savedContext = this.persistence.loadContext()
    if (savedContext.currentState && savedContext.currentState !== TimerState.IDLE) {
      this.stateMachine.restore(savedContext)
      this.updateUI(this.stateMachine.getCurrentState(), this.stateMachine.getContext())
      console.log('状态已恢复:', savedContext)
    }
  }

  /**
   * 绑定应用事件
   */
  private bindEvents(): void {
    app.on('before-quit', () => {
      this.saveState()
      this.trayManager.destroy()
    })

    app.on('window-all-closed', () => {
      // 不退出应用，保持 Menu Bar 运行
    })
  }
}

// 创建应用实例
let pomodoroApp: PomodoroApp | null = null

app.whenReady().then(() => {
  pomodoroApp = new PomodoroApp()
  console.log('番茄时钟应用已启动')
})

app.on('window-all-closed', () => {
  // macOS 上，即使所有窗口关闭也不退出应用
})

app.on('before-quit', () => {
  if (pomodoroApp) {
    // 清理工作
  }
})
