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

    // 注意：不再监听 'tick' 事件，因为在计时器回调中直接处理 UI 更新
    // 避免 updateTimeLeft → emit('tick') → updateTimeLeft 的无限递归
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
    // 状态改变时重置暂停状态
    this.trayManager.setPaused(false)
  }

  /**
   * 启动计时器
   */
  private startTimer(): void {
    console.log('启动计时器...')
    this.trayManager.setPaused(false)
    const result = this.stateMachine.handleEvent({ type: EventType.START })
    console.log('状态转换结果:', result)

    if (result.nextState === TimerState.FOCUS) {
      console.log('启动 Focus 计时器，时长:', result.timeLeft, '秒')
      this.timer.start(
        result.timeLeft,
        (timeLeft) => {
          this.stateMachine.updateTimeLeft(timeLeft)
          this.trayManager.updateTitle(TimerState.FOCUS, this.stateMachine.getContext())
        },
        () => {
          console.log('计时器时间到！')
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
    this.trayManager.setPaused(true)
    this.trayManager.updateMenu(this.stateMachine.getCurrentState())
  }

  /**
   * 恢复计时器
   */
  private resumeTimer(): void {
    const context = this.stateMachine.getContext()
    this.trayManager.setPaused(false)
    this.trayManager.updateMenu(this.stateMachine.getCurrentState())

    this.timer.resume(
      context.timeLeft,
      (timeLeft) => {
        this.stateMachine.updateTimeLeft(timeLeft)
        // 实时获取最新的 context，而不是使用闭包中的旧引用
        this.trayManager.updateTitle(this.stateMachine.getCurrentState(), this.stateMachine.getContext())
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
    console.log('停止计时器')
    this.timer.stop()
    this.trayManager.setPaused(false)
    // 通过状态机处理停止事件，让状态机决定如何转换
    this.stateMachine.handleEvent({ type: EventType.STOP })
    this.updateUI(this.stateMachine.getCurrentState(), this.stateMachine.getContext())
    this.saveState()
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
      const currentState = this.stateMachine.getCurrentState()
      const timeLeft = this.stateMachine.getContext().timeLeft

      this.updateUI(currentState, this.stateMachine.getContext())
      console.log('状态已恢复:', savedContext)

      // 如果是 FOCUS 或 BREAK 状态，启动计时器
      if (currentState === TimerState.FOCUS || currentState === TimerState.BREAK) {
        console.log(`恢复计时器，状态: ${currentState}, 剩余时间: ${timeLeft} 秒`)
        this.timer.resume(
          timeLeft,
          (tickTimeLeft) => {
            this.stateMachine.updateTimeLeft(tickTimeLeft)
            this.trayManager.updateTitle(this.stateMachine.getCurrentState(), this.stateMachine.getContext())
          },
          () => {
            console.log('恢复的计时器时间到！')
            this.stateMachine.handleEvent({ type: EventType.TIME_UP })
          }
        )
      }
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
