import Foundation

// MARK: - Fixed Work Schedule (固定排班：根据每周工作日设置)
struct FixedWorkSchedule: WorkSchedule {
    var workStartTime: Date
    var workEndTime: Date
    var lunchBreakStartTime: Date
    var lunchBreakEndTime: Date
    var dinnerStartTime: Date
    var dinnerEndTime: Date
    var workingDays: [Bool] // 周一至周日的工作状态 [周一,周二,周三,周四,周五,周六,周日]
    var holidayAutoRest: Bool // 节假日是否自动休息
    
    // 初始化方法
    init(workStartTime: Date, workEndTime: Date, lunchBreakStartTime: Date, lunchBreakEndTime: Date, 
         dinnerStartTime: Date, dinnerEndTime: Date, workingDays: [Bool], holidayAutoRest: Bool = true) {
        self.workStartTime = workStartTime
        self.workEndTime = workEndTime
        self.lunchBreakStartTime = lunchBreakStartTime
        self.lunchBreakEndTime = lunchBreakEndTime
        self.dinnerStartTime = dinnerStartTime
        self.dinnerEndTime = dinnerEndTime
        self.workingDays = workingDays.count == 7 ? workingDays : [true, true, true, true, true, false, false]
        self.holidayAutoRest = holidayAutoRest
    }
    
    // 判断指定日期是否为工作日、休息日或节假日
    func isWorkDay(date: Date) -> WorkDayType {
        let calendar = Calendar.current
        
        // 检查是否是节假日
        if holidayAutoRest && HolidayManager.shared.isHoliday(date: date) {
            return .holiday
        }
        
        // 获取星期几 (1 = 周日, 2 = 周一, ..., 7 = 周六)
        let weekday = calendar.component(.weekday, from: date)
        // 转换为数组索引 (0 = 周一, 1 = 周二, ..., 6 = 周日)
        let index = (weekday + 5) % 7
        
        // 根据工作日设置判断
        if workingDays[index] {
            return .workDay
        } else {
            return .restDay
        }
    }
    
    // 获取指定日期的当前状态
    func getCurrentStatus(date: Date) -> WorkStatus {
        let dayType = isWorkDay(date: date) // 获取日期类型
        
        switch dayType {
        case .holiday:
            return .holiday // 节假日
        case .restDay:
            return .weekend // 休息日（这里统一返回周末，因为固定排班的休息日就是周末）
        case .workDay:
            // 如果是工作日，则检查具体时间状态
            return checkWorkTimeStatus(date: date)
        }
    }
    
    // 计算给定日期之后的下一个状态变更事件
    func getNextEvent(after currentDate: Date) -> (date: Date, status: WorkStatus)? {
        return calculateNextEvent(after: currentDate)
    }
}