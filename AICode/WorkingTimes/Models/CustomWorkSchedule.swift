import Foundation

// MARK: - Custom Work Schedule (自定义排班：指定特定休息日)
struct CustomWorkSchedule: WorkSchedule {
    var workStartTime: Date
    var workEndTime: Date
    var lunchBreakStartTime: Date
    var lunchBreakEndTime: Date
    var dinnerStartTime: Date
    var dinnerEndTime: Date
    var customRestDays: [Date]
    var holidayAutoRest: Bool // 节假日是否自动休息
    
    // 初始化方法
    init(workStartTime: Date, workEndTime: Date, lunchBreakStartTime: Date, lunchBreakEndTime: Date,
         dinnerStartTime: Date, dinnerEndTime: Date, customRestDays: [Date], holidayAutoRest: Bool = true) {
        self.workStartTime = workStartTime
        self.workEndTime = workEndTime
        self.lunchBreakStartTime = lunchBreakStartTime
        self.lunchBreakEndTime = lunchBreakEndTime
        self.dinnerStartTime = dinnerStartTime
        self.dinnerEndTime = dinnerEndTime
        self.customRestDays = customRestDays
        self.holidayAutoRest = holidayAutoRest
    }
    
    // 判断指定日期是否为工作日、休息日或节假日
    func isWorkDay(date: Date) -> WorkDayType {
        let calendar = Calendar.current
        
        // 检查是否是节假日
        if holidayAutoRest && HolidayManager.shared.isHoliday(date: date) {
            return .holiday
        }
        
        // 检查是否是自定义休息日
        let dateOnly = calendar.startOfDay(for: date)
        for restDay in customRestDays {
            if calendar.isDate(dateOnly, inSameDayAs: restDay) {
                return .restDay
            }
        }
        
        // 获取星期几 (1 = 周日, 2 = 周一, ..., 7 = 周六)
        let weekday = calendar.component(.weekday, from: date)
        
        // 周末判断 - 修正：返回 .restDay 而不是 .weekend
        if weekday == 1 || weekday == 7 {
            return .restDay
        }
        
        // 默认为工作日
        return .workDay
    }
    
    // 获取指定日期的当前状态
    func getCurrentStatus(date: Date) -> WorkStatus {
        let dayType = isWorkDay(date: date) // 获取日期类型
        
        switch dayType {
        case .holiday:
            return .holiday // 节假日
        case .restDay:
            // 判断是否为周末
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: date)
            let isWeekend = weekday == 1 || weekday == 7
            
            if isWeekend {
                return .weekend // 如果是周末，返回 Weekend
            } else {
                return .restDay // 自定义休息日
            }
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