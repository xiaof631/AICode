import Foundation

// MARK: - Week Type for Alternating Schedule (大小周类型，用于交替排班)
enum WeekType: String, CaseIterable, Identifiable {
    case bigWeek = "Big Week"  // 大周：周一至周六工作，周日休息
    case smallWeek = "Small Week"  // 小周：周一至周五工作，周六周日休息
    
    var id: String {
        self.rawValue
    } // 唯一标识符
    
    // 本地化名称
    var localizedName: String {
        switch self {
        case .bigWeek:
            return NSLocalizedString(
                "6-Day Week",
                comment: "Work Monday to Saturday"
            ) // 6天工作周
        case .smallWeek:
            return NSLocalizedString(
                "5-Day Week",
                comment: "Work Monday to Friday"
            ) // 5天工作周
        }
    }
}

// MARK: - Work Schedule Types (工作排班类型)
enum WorkScheduleType: String, CaseIterable, Identifiable {
    case fixed = "Fixed"        // 固定排班
    case alternating = "Alternating" // 交替排班 (大小周)
    case shift = "Shift"        // 轮班制
    case custom = "Custom"      // 自定义排班
    
    var id: String {
        self.rawValue
    } // 唯一标识符
    
    // 本地化名称
    var localizedName: String {
        switch self {
        case .fixed:
            return NSLocalizedString(
                "Fixed",
                comment: "Fixed schedule type"
            ) // 固定
        case .alternating:
            return NSLocalizedString(
                "Alternating",
                comment: "Alternating schedule type"
            ) // 交替
        case .shift:
            return NSLocalizedString(
                "Shift",
                comment: "Shift schedule type"
            ) // 轮班
        case .custom:
            return NSLocalizedString(
                "Custom",
                comment: "Custom schedule type"
            ) // 自定义
        }
    }
}

// MARK: - Work Status (当前工作状态)
enum WorkStatus: String, CaseIterable, Identifiable {
    case working = "Working"
    case lunchBreak = "Lunch Break"
    case dinnerBreak = "Dinner Break" // 晚餐状态
    case offWork = "Off Work"
    case weekend = "Weekend"
    case holiday = "Holiday"
    case restDay = "Rest Day" // 非周末的休息日
    
    var id: String {
        self.rawValue
    }
    
    // 提供本地化的状态名称 (如果需要的话)
    var localizedName: String {
        NSLocalizedString(
            self.rawValue,
            comment: "Work status"
        )
    }
}

// MARK: - Work Day Type (日期类型)
enum WorkDayType: String {
    case workDay = "Work Day" // 工作日
    case restDay = "Rest Day" // 休息日 (包括周末和自定义休息日)
    case holiday = "Holiday"  // 节假日
}

// MARK: - Base Work Schedule Protocol (基础工作排班协议)
protocol WorkSchedule {
    var workStartTime: Date {
        get set
    }       // 工作开始时间
    var workEndTime: Date {
        get set
    }         // 工作结束时间
    var lunchBreakStartTime: Date {
        get set
    } // 午休开始时间
    var lunchBreakEndTime: Date {
        get set
    }   // 午休结束时间
    var dinnerStartTime: Date {
        get set
    }     // 晚餐开始时间
    var dinnerEndTime: Date {
        get set
    }       // 晚餐结束时间
    
    // 获取指定日期的当前状态
    func getCurrentStatus(
        date: Date
    ) -> WorkStatus
    // 判断指定日期是否为工作日、休息日或节假日
    func isWorkDay(
        date: Date
    ) -> WorkDayType
    
    // 计算给定日期之后的下一个状态变更事件
    func getNextEvent(after currentDate: Date) -> (date: Date, status: WorkStatus)?
}

// MARK: - Fixed Work Schedule (Mon-Fri) (固定排班：周一至周五工作)
struct FixedWorkSchedule: WorkSchedule {
    var workStartTime: Date
    var workEndTime: Date
    var lunchBreakStartTime: Date
    var lunchBreakEndTime: Date
    var dinnerStartTime: Date // 新增
    var dinnerEndTime: Date   // 新增
    var workingDays: [Bool] // 新增：周一至周日的工作状态 [周一,周二,周三,周四,周五,周六,周日]
    
    // 判断指定日期是否为工作日
    func isWorkDay(
        date: Date
    ) -> WorkDayType {
        let calendar = Calendar.current
        let weekday = calendar.component(
            .weekday,
            from: date
        ) // 获取星期几
        
        // 检查是否为公共节假日
        if HolidayManager.shared
            .isHoliday(
                date: date
            ) {
            return .holiday
        }
        
        // 1 = 周日, 2 = 周一, ..., 7 = 周六
        // 将日历的星期几转换为数组索引 (0 = 周一, 1 = 周二, ..., 6 = 周日)
        let dayIndex = (weekday + 5) % 7
        
        // 检查该天是否设置为工作日
        return workingDays[dayIndex] ? .workDay : .restDay
    }
    
    // 获取指定日期的当前状态
    func getCurrentStatus(
        date: Date
    ) -> WorkStatus {
        let dayType = isWorkDay(
            date: date
        ) // 获取日期类型
        
        switch dayType {
        case .holiday:
            return .holiday // 节假日
        case .restDay:
            return .weekend // 休息日（这里统一返回周末，因为固定排班的休息日就是周末）
        case .workDay:
            // 如果是工作日，则检查具体时间状态
            return checkWorkTimeStatus(
                date: date
            )
        }
    }
    
    // 检查工作日内具体时间的状态
    private func checkWorkTimeStatus(
        date: Date
    ) -> WorkStatus {
        let calendar = Calendar.current
        let now = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: date
        )
        let workStart = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: workStartTime
        )
        let workEnd = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: workEndTime
        )
        let lunchStart = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: lunchBreakStartTime
        )
        let lunchEnd = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: lunchBreakEndTime
        )
        // Use the struct's own dinner time properties
        let dinnerStart = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: dinnerStartTime
        ) // Add this line
        let dinnerEnd = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: dinnerEndTime
        )     // Add this line
        
        let nowMinutes = (
            now.hour ?? 0
        ) * 60 + (
            now.minute ?? 0
        )
        let workStartMinutes = (
            workStart.hour ?? 0
        ) * 60 + (
            workStart.minute ?? 0
        )
        let workEndMinutes = (
            workEnd.hour ?? 0
        ) * 60 + (
            workEnd.minute ?? 0
        )
        let lunchStartMinutes = (
            lunchStart.hour ?? 0
        ) * 60 + (
            lunchStart.minute ?? 0
        )
        let lunchEndMinutes = (
            lunchEnd.hour ?? 0
        ) * 60 + (
            lunchEnd.minute ?? 0
        )
        let dinnerStartMinutes = (
            dinnerStart.hour ?? 0
        ) * 60 + (
            dinnerStart.minute ?? 0
        ) // Add this line
        let dinnerEndMinutes = (
            dinnerEnd.hour ?? 0
        ) * 60 + (
            dinnerEnd.minute ?? 0
        )     // Add this line
        
        // Update the status check logic to include dinner break
        if nowMinutes < workStartMinutes || nowMinutes >= workEndMinutes {
            // Check for dinner break even when off work
            if nowMinutes >= dinnerStartMinutes && nowMinutes < dinnerEndMinutes {
                return .dinnerBreak
            }
            return .offWork
        } else if nowMinutes >= lunchStartMinutes && nowMinutes < lunchEndMinutes {
            return .lunchBreak
        } else if nowMinutes >= dinnerStartMinutes && nowMinutes < dinnerEndMinutes {
            // Check for dinner break during work hours
            return .dinnerBreak
        } else {
            return .working
        }
    }
    
    // --- 添加 getNextEvent 方法的实现 ---
    func getNextEvent(after currentDate: Date) -> (date: Date, status: WorkStatus)? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: currentDate)
        
        // 辅助函数：合并日期和时间部分
        func combine(date: Date, time: Date) -> Date {
            let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
            return calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                 minute: timeComponents.minute ?? 0,
                                 second: timeComponents.second ?? 0,
                                 of: date) ?? date
        }
        
        var potentialEvents: [(date: Date, status: WorkStatus)] = []
        var searchDate = today // 从今天开始搜索
        
        // 循环查找未来最多（例如）7天内的事件，避免无限循环
        for _ in 0..<7 {
            let workDayType = self.isWorkDay(date: searchDate)
            
            if workDayType == .workDay {
                // 获取当天的所有时间点
                let workStart = combine(date: searchDate, time: workStartTime)
                let lunchStart = combine(date: searchDate, time: lunchBreakStartTime)
                let lunchEnd = combine(date: searchDate, time: lunchBreakEndTime)
                let dinnerStart = combine(date: searchDate, time: dinnerStartTime)
                let dinnerEnd = combine(date: searchDate, time: dinnerEndTime)
                let workEnd = combine(date: searchDate, time: workEndTime)
                
                // 添加所有在 currentDate 之后的时间点
                if workStart > currentDate { potentialEvents.append((workStart, .working)) }
                if lunchStart > currentDate { potentialEvents.append((lunchStart, .lunchBreak)) }
                if lunchEnd > currentDate { potentialEvents.append((lunchEnd, .working)) } // 假设午休后恢复工作
                if dinnerStart > currentDate { potentialEvents.append((dinnerStart, .dinnerBreak)) }
                if dinnerEnd > currentDate { potentialEvents.append((dinnerEnd, .working)) } // 假设晚餐后恢复工作
                if workEnd > currentDate { potentialEvents.append((workEnd, .offWork)) }
            } else {
                // 如果当天是休息日/周末/节假日，下一个事件可能是下一个工作日的开始
                // 需要找到下一个工作日
                var nextWorkday = calendar.date(byAdding: .day, value: 1, to: searchDate)!
                while self.isWorkDay(date: nextWorkday) != .workDay {
                    nextWorkday = calendar.date(byAdding: .day, value: 1, to: nextWorkday)!
                    // 可以加一个循环次数限制防止意外死循环
                }
                let nextWorkStart = combine(date: nextWorkday, time: workStartTime)
                // 只有当这个下一个工作日开始时间晚于当前时间时才添加
                if nextWorkStart > currentDate {
                    potentialEvents.append((nextWorkStart, .working))
                }
                // 找到第一个非工作日后的工作日即可跳出外层循环，因为我们只关心最近的事件
                potentialEvents.sort { $0.date < $1.date } // 排序找到最近的
                return potentialEvents.first // 直接返回找到的第一个事件
            }
            
            // 如果在当前搜索日期找到了未来的事件，就排序并返回最近的一个
            if !potentialEvents.isEmpty {
                potentialEvents.sort { $0.date < $1.date }
                return potentialEvents.first
            }
            
            // 如果今天没有找到未来的事件，继续搜索下一天
            searchDate = calendar.date(byAdding: .day, value: 1, to: searchDate)!
        }
        
        // 如果循环7天后仍未找到事件，则返回 nil
        return nil
    }
    
    // --- 添加 getNextEvent 方法的实现 ---
    func getNextEvent(after currentDate: Date) -> (date: Date, status: WorkStatus)? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: currentDate)
        
        // 辅助函数：合并日期和时间部分
        func combine(date: Date, time: Date) -> Date {
            let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
            return calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                 minute: timeComponents.minute ?? 0,
                                 second: timeComponents.second ?? 0,
                                 of: date) ?? date
        }
        
        var potentialEvents: [(date: Date, status: WorkStatus)] = []
        var searchDate = today // 从今天开始搜索
        
        // 循环查找未来最多（例如）7天内的事件，避免无限循环
        for _ in 0..<7 {
            let workDayType = self.isWorkDay(date: searchDate)
            
            if workDayType == .workDay {
                // 获取当天的所有时间点
                let workStart = combine(date: searchDate, time: workStartTime)
                let lunchStart = combine(date: searchDate, time: lunchBreakStartTime)
                let lunchEnd = combine(date: searchDate, time: lunchBreakEndTime)
                let dinnerStart = combine(date: searchDate, time: dinnerStartTime)
                let dinnerEnd = combine(date: searchDate, time: dinnerEndTime)
                let workEnd = combine(date: searchDate, time: workEndTime)
                
                // 添加所有在 currentDate 之后的时间点
                if workStart > currentDate { potentialEvents.append((workStart, .working)) }
                if lunchStart > currentDate { potentialEvents.append((lunchStart, .lunchBreak)) }
                if lunchEnd > currentDate { potentialEvents.append((lunchEnd, .working)) } // 假设午休后恢复工作
                if dinnerStart > currentDate { potentialEvents.append((dinnerStart, .dinnerBreak)) }
                if dinnerEnd > currentDate { potentialEvents.append((dinnerEnd, .working)) } // 假设晚餐后恢复工作
                if workEnd > currentDate { potentialEvents.append((workEnd, .offWork)) }
            } else {
                // 如果当天是休息日/周末/节假日，下一个事件可能是下一个工作日的开始
                // 需要找到下一个工作日
                var nextWorkday = calendar.date(byAdding: .day, value: 1, to: searchDate)!
                while self.isWorkDay(date: nextWorkday) != .workDay {
                    nextWorkday = calendar.date(byAdding: .day, value: 1, to: nextWorkday)!
                    // 可以加一个循环次数限制防止意外死循环
                }
                let nextWorkStart = combine(date: nextWorkday, time: workStartTime)
                // 只有当这个下一个工作日开始时间晚于当前时间时才添加
                if nextWorkStart > currentDate {
                    potentialEvents.append((nextWorkStart, .working))
                }
                // 找到第一个非工作日后的工作日即可跳出外层循环，因为我们只关心最近的事件
                potentialEvents.sort { $0.date < $1.date } // 排序找到最近的
                return potentialEvents.first // 直接返回找到的第一个事件
            }
            
            // 如果在当前搜索日期找到了未来的事件，就排序并返回最近的一个
            if !potentialEvents.isEmpty {
                potentialEvents.sort { $0.date < $1.date }
                return potentialEvents.first
            }
            
            // 如果今天没有找到未来的事件，继续搜索下一天
            searchDate = calendar.date(byAdding: .day, value: 1, to: searchDate)!
        }
        
        // 如果循环7天后仍未找到事件，则返回 nil
        return nil
    }
}

// MARK: - Alternating Work Schedule (Big/Small Week) (交替排班：大小周)
// In struct AlternatingWorkSchedule:
struct AlternatingWorkSchedule: WorkSchedule {
    var workStartTime: Date
    var workEndTime: Date
    var lunchBreakStartTime: Date
    var lunchBreakEndTime: Date
    var dinnerStartTime: Date // Add this line
    var dinnerEndTime: Date   // Add this line
    var currentWeekType: WeekType // 当前周是大周还是小周
    
    // 判断指定日期是否为工作日
    func isWorkDay(
        date: Date
    ) -> WorkDayType {
        let calendar = Calendar.current
        
        // 检查是否为公共节假日
        if HolidayManager.shared
            .isHoliday(
                date: date
            ) {
            return .holiday
        }
        
        // 获取今天的日期（忽略时间）
        let today = calendar.startOfDay(
            for: Date()
        )
        // 获取目标日期（忽略时间）
        let targetDay = calendar.startOfDay(
            for: date
        )
        
        // 计算目标日期与今天相差的周数
        // 注意：这里计算周差的方式可能需要根据具体业务逻辑调整，
        // 例如，如果需要严格按照ISO 8601周数或者特定周的起始日计算，需要修改。
        // 简单实现：计算天数差，然后除以7。更精确的方式是使用 weekOfYear。
        // let daysDifference = calendar.dateComponents([.day], from: today, to: targetDay).day ?? 0
        // let weekDifference = daysDifference / 7 // 这种方式可能不准确，跨年或周起始日不同时有问题
        
        // 使用 weekOfYear 计算周差可能更可靠，但也要注意 calendar 的 firstWeekday 设置
        // 这里假设 Calendar.current 的设置符合预期
        let todayWeekOfYear = calendar.component(
            .weekOfYear,
            from: today
        )
        let targetWeekOfYear = calendar.component(
            .weekOfYear,
            from: targetDay
        )
        // 简单的周差计算，可能需要处理跨年的情况
        // 更健壮的方式是计算两个日期之间的完整周数
        let weekDifference = calendar.dateComponents(
            [.weekOfYear],
            from: today,
            to: targetDay
        ).weekOfYear ?? 0
        
        
        // 判断目标日期所在周是大周还是小周
        // 假设大小周严格交替
        // 如果当前周是大周，且周差为偶数，则目标周也是大周
        // 如果当前周是小周，且周差为奇数，则目标周是大周
        let isTargetWeekBig: Bool
        if currentWeekType == .bigWeek {
            isTargetWeekBig = (
                weekDifference % 2 == 0
            )
        } else {
            isTargetWeekBig = (
                weekDifference % 2 != 0
            )
        }
        
        let weekday = calendar.component(
            .weekday,
            from: date
        ) // 获取星期几
        
        // 1 = 周日, 2 = 周一, ..., 7 = 周六
        if weekday == 1 { // 周日
            return .restDay // 周日固定休息
        } else if weekday == 7 { // 周六
            // 大周的周六工作，小周的周六休息
            return isTargetWeekBig ? .workDay : .restDay
        } else { // 周一至周五
            return .workDay // 周一至周五固定工作
        }
    }
    
    // 获取指定日期的当前状态
    func getCurrentStatus(
        date: Date
    ) -> WorkStatus {
        let dayType = isWorkDay(
            date: date
        ) // 获取日期类型
        
        switch dayType {
        case .holiday:
            return .holiday // 节假日
        case .restDay:
            // 交替排班的休息日可能是周末，也可能是小周的周六
            // 为了简化，统一返回 .weekend
            // 如果需要区分是周日还是小周周六，可以在这里添加逻辑
            return .weekend
        case .workDay:
            // 如果是工作日，则检查具体时间状态
            return checkWorkTimeStatus(
                date: date
            )
        }
    }
    
    // 检查工作日内具体时间的状态 (与 FixedWorkSchedule 相同)
    private func checkWorkTimeStatus(
        date: Date
    ) -> WorkStatus {
        let calendar = Calendar.current
        let now = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: date
        )
        let workStart = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: workStartTime
        )
        let workEnd = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: workEndTime
        )
        let lunchStart = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: lunchBreakStartTime
        )
        let lunchEnd = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: lunchBreakEndTime
        )
        // Use the struct's own dinner time properties
        let dinnerStart = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: dinnerStartTime
        ) // Add this line
        let dinnerEnd = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: dinnerEndTime
        )     // Add this line
        
        let nowMinutes = (
            now.hour ?? 0
        ) * 60 + (
            now.minute ?? 0
        )
        let workStartMinutes = (
            workStart.hour ?? 0
        ) * 60 + (
            workStart.minute ?? 0
        )
        let workEndMinutes = (
            workEnd.hour ?? 0
        ) * 60 + (
            workEnd.minute ?? 0
        )
        let lunchStartMinutes = (
            lunchStart.hour ?? 0
        ) * 60 + (
            lunchStart.minute ?? 0
        )
        let lunchEndMinutes = (
            lunchEnd.hour ?? 0
        ) * 60 + (
            lunchEnd.minute ?? 0
        )
        let dinnerStartMinutes = (
            dinnerStart.hour ?? 0
        ) * 60 + (
            dinnerStart.minute ?? 0
        ) // Add this line
        let dinnerEndMinutes = (
            dinnerEnd.hour ?? 0
        ) * 60 + (
            dinnerEnd.minute ?? 0
        )     // Add this line
        
        // Update the status check logic to include dinner break
        if nowMinutes < workStartMinutes || nowMinutes >= workEndMinutes {
            // Check for dinner break even when off work
            if nowMinutes >= dinnerStartMinutes && nowMinutes < dinnerEndMinutes {
                return .dinnerBreak
            }
            return .offWork
        } else if nowMinutes >= lunchStartMinutes && nowMinutes < lunchEndMinutes {
            return .lunchBreak
        } else if nowMinutes >= dinnerStartMinutes && nowMinutes < dinnerEndMinutes {
            // Check for dinner break during work hours
            return .dinnerBreak
        } else {
            return .working
        }
    }
    
    func getNextEvent(
        after currentDate: Date
    ) -> (
        date: Date,
        status: WorkStatus
    )? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(
            for: currentDate
        )
        
        // 辅助函数：合并日期和时间部分 (与 FixedWorkSchedule 相同)
        func combine(
            date: Date,
            time: Date
        ) -> Date {
            let timeComponents = calendar.dateComponents(
                [
                    .hour,
                    .minute,
                    .second
                ],
                from: time
            )
            return calendar
                .date(
                    bySettingHour: timeComponents.hour ?? 0,
                    minute: timeComponents.minute ?? 0,
                    second: timeComponents.second ?? 0,
                    of: date
                ) ?? date
        }
        
        var potentialEvents: [(
            date: Date,
            status: WorkStatus
        )] = []
        var searchDate = today // 从今天开始搜索
        
        // 循环查找未来最多（例如）7天内的事件
        for _ in 0..<7 {
            // 使用 AlternatingWorkSchedule 的 isWorkDay 方法
            let workDayType = self.isWorkDay(
                date: searchDate
            )
            
            if workDayType == .workDay {
                // 获取当天的所有时间点 (与 FixedWorkSchedule 相同)
                let workStart = combine(
                    date: searchDate,
                    time: workStartTime
                )
                let lunchStart = combine(
                    date: searchDate,
                    time: lunchBreakStartTime
                )
                let lunchEnd = combine(
                    date: searchDate,
                    time: lunchBreakEndTime
                )
                let dinnerStart = combine(
                    date: searchDate,
                    time: dinnerStartTime
                )
                let dinnerEnd = combine(
                    date: searchDate,
                    time: dinnerEndTime
                )
                let workEnd = combine(
                    date: searchDate,
                    time: workEndTime
                )
                
                // 添加所有在 currentDate 之后的时间点 (与 FixedWorkSchedule 相同)
                if workStart > currentDate {
                    potentialEvents.append(
                        (
                            workStart,
                            .working
                        )
                    )
                }
                if lunchStart > currentDate {
                    potentialEvents.append(
                        (
                            lunchStart,
                            .lunchBreak
                        )
                    )
                }
                if lunchEnd > currentDate {
                    potentialEvents.append(
                        (
                            lunchEnd,
                            .working
                        )
                    )
                }
                if dinnerStart > currentDate {
                    potentialEvents.append(
                        (
                            dinnerStart,
                            .dinnerBreak
                        )
                    )
                }
                if dinnerEnd > currentDate {
                    potentialEvents.append(
                        (
                            dinnerEnd,
                            .working
                        )
                    )
                }
                if workEnd > currentDate {
                    potentialEvents.append(
                        (
                            workEnd,
                            .offWork
                        )
                    )
                }
            } else {
                // 如果当天是休息日/周末/节假日，查找下一个工作日 (使用 self.isWorkDay)
                var nextWorkday = calendar.date(
                    byAdding: .day,
                    value: 1,
                    to: searchDate
                )!
                var loopCount = 0 // 防止无限循环
                while self.isWorkDay(
                    date: nextWorkday
                ) != .workDay && loopCount < 365 { // 增加循环限制
                    nextWorkday = calendar
                        .date(
                            byAdding: .day,
                            value: 1,
                            to: nextWorkday
                        )!
                    loopCount += 1
                }
                
                // 如果在合理范围内找到下一个工作日
                if loopCount < 365 {
                    let nextWorkStart = combine(
                        date: nextWorkday,
                        time: workStartTime
                    )
                    if nextWorkStart > currentDate {
                        potentialEvents
                            .append(
                                (
                                    nextWorkStart,
                                    .working
                                )
                            )
                    }
                }
                // 找到第一个非工作日后的工作日即可排序并返回最近事件
                potentialEvents
                    .sort {
                        $0.date < $1.date
                    }
                return potentialEvents.first
            }
            
            // 如果在当前搜索日期找到了未来的事件，就排序并返回最近的一个
            if !potentialEvents.isEmpty {
                potentialEvents
                    .sort {
                        $0.date < $1.date
                    }
                return potentialEvents.first
            }
            
            // 继续搜索下一天
            searchDate = calendar
                .date(
                    byAdding: .day,
                    value: 1,
                    to: searchDate
                )!
        }
        
        // 如果循环结束后仍未找到事件，则返回 nil
        return nil
    }
}

// MARK: - Shift Work Schedule (轮班制)
struct ShiftWorkSchedule: WorkSchedule {
    var workStartTime: Date
    var workEndTime: Date
    var lunchBreakStartTime: Date
    var lunchBreakEndTime: Date
    var dinnerStartTime: Date // Add this line
    var dinnerEndTime: Date   // Add this line
    var startDate: Date // 轮班周期的开始日期
    var workDays: Int   // 连续工作天数
    var restDays: Int   // 连续休息天数
    
    // 判断指定日期是否为工作日
    func isWorkDay(
        date: Date
    ) -> WorkDayType {
        let calendar = Calendar.current
        
        // 检查是否为公共节假日
        if HolidayManager.shared
            .isHoliday(
                date: date
            ) {
            return .holiday
        }
        
        // 计算目标日期距离轮班开始日期的天数
        // 确保比较的是日期部分，忽略时间
        let cycleStartDate = calendar.startOfDay(
            for: startDate
        )
        let targetDate = calendar.startOfDay(
            for: date
        )
        let daysSinceStart = calendar.dateComponents(
            [.day],
            from: cycleStartDate,
            to: targetDate
        ).day ?? 0
        
        // 如果目标日期在开始日期之前，则行为未定义，这里可以根据需求处理，例如返回休息日
        if daysSinceStart < 0 {
            // 或者抛出错误，或者根据业务逻辑决定
            return .restDay // 暂定为休息日
        }
        
        // 计算轮班周期的总长度
        let cycleLength = workDays + restDays
        // 如果周期长度小于等于0，则无效，返回休息日
        guard cycleLength > 0 else {
            return .restDay
        }
        
        // 计算目标日期在当前周期内的第几天 (从0开始计数)
        let dayInCycle = daysSinceStart % cycleLength
        
        // 如果天数在工作日范围内，则为工作日，否则为休息日
        return dayInCycle < workDays ? .workDay : .restDay
    }
    
    // 获取指定日期的当前状态
    func getCurrentStatus(
        date: Date
    ) -> WorkStatus {
        let dayType = isWorkDay(
            date: date
        ) // 获取日期类型
        
        switch dayType {
        case .holiday:
            return .holiday // 节假日
        case .restDay:
            // 轮班制的休息日，统一返回 .weekend
            // 如果需要区分是轮休还是法定周末（虽然轮班制不一定遵循周末），可以调整
            return .weekend
        case .workDay:
            // 如果是工作日，则检查具体时间状态
            return checkWorkTimeStatus(
                date: date
            )
        }
    }
    
    // 检查工作日内具体时间的状态 (与 FixedWorkSchedule 相同)
    private func checkWorkTimeStatus(
        date: Date
    ) -> WorkStatus {
        let calendar = Calendar.current
        let now = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: date
        )
        let workStart = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: workStartTime
        )
        let workEnd = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: workEndTime
        )
        let lunchStart = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: lunchBreakStartTime
        )
        let lunchEnd = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: lunchBreakEndTime
        )
        // 获取晚餐时间
        let dinnerStart = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: WorkScheduleManager.shared.dinnerStartTime
        )
        let dinnerEnd = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: WorkScheduleManager.shared.dinnerEndTime
        )
        
        let nowMinutes = (
            now.hour ?? 0
        ) * 60 + (
            now.minute ?? 0
        )
        let workStartMinutes = (
            workStart.hour ?? 0
        ) * 60 + (
            workStart.minute ?? 0
        )
        let workEndMinutes = (
            workEnd.hour ?? 0
        ) * 60 + (
            workEnd.minute ?? 0
        )
        let lunchStartMinutes = (
            lunchStart.hour ?? 0
        ) * 60 + (
            lunchStart.minute ?? 0
        )
        let lunchEndMinutes = (
            lunchEnd.hour ?? 0
        ) * 60 + (
            lunchEnd.minute ?? 0
        )
        let dinnerStartMinutes = (
            dinnerStart.hour ?? 0
        ) * 60 + (
            dinnerStart.minute ?? 0
        )
        let dinnerEndMinutes = (
            dinnerEnd.hour ?? 0
        ) * 60 + (
            dinnerEnd.minute ?? 0
        )
        
        // 判断当前时间所处的状态 (与 FixedWorkSchedule 保持一致)
        if nowMinutes < workStartMinutes || nowMinutes >= workEndMinutes {
            // 在下班后，但在晚餐时间之前或之后
            if nowMinutes >= dinnerStartMinutes && nowMinutes < dinnerEndMinutes {
                return .dinnerBreak // 晚餐时间内 -> 晚餐中
            }
            return .offWork // 上班前或下班后 -> 下班
        } else if nowMinutes >= lunchStartMinutes && nowMinutes < lunchEndMinutes {
            return .lunchBreak // 午休时间内 -> 午休中
        } else if nowMinutes >= dinnerStartMinutes && nowMinutes < dinnerEndMinutes {
            // 工作时间内的晚餐判断
            return .dinnerBreak
        } else {
            return .working // 其他工作时间内 -> 工作中
        }
    }
    
    // --- 添加 getNextEvent 方法的实现 ---
    func getNextEvent(
        after currentDate: Date
    ) -> (
        date: Date,
        status: WorkStatus
    )? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(
            for: currentDate
        )
        
        // 辅助函数：合并日期和时间部分 (与 FixedWorkSchedule 相同)
        func combine(
            date: Date,
            time: Date
        ) -> Date {
            let timeComponents = calendar.dateComponents(
                [
                    .hour,
                    .minute,
                    .second
                ],
                from: time
            )
            return calendar
                .date(
                    bySettingHour: timeComponents.hour ?? 0,
                    minute: timeComponents.minute ?? 0,
                    second: timeComponents.second ?? 0,
                    of: date
                ) ?? date
        }
        
        var potentialEvents: [(
            date: Date,
            status: WorkStatus
        )] = []
        var searchDate = today // 从今天开始搜索
        
        // 循环查找未来最多（例如）一个完整轮班周期 + 7 天内的事件
        let cycleLength = workDays + restDays
        for _ in 0..<(
            cycleLength + 7
        ) {
            // 使用 ShiftWorkSchedule 的 isWorkDay 方法
            let workDayType = self.isWorkDay(
                date: searchDate
            )
            
            if workDayType == .workDay {
                // 获取当天的所有时间点 (与 FixedWorkSchedule 相同)
                let workStart = combine(
                    date: searchDate,
                    time: workStartTime
                )
                let lunchStart = combine(
                    date: searchDate,
                    time: lunchBreakStartTime
                )
                let lunchEnd = combine(
                    date: searchDate,
                    time: lunchBreakEndTime
                )
                let dinnerStart = combine(
                    date: searchDate,
                    time: dinnerStartTime
                )
                let dinnerEnd = combine(
                    date: searchDate,
                    time: dinnerEndTime
                )
                let workEnd = combine(
                    date: searchDate,
                    time: workEndTime
                )
                
                // 添加所有在 currentDate 之后的时间点 (与 FixedWorkSchedule 相同)
                if workStart > currentDate {
                    potentialEvents.append(
                        (
                            workStart,
                            .working
                        )
                    )
                }
                if lunchStart > currentDate {
                    potentialEvents.append(
                        (
                            lunchStart,
                            .lunchBreak
                        )
                    )
                }
                if lunchEnd > currentDate {
                    potentialEvents.append(
                        (
                            lunchEnd,
                            .working
                        )
                    )
                }
                if dinnerStart > currentDate {
                    potentialEvents.append(
                        (
                            dinnerStart,
                            .dinnerBreak
                        )
                    )
                }
                if dinnerEnd > currentDate {
                    potentialEvents.append(
                        (
                            dinnerEnd,
                            .working
                        )
                    )
                }
                if workEnd > currentDate {
                    potentialEvents.append(
                        (
                            workEnd,
                            .offWork
                        )
                    )
                }
            } else {
                // 如果当天是休息日/节假日，查找下一个工作日 (使用 self.isWorkDay)
                var nextWorkday = calendar.date(
                    byAdding: .day,
                    value: 1,
                    to: searchDate
                )!
                var loopCount = 0 // 防止无限循环
                while self.isWorkDay(
                    date: nextWorkday
                ) != .workDay && loopCount < 365 { // 增加循环限制
                    nextWorkday = calendar
                        .date(
                            byAdding: .day,
                            value: 1,
                            to: nextWorkday
                        )!
                    loopCount += 1
                }
                
                // 如果在合理范围内找到下一个工作日
                if loopCount < 365 {
                    let nextWorkStart = combine(
                        date: nextWorkday,
                        time: workStartTime
                    )
                    if nextWorkStart > currentDate {
                        potentialEvents
                            .append(
                                (
                                    nextWorkStart,
                                    .working
                                )
                            )
                    }
                }
                // 找到第一个非工作日后的工作日即可排序并返回最近事件
                potentialEvents
                    .sort {
                        $0.date < $1.date
                    }
                return potentialEvents.first
            }
            
            // 如果在当前搜索日期找到了未来的事件，就排序并返回最近的一个
            if !potentialEvents.isEmpty {
                potentialEvents
                    .sort {
                        $0.date < $1.date
                    }
                return potentialEvents.first
            }
            
            // 继续搜索下一天
            searchDate = calendar
                .date(
                    byAdding: .day,
                    value: 1,
                    to: searchDate
                )!
        }
        
        // 如果循环结束后仍未找到事件，则返回 nil
        return nil
    }
}

// MARK: - Custom Work Schedule (自定义排班)
struct CustomWorkSchedule: WorkSchedule {
    var workStartTime: Date
    var workEndTime: Date
    var lunchBreakStartTime: Date
    var lunchBreakEndTime: Date
    var dinnerStartTime: Date // Add this line
    var dinnerEndTime: Date   // Add this line
    var customRestDays: [Date] // 特定的休息日列表 (日期，忽略时间)
    
    // 判断指定日期是否为工作日
    func isWorkDay(
        date: Date
    ) -> WorkDayType {
        let calendar = Calendar.current
        
        // 检查是否为公共节假日
        if HolidayManager.shared
            .isHoliday(
                date: date
            ) {
            return .holiday
        }
        
        // 检查是否为周末 (周六或周日)
        let weekday = calendar.component(
            .weekday,
            from: date
        )
        let isWeekend = weekday == 1 || weekday == 7 // 1 = 周日, 7 = 周六
        
        // 如果是周末，则固定为休息日
        if isWeekend {
            return .restDay
        }
        
        // 检查日期是否在自定义休息日列表中 (忽略时间比较)
        let isCustomRestDay = customRestDays.contains { restDay in
            calendar
                .isDate(
                    date,
                    inSameDayAs: restDay
                )
        }
        
        // 如果是自定义休息日，则为休息日，否则为工作日
        return isCustomRestDay ? .restDay : .workDay
    }
    
    // 获取指定日期的当前状态
    func getCurrentStatus(
        date: Date
    ) -> WorkStatus {
        let dayType = isWorkDay(
            date: date
        ) // 获取日期类型
        
        switch dayType {
        case .holiday:
            return .holiday // 节假日
        case .restDay:
            // 判断这个休息日是周末还是自定义休息日
            let calendar = Calendar.current
            let weekday = calendar.component(
                .weekday,
                from: date
            )
            let isWeekend = weekday == 1 || weekday == 7
            
            if isWeekend {
                return .weekend // 如果是周末，返回 Weekend
            } else {
                // 检查是否确实是自定义休息日（理论上 dayType 已经是 .restDay 且非周末，那必然是）
                // let isCustomRestDay = customRestDays.contains { restDay in
                //     calendar.isDate(date, inSameDayAs: restDay)
                // }
                // 对于非周末的自定义休息日，返回 RestDay 状态
                // return isCustomRestDay ? .restDay : .offWork // 这里逻辑有点绕，既然 dayType 是 restDay 且非周末，就应该是 .restDay
                return .restDay // 直接返回自定义休息日状态
            }
        case .workDay:
            // 如果是工作日，则检查具体时间状态
            return checkWorkTimeStatus(
                date: date
            )
        }
    }
    
    // 检查工作日内具体时间的状态 (与 FixedWorkSchedule 相同)
    private func checkWorkTimeStatus(
        date: Date
    ) -> WorkStatus {
        let calendar = Calendar.current
        let now = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: date
        )
        let workStart = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: workStartTime
        )
        let workEnd = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: workEndTime
        )
        let lunchStart = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: lunchBreakStartTime
        )
        let lunchEnd = calendar.dateComponents(
            [
                .hour,
                .minute
            ],
            from: lunchBreakEndTime
        )
        
        let nowMinutes = (
            now.hour ?? 0
        ) * 60 + (
            now.minute ?? 0
        )
        let workStartMinutes = (
            workStart.hour ?? 0
        ) * 60 + (
            workStart.minute ?? 0
        )
        let workEndMinutes = (
            workEnd.hour ?? 0
        ) * 60 + (
            workEnd.minute ?? 0
        )
        let lunchStartMinutes = (
            lunchStart.hour ?? 0
        ) * 60 + (
            lunchStart.minute ?? 0
        )
        let lunchEndMinutes = (
            lunchEnd.hour ?? 0
        ) * 60 + (
            lunchEnd.minute ?? 0
        )
        
        if nowMinutes < workStartMinutes || nowMinutes >= workEndMinutes {
            return .offWork
        } else if nowMinutes >= lunchStartMinutes && nowMinutes < lunchEndMinutes {
            return .lunchBreak
        } else {
            return .working
        }
    }
    // --- 添加 getNextEvent 方法的实现 ---
    func getNextEvent(after currentDate: Date) -> (date: Date, status: WorkStatus)? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: currentDate)
        
        // 辅助函数：合并日期和时间部分 (与 FixedWorkSchedule 相同)
        func combine(date: Date, time: Date) -> Date {
            let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
            return calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                 minute: timeComponents.minute ?? 0,
                                 second: timeComponents.second ?? 0,
                                 of: date) ?? date
        }
        
        var potentialEvents: [(date: Date, status: WorkStatus)] = []
        var searchDate = today // 从今天开始搜索
        
        // 循环查找未来最多（例如）30天内的事件
        for _ in 0..<30 {
            // 使用 CustomWorkSchedule 的 isWorkDay 方法
            let workDayType = self.isWorkDay(date: searchDate)
            
            if workDayType == .workDay {
                // 获取当天的所有时间点 (与 FixedWorkSchedule 相同)
                let workStart = combine(date: searchDate, time: workStartTime)
                let lunchStart = combine(date: searchDate, time: lunchBreakStartTime)
                let lunchEnd = combine(date: searchDate, time: lunchBreakEndTime)
                let dinnerStart = combine(date: searchDate, time: dinnerStartTime)
                let dinnerEnd = combine(date: searchDate, time: dinnerEndTime)
                let workEnd = combine(date: searchDate, time: workEndTime)
                
                // 添加所有在 currentDate 之后的时间点 (与 FixedWorkSchedule 相同)
                if workStart > currentDate { potentialEvents.append((workStart, .working)) }
                if lunchStart > currentDate { potentialEvents.append((lunchStart, .lunchBreak)) }
                if lunchEnd > currentDate { potentialEvents.append((lunchEnd, .working)) }
                if dinnerStart > currentDate { potentialEvents.append((dinnerStart, .dinnerBreak)) }
                if dinnerEnd > currentDate { potentialEvents.append((dinnerEnd, .working)) }
                if workEnd > currentDate { potentialEvents.append((workEnd, .offWork)) }
            } else {
                // 如果当天是休息日/周末/节假日，查找下一个工作日 (使用 self.isWorkDay)
                var nextWorkday = calendar.date(byAdding: .day, value: 1, to: searchDate)!
                var loopCount = 0 // 防止无限循环
                while self.isWorkDay(date: nextWorkday) != .workDay && loopCount < 365 { // 增加循环限制
                    nextWorkday = calendar.date(byAdding: .day, value: 1, to: nextWorkday)!
                    loopCount += 1
                }
                
                // 如果在合理范围内找到下一个工作日
                if loopCount < 365 {
                    let nextWorkStart = combine(date: nextWorkday, time: workStartTime)
                    if nextWorkStart > currentDate {
                        potentialEvents.append((nextWorkStart, .working))
                    }
                }
                // 找到第一个非工作日后的工作日即可排序并返回最近事件
                potentialEvents.sort { $0.date < $1.date }
                return potentialEvents.first
            }
            
            // 如果在当前搜索日期找到了未来的事件，就排序并返回最近的一个
            if !potentialEvents.isEmpty {
                potentialEvents.sort { $0.date < $1.date }
                return potentialEvents.first
            }
            
            // 继续搜索下一天
            searchDate = calendar.date(byAdding: .day, value: 1, to: searchDate)!
        }
        
        // 如果循环结束后仍未找到事件，则返回 nil
        return nil
    }
}
