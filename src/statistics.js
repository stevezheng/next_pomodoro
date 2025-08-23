const { app } = require('electron')
const path = require('path')
const fs = require('fs')

class Statistics {
  constructor() {
    this.userDataPath = app.getPath('userData')
    this.statsPath = path.join(this.userDataPath, 'statistics.json')
    this.data = this.load()
  }
  
  load() {
    try {
      if (fs.existsSync(this.statsPath)) {
        const data = fs.readFileSync(this.statsPath, 'utf8')
        return JSON.parse(data)
      }
    } catch (error) {
      console.error('加载统计失败:', error)
    }
    return {
      sessions: [],
      totalPomodoros: 0,
      totalWorkTime: 0,
      totalBreakTime: 0,
      streakDays: 0,
      longestStreak: 0,
      dailyStats: {}
    }
  }
  
  save() {
    try {
      fs.writeFileSync(this.statsPath, JSON.stringify(this.data, null, 2))
    } catch (error) {
      console.error('保存统计失败:', error)
    }
  }
  
  recordSession(type, duration, completed = true) {
    const now = new Date()
    const today = now.toDateString()
    
    const session = {
      type,
      duration,
      completed,
      timestamp: now.toISOString(),
      date: today
    }
    
    this.data.sessions.push(session)
    
    if (completed) {
      if (type === 'work') {
        this.data.totalPomodoros++
        this.data.totalWorkTime += duration
      } else {
        this.data.totalBreakTime += duration
      }
      
      // 更新日统计
      if (!this.data.dailyStats[today]) {
        this.data.dailyStats[today] = {
          pomodoros: 0,
          workTime: 0,
          breakTime: 0
        }
      }
      
      if (type === 'work') {
        this.data.dailyStats[today].pomodoros++
        this.data.dailyStats[today].workTime += duration
      } else {
        this.data.dailyStats[today].breakTime += duration
      }
      
      this.updateStreak()
    }
    
    this.save()
  }
  
  updateStreak() {
    const pomodoroCount = this.getRecentDates(2).map(date => 
      this.getStatsForDate(date).pomodoros
    )
    
    if (pomodoroCount[0] === 0) return
    
    this.data.streakDays = pomodoroCount[1] > 0 ? this.data.streakDays + 1 : 1
    this.data.longestStreak = Math.max(this.data.streakDays, this.data.longestStreak)
  }

  getRecentDates(days) {
    const result = []
    for (let i = 0; i < days; i++) {
      const date = new Date(Date.now() - i * 24 * 60 * 60 * 1000)
      result.push(date.toDateString())
    }
    return result
  }
  
  getTodayStats() {
    return this.getStatsForDate(this.getRecentDates(1)[0])
  }

  getStatsForDate(date) {
    return this.data.dailyStats[date] || {
      pomodoros: 0,
      workTime: 0,
      breakTime: 0
    }
  }
  
  getWeekStats() {
    return this.getRecentDates(7)
      .reverse()
      .map(dateStr => ({
        date: dateStr,
        day: new Date(dateStr).toLocaleDateString('zh-CN', { weekday: 'short' }),
        ...this.getStatsForDate(dateStr)
      }))
  }
  
  exportToCSV() {
    const headers = ['日期', '类型', '时长(分钟)', '是否完成', '时间戳']
    const rows = [headers.join(',')]
    
    this.data.sessions.forEach(session => {
      const row = [
        session.date,
        session.type === 'work' ? '工作' : '休息',
        Math.round(session.duration / 60),
        session.completed ? '是' : '否',
        session.timestamp
      ]
      rows.push(row.join(','))
    })
    
    return rows.join('\n')
  }
  
  getAllStats() {
    return {
      totalPomodoros: this.data.totalPomodoros,
      totalWorkTime: Math.round(this.data.totalWorkTime / 60),
      totalBreakTime: Math.round(this.data.totalBreakTime / 60),
      streakDays: this.data.streakDays,
      longestStreak: this.data.longestStreak,
      todayStats: this.getTodayStats(),
      weekStats: this.getWeekStats()
    }
  }
}

module.exports = Statistics