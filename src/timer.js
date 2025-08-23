class PomodoroTimer {
  constructor() {
    this.state = 'stopped' // stopped, running, paused
    this.phase = 'work' // work, break, longbreak
    this.timeLeft = 25 * 60 // 25分钟 = 1500秒
    this.completedPomodoros = 0
    this.interval = null
    
    this.WORK_TIME = 25 * 60
    this.BREAK_TIME = 5 * 60
    this.LONG_BREAK_TIME = 15 * 60
    
    this.onTick = null
    this.onComplete = null
  }
  
  start() {
    if (this.state === 'stopped') {
      this.timeLeft = this.WORK_TIME
      this.phase = 'work'
    }
    
    this.state = 'running'
    this.interval = setInterval(() => {
      this.timeLeft--
      
      if (this.onTick) {
        this.onTick(this.timeLeft, this.phase, this.state)
      }
      
      if (this.timeLeft <= 0) {
        this.complete()
      }
    }, 1000)
  }
  
  pause() {
    if (this.state === 'running') {
      this.state = 'paused'
      clearInterval(this.interval)
    } else if (this.state === 'paused') {
      this.start()
    }
  }
  
  stop() {
    this.state = 'stopped'
    this.timeLeft = this.WORK_TIME
    this.phase = 'work'
    clearInterval(this.interval)
    
    if (this.onTick) {
      this.onTick(this.timeLeft, this.phase, this.state)
    }
  }
  
  complete() {
    clearInterval(this.interval)
    
    if (this.phase === 'work') {
      this.completedPomodoros++
      if (this.completedPomodoros % 4 === 0) {
        this.phase = 'longbreak'
        this.timeLeft = this.LONG_BREAK_TIME
      } else {
        this.phase = 'break'
        this.timeLeft = this.BREAK_TIME
      }
    } else {
      this.phase = 'work'
      this.timeLeft = this.WORK_TIME
    }
    
    this.state = 'stopped'
    
    if (this.onComplete) {
      this.onComplete(this.phase, this.completedPomodoros)
    }
    
    if (this.onTick) {
      this.onTick(this.timeLeft, this.phase, this.state)
    }
  }
  
  formatTime(seconds) {
    const minutes = Math.floor(seconds / 60)
    const remainingSeconds = seconds % 60
    return `${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`
  }
  
  getStatus() {
    return {
      state: this.state,
      phase: this.phase,
      timeLeft: this.timeLeft,
      timeLeftFormatted: this.formatTime(this.timeLeft),
      completedPomodoros: this.completedPomodoros
    }
  }
}

module.exports = PomodoroTimer