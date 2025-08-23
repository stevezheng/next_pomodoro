class PomodoroTimer {
  constructor(settings) {
    this.settings = settings
    this.state = 'stopped'
    this.phase = 'work'
    this.completedPomodoros = 0
    this.interval = null
    this.timeLeft = this.getWorkTime()
    this.onTick = null
    this.onComplete = null
    
    this.actions = {
      stopped: () => this.start(),
      running: () => this.pause(), 
      paused: () => this.resume()
    }
  }
  
  getWorkTime() {
    return this.settings ? this.settings.get('workTime') * 60 : 25 * 60
  }
  
  getBreakTime() {
    return this.settings ? this.settings.get('breakTime') * 60 : 5 * 60
  }
  
  getLongBreakTime() {
    return this.settings ? this.settings.get('longBreakTime') * 60 : 15 * 60
  }
  
  getLongBreakInterval() {
    return this.settings ? this.settings.get('longBreakInterval') : 4
  }
  
  start() {
    if (this.state === 'stopped') {
      this.timeLeft = this.getWorkTime()
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
    if (this.state !== 'running') return
    this.state = 'paused'
    clearInterval(this.interval)
    
    if (this.onTick) {
      this.onTick(this.timeLeft, this.phase, this.state)
    }
  }

  resume() {
    if (this.state !== 'paused') return
    
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
    
    if (this.onTick) {
      this.onTick(this.timeLeft, this.phase, this.state)
    }
  }

  toggle() {
    this.actions[this.state]()
  }
  
  stop() {
    this.state = 'stopped'
    this.timeLeft = this.getWorkTime()
    this.phase = 'work'
    clearInterval(this.interval)
    
    if (this.onTick) {
      this.onTick(this.timeLeft, this.phase, this.state)
    }
  }
  
  complete() {
    clearInterval(this.interval)
    
    const completedPhase = this.phase
    
    if (this.phase === 'work') {
      this.completedPomodoros++
      if (this.completedPomodoros % this.getLongBreakInterval() === 0) {
        this.phase = 'longbreak'
        this.timeLeft = this.getLongBreakTime()
      } else {
        this.phase = 'break'
        this.timeLeft = this.getBreakTime()
      }
    } else {
      this.phase = 'work'
      this.timeLeft = this.getWorkTime()
    }
    
    this.state = 'stopped'
    
    if (this.onComplete) {
      this.onComplete(completedPhase, this.phase, this.completedPomodoros)
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