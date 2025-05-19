import Foundation
import SwiftUI

// 任务象限
enum TaskQuadrant: String, CaseIterable, Identifiable, Codable {
    case importantUrgent = "重要且紧急"
    case importantNotUrgent = "重要不紧急"
    case notImportantUrgent = "紧急不重要"
    case notImportantNotUrgent = "不紧急不重要"
    
    var id: String { rawValue }
    
    var name: String { rawValue }
    
    var color: Color {
        switch self {
        case .importantUrgent: return .red
        case .importantNotUrgent: return .blue
        case .notImportantUrgent: return .orange
        case .notImportantNotUrgent: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .importantUrgent: return "flame"
        case .importantNotUrgent: return "star"
        case .notImportantUrgent: return "bolt"
        case .notImportantNotUrgent: return "leaf"
        }
    }
}

// 基础任务模型
struct TodoTask: Identifiable, Codable {
    var id: UUID
    var title: String
    var quadrant: TaskQuadrant
    var isCompleted: Bool
    var completionNotes: String?
    var incompleteReason: String?
    
    init(id: UUID = UUID(), title: String, quadrant: TaskQuadrant, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.quadrant = quadrant
        self.isCompleted = isCompleted
    }
}

// 计划任务模型
struct ScheduledTask: Identifiable, Codable {
    var id: UUID
    var title: String
    var startTime: Date
    var endTime: Date
    var notes: String
    var isParallel: Bool
    var isCompleted: Bool
    
    var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startTime))-\(formatter.string(from: endTime))"
    }
    
    var durationText: String {
        let duration = endTime.timeIntervalSince(startTime)
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    var duration: TimeInterval { endTime.timeIntervalSince(startTime) }
    
    init(id: UUID = UUID(), title: String, startTime: Date, endTime: Date, notes: String = "", isParallel: Bool = false) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
        self.isParallel = isParallel
        self.isCompleted = false
    }
}

// 完成任务模型
struct CompletedTask: Identifiable, Codable {
    var id: UUID
    var title: String
    var startTime: Date
    var endTime: Date
    var notes: String
    var scheduledTaskId: UUID?
    
    var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startTime))-\(formatter.string(from: endTime))"
    }
    
    var durationText: String {
        let duration = endTime.timeIntervalSince(startTime)
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    var duration: TimeInterval { endTime.timeIntervalSince(startTime) }
    
    init(id: UUID = UUID(), title: String, startTime: Date, endTime: Date, notes: String = "", scheduledTaskId: UUID? = nil) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
        self.scheduledTaskId = scheduledTaskId
    }
}

// 复盘模型
struct Reflection: Codable {
    var summary: String = ""
    var learnings: String = ""
    var improvements: String = ""
    var description: String = ""
    var analysis: String = ""
    var improvement: String = ""
}

// 每日日志模型
struct DailyLog: Identifiable, Codable {
    var id: UUID
    var date: Date
    var tasks: [TodoTask]
    var scheduledTasks: [ScheduledTask]
    var completedTasks: [CompletedTask]
    var notes: String
    var reflection: Reflection?
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    init(id: UUID = UUID(), date: Date = Date(), tasks: [TodoTask] = [], scheduledTasks: [ScheduledTask] = [], completedTasks: [CompletedTask] = [], notes: String = "", reflection: Reflection? = nil) {
        self.id = id
        self.date = date
        self.tasks = tasks
        self.scheduledTasks = scheduledTasks
        self.completedTasks = completedTasks
        self.notes = notes
        self.reflection = reflection
    }
} 