import Foundation
import Combine

// 管理工作排班的核心类，负责加载、保存、更新和计算当前的工作状态
class WorkScheduleManager: ObservableObject {
    // 单例实例
    static let shared = WorkScheduleManager()

    // MARK: - Published Properties (发布属性，用于 SwiftUI 视图绑定)

    // 当前选择的排班类型 (例如：固定、交替、轮班、自定义)
    @Published var currentScheduleType: WorkScheduleType = .fixed
    // 当前的工作状态 (例如：工作中、午休、下班、周末、节假日、休息日)
    @Published var currentStatus: WorkStatus = .offWork
    // 用于显示的当前状态文本
    @Published var statusText: String = "Initial Status" // 初始状态

    // --- 新增：下一个状态事件 ---
    @Published var nextEvent: (date: Date, status: WorkStatus)? = nil
    // --- 结束新增 ---
    
    // 新增：控制节假日是否自动休息
    @Published var holidayAutoRest: Bool = true

    // 工作时间 (所有排班类型通用)
    @Published var workStartTime: Date // 工作开始时间
    @Published var workEndTime: Date   // 工作结束时间
    @Published var lunchBreakStartTime: Date // 午休开始时间
    @Published var lunchBreakEndTime: Date   // 午休结束时间
    @Published var dinnerStartTime: Date // 新增：晚餐开始时间
    @Published var dinnerEndTime: Date   // 新增：晚餐结束时间

    // 特定排班类型的属性
    @Published var alternatingStartDate: Date = Date() // 交替排班的参考开始日期 (用于计算大小周)
    @Published var currentWeekType: WeekType = .bigWeek // 交替排班的当前周类型 (大周/小周)
    @Published var shiftStartDate: Date = Date() // 轮班制的开始日期
    @Published var shiftWorkDays: Int = 5 // 轮班制连续工作天数
    @Published var shiftRestDays: Int = 2 // 轮班制连续休息天数
    @Published var customRestDays: [Date] = [] // 自定义排班的特定休息日列表
    
    // 新增：固定排班的每周工作日设置 [周一,周二,周三,周四,周五,周六,周日]
    @Published var fixedScheduleWorkingDays: [Bool] = [true, true, true, true, true, false, false]
    
    // MARK: - Private Properties (私有属性)

    // 当前激活的排班计划实例
    var activeSchedule: WorkSchedule?

    // 用于定期更新状态的计时器
    var statusTimer: Timer?
    
    // 设置文件名
    let settingsFileName = "workScheduleSettings.json"
    
    // 私有初始化方法，确保单例模式
    private init() {
        // 设置默认工作时间 (上午9点 - 下午6点, 午休 12点 - 1点)
        let calendar = Calendar.current

        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        workStartTime = calendar.date(from: components) ?? Date()

        components.hour = 18
        components.minute = 0
        workEndTime = calendar.date(from: components) ?? Date()

        components.hour = 12
        components.minute = 0
        lunchBreakStartTime = calendar.date(from: components) ?? Date()

        components.hour = 13
        components.minute = 0
        lunchBreakEndTime = calendar.date(from: components) ?? Date()

        // 设置默认晚餐时间 (晚上 7点 - 8点)
        components.hour = 19
        components.minute = 0
        dinnerStartTime = calendar.date(from: components) ?? Date() // 新增

        components.hour = 20
        components.minute = 0
        dinnerEndTime = calendar.date(from: components) ?? Date()   // 新增

        // 加载保存的设置 (如果不存在则使用默认值)
        loadSettings()

        // 加载当前年份的节假日信息
        let currentYear = calendar.component(.year, from: Date())
        HolidayManager.shared.loadHolidays(for: currentYear)

        // 使用加载或默认的设置初始化激活的排班计划
        updateActiveSchedule()

        // 启动状态更新计时器
        startStatusTimer()
    }
    
    // MARK: - Public Methods
    
    // 更新排班类型
    func changeScheduleType(type: WorkScheduleType) {
        // 更新当前的排班类型
        currentScheduleType = type
        // 根据新的类型更新激活的排班计划
        updateActiveSchedule()
        // 保存更改后的设置
        saveSettings()
    }
    
    // 判断指定日期是否为工作日
    func isWorkDay(date: Date) -> WorkDayType {
        // 确保有激活的排班计划
        guard let schedule = activeSchedule else {
            // 没有排班计划，默认返回休息日
            return .restDay
        }
        // 调用激活排班计划的 isWorkDay 方法
        return schedule.isWorkDay(date: date)
    }
}





