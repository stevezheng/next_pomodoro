/**
 * 时间格式化工具
 */

/**
 * 将秒数格式化为 MM:SS 格式
 * @param seconds 秒数
 * @returns 格式化后的时间字符串
 */
export function formatTime(seconds: number): string {
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`
}

/**
 * 将分钟数转换为秒数
 * @param minutes 分钟数
 * @returns 秒数
 */
export function minutesToSeconds(minutes: number): number {
  return minutes * 60
}

/**
 * 计算休息时间
 * 公式：基础时间 + floor(累计推迟秒 ÷ 5)
 * 测试模式：5秒 + floor(累计推迟秒 ÷ 5)
 * @param totalSnoozeSeconds 累计推迟秒数
 * @returns 休息时间（秒）
 */
export function calculateBreakTime(totalSnoozeSeconds: number): number {
  const BASE_TIME = 5  // 测试模式：5秒基础休息
  const penalty = Math.floor(totalSnoozeSeconds / 5)
  return BASE_TIME + penalty
}
