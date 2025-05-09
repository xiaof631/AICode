import Foundation

// MARK: - Work Schedule Type (排班类型)
enum WorkScheduleType: String, CaseIterable, Identifiable {
    case fixed = "Fixed"
    case alternating = "Alternating"
    case shift = "Shift"
    case custom = "Custom"
    
    var id: String {
        self.rawValue
    }
    
    // 提供本地化的类型名称
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

// MARK: - Week Type (周类型，用于交替排班)
enum WeekType: String, CaseIterable, Identifiable {
    case bigWeek = "Big Week"   // 大周
    case smallWeek = "Small Week" // 小周
    
    var id: String {
        self.rawValue
    }
    
    // 提供本地化的类型名称
    var localizedName: String {
        NSLocalizedString(
            self.rawValue,
            comment: "Week type"
        )
    }
}
