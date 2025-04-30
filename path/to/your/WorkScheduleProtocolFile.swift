import Foundation

protocol WorkSchedule {
    // ... 其他已有的属性和方法 ...

    func getCurrentStatus(date: Date) -> WorkStatus
    func isWorkDay(date: Date) -> WorkDayType

    // --- 在这里添加 getNextEvent 方法的定义 ---
    /// 计算给定日期之后的下一个状态变更事件。
    /// - Parameter currentDate: 需要查找其后事件的日期。
    /// - Returns: 包含下一个事件的日期和状态的元组，如果近期内没有定义的事件则返回 nil。
    func getNextEvent(after currentDate: Date) -> (date: Date, status: WorkStatus)?
    // --- 结束添加 ---
}