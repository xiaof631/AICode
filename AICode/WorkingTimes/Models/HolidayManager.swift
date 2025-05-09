import Foundation

// 管理节假日信息的类 (单例模式)
class HolidayManager {
    // 单例实例
    static let shared = HolidayManager()

    // 私有初始化方法，防止外部创建实例
    private init() {}

    // 节假日数据的管理方式可以有多种：
    // 1. 硬编码特定年份的节假日 (如示例)
    // 2. 从服务器获取
    // 3. 存储在本地数据库 (如 CoreData, Realm, SQLite)
    // 4. 根据规则计算 (例如：每年5月的第一个星期一)

    // 存储节假日的数组 (只存储日期部分，忽略时间)
    private var holidays: [Date] = []

    // 添加一个节假日
    func addHoliday(date: Date) {
        let calendar = Calendar.current
        // 获取日期部分，设置为当天的开始时间 (00:00:00)
        let dateOnly = calendar.startOfDay(for: date)

        // 检查该日期是否已存在于节假日列表中 (使用 isDate(_:inSameDayAs:) 进行比较)
        if !holidays.contains(where: { calendar.isDate($0, inSameDayAs: dateOnly) }) {
            holidays.append(dateOnly)
            // 可以考虑添加后排序，方便管理和查找
            // holidays.sort()
        }
    }

    // 移除一个节假日
    func removeHoliday(date: Date) {
        let calendar = Calendar.current
        // 移除所有与指定日期在同一天的节假日
        holidays.removeAll { holiday in
            calendar.isDate(holiday, inSameDayAs: date)
        }
    }

    // 检查指定日期是否为节假日
    func isHoliday(date: Date) -> Bool {
        let calendar = Calendar.current
        // 检查节假日列表中是否包含与指定日期在同一天的日期
        return holidays.contains { holiday in
            calendar.isDate(holiday, inSameDayAs: date)
        }
    }

    // 加载特定年份的节假日数据
    // 这个方法可以扩展为从 API 或数据库加载
    // 目前是硬编码的示例数据 (中国 2024 年节假日)
    func loadHolidays(for year: Int) {
        // 清除旧数据，避免重复加载或加载不同年份的数据
        // clearHolidays() // 根据需要决定是否每次加载前清空

        // 示例：加载 2024 年中国的法定节假日
        // 注意：这只是一个示例，实际应用中应使用更可靠的数据源
        // 并且需要考虑调休工作日的情况（本示例未处理调休）
        if year == 2025 {
            // 元旦
            addHolidayFromComponents(year: 2024, month: 1, day: 1)

            // 春节 (除夕到初七)
            addHolidayFromComponents(year: 2024, month: 2, day: 10) // 初一
            addHolidayFromComponents(year: 2024, month: 2, day: 11) // 初二
            addHolidayFromComponents(year: 2024, month: 2, day: 12) // 初三
            addHolidayFromComponents(year: 2024, month: 2, day: 13) // 初四
            addHolidayFromComponents(year: 2024, month: 2, day: 14) // 初五
            addHolidayFromComponents(year: 2024, month: 2, day: 15) // 初六
            addHolidayFromComponents(year: 2024, month: 2, day: 16) // 初七
            addHolidayFromComponents(year: 2024, month: 2, day: 17) // 初八 (官方假期到17日)

            // 清明节
            addHolidayFromComponents(year: 2024, month: 4, day: 4)
            addHolidayFromComponents(year: 2024, month: 4, day: 5)
            addHolidayFromComponents(year: 2024, month: 4, day: 6)

            // 劳动节
            addHolidayFromComponents(year: 2024, month: 5, day: 1)
            addHolidayFromComponents(year: 2024, month: 5, day: 2)
            addHolidayFromComponents(year: 2024, month: 5, day: 3)
            addHolidayFromComponents(year: 2024, month: 5, day: 4)
            addHolidayFromComponents(year: 2024, month: 5, day: 5)

            // 端午节
            addHolidayFromComponents(year: 2024, month: 6, day: 8) // 周六，实际放假从10号开始，但8、9是周末
            addHolidayFromComponents(year: 2024, month: 6, day: 9) // 周日
            addHolidayFromComponents(year: 2024, month: 6, day: 10) // 端午节当天

            // 中秋节
            addHolidayFromComponents(year: 2024, month: 9, day: 15) // 周日
            addHolidayFromComponents(year: 2024, month: 9, day: 16) // 周一
            addHolidayFromComponents(year: 2024, month: 9, day: 17) // 周二 (中秋节当天)

            // 国庆节
            addHolidayFromComponents(year: 2024, month: 10, day: 1)
            addHolidayFromComponents(year: 2024, month: 10, day: 2)
            addHolidayFromComponents(year: 2024, month: 10, day: 3)
            addHolidayFromComponents(year: 2024, month: 10, day: 4)
            addHolidayFromComponents(year: 2024, month: 10, day: 5)
            addHolidayFromComponents(year: 2024, month: 10, day: 6)
            addHolidayFromComponents(year: 2024, month: 10, day: 7)
        }
        // 可以添加其他年份的逻辑或从外部数据源加载
        // else if year == 2025 { ... }
    }

    // 辅助方法：根据年月日创建 Date 对象并添加到节假日列表
    private func addHolidayFromComponents(year: Int, month: Int, day: Int) {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        // 设置时区为当前时区，确保日期正确
        dateComponents.timeZone = TimeZone.current
        // 设置时间为 00:00:00
        dateComponents.hour = 0
        dateComponents.minute = 0
        dateComponents.second = 0


        // 使用 Calendar.current 从 DateComponents 创建 Date 对象
        if let date = Calendar.current.date(from: dateComponents) {
            // 调用 addHoliday 方法添加，该方法会处理日期部分和重复检查
            addHoliday(date: date)
        } else {
            // 如果日期创建失败，可以记录日志或进行错误处理
            print("Error creating date for holiday: \(year)-\(month)-\(day)")
        }
    }

    // 清除所有已加载的节假日
    func clearHolidays() {
        holidays.removeAll()
    }

    // 获取所有当前存储的节假日列表 (返回副本)
    func getAllHolidays() -> [Date] {
        // 返回数组的副本，防止外部直接修改内部 holidays 数组
        return holidays
    }
}
