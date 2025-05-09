import Foundation

// MARK: - Alternating Work Schedule (交替排班：大小周)
struct AlternatingWorkSchedule: WorkSchedule {
    var workStartTime: Date
    var workEndTime: Date
    var lunchBreakStartTime: Date
    var lunchBreakEndTime: Date
    var dinnerStartTime: Date
    var dinnerEndTime: Date
    var currentWeekType: WeekType
    var holidayAutoRest: Bool // 节假日是否自动休息
    
    // 初始化方法
    init(workStartTime: Date, workEndTime: Date, lunchBreakStartTime: Date, lunchBreakEndTime: Date,
         dinnerStartTime: Date, dinnerEndTime: Date, currentWeekType: WeekType, holidayAutoRest: Bool = true) {
        self.workStartTime = workStartTime
        self.workEndTime = workEndTime
        self.lunchBreakStartTime = lunchBreakStartTime
        self.lunchBreakEndTime = lunchBreakEndTime
        self.dinnerStartTime = dinnerStartTime
        self.dinnerEndTime = dinnerEndTime
        self.currentWeekType = currentWeekType
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
        
        // 周末判断
        if weekday == 1 || weekday == 7 {
            // 根据当前周类型判断周末是否工作
            let weekType = getWeekType(for: date)
            
            if weekType == .bigWeek {
                // 大周：周六工作，周日休息
                return weekday == 7 ? .workDay : .restDay  // 修改为 .restDay
            } else {
                // 小周：周六周日都休息
                return .restDay  // 修改为 .restDay
            }
        }
        
        // 工作日
        return .workDay
    }
    
    // 获取指定日期的当前状态
    // 获取指定日期的当前状态
    func getCurrentStatus(date: Date) -> WorkStatus {
        let dayType = isWorkDay(date: date) // 获取日期类型
        
        switch dayType {
        case .holiday:
            return .holiday // 节假日
        case .restDay:
            return .weekend // 休息日（这里统一返回周末）
        case .workDay:
            // 如果是工作日，则检查具体时间状态
            return checkWorkTimeStatus(date: date)
        }
    }
    
    // 获取指定日期的周类型 (大周/小周)
    func getWeekType(for date: Date) -> WeekType {
        let calendar = Calendar.current
        
        // 获取当前日期所在周的周一
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        guard let monday = calendar.date(from: components) else {
            return currentWeekType // 如果无法计算，返回当前设置的周类型
        }
        
        // 计算从参考日期到当前周一的周数
        let referenceDate = calendar.startOfDay(for: Date()) // 使用今天作为参考日期
        components = calendar.dateComponents([.weekOfYear], from: referenceDate, to: monday)
        
        guard let weekDifference = components.weekOfYear else {
            return currentWeekType // 如果无法计算，返回当前设置的周类型
        }
        
        // 根据周数的奇偶性判断大小周
        if weekDifference % 2 == 0 {
            return currentWeekType // 偶数周，保持当前周类型
        } else {
            // 奇数周，切换周类型
            return currentWeekType == .bigWeek ? .smallWeek : .bigWeek
        }
    }
    
    // 计算给定日期之后的下一个状态变更事件
    func getNextEvent(after currentDate: Date) -> (date: Date, status: WorkStatus)? {
        return calculateNextEvent(after: currentDate)
    }
}
