import SwiftUI

struct StatusView: View {
    
    init() {
        // Load holidays for the current year
        let currentYear = Calendar.current.component(.year, from: Date())
        // TODO: 确保 HolidayManager.shared.loadHolidays 存在且被正确调用
        // HolidayManager.shared.loadHolidays(for: currentYear)
    }
    
    @ObservedObject var scheduleManager = WorkScheduleManager.shared
    @State private var currentDate = Date()
    
    // --- 建议：如果不需要秒级更新，可以改回 60 秒 ---
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect() // 每秒更新以显示倒计时
    
    var body: some View {
        VStack(spacing: 20) {
            // Current date and time
            VStack {
                Text(currentDate, style: .date)
                    .font(.headline)
                Text(currentDate, style: .time)
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Current status
            VStack {
                Text(NSLocalizedString("Current Status", comment: ""))
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(localizedStatusText) // 使用计算属性
                    .font(.system(size: 36))
                    .fontWeight(.bold)
                    .foregroundColor(statusColor) // 使用计算属性
                    .padding()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // --- 新增/确认：下一个状态信息 ---
            // 确保 WorkScheduleManager 中 nextEvent 属性存在且被更新
            if let nextEvent = scheduleManager.nextEvent {
                VStack {
                    Text(NSLocalizedString("Next Status", comment: ""))
                        .font(.headline)
                        .foregroundColor(.secondary)
                
                    HStack(alignment: .lastTextBaseline) { // 对齐文本基线
                        Text(localizedStatusText(for: nextEvent.status)) // 使用带参数的方法
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(statusColor(for: nextEvent.status)) // 使用带参数的方法
                        
                        Spacer()
                        
                        Text("in \(formatTimeInterval(from: currentDate, to: nextEvent.date))")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 4)
                    
                    // 显示下一个状态的具体时间
                    Text("at \(formatTime(nextEvent.date))")
                         .font(.caption)
                         .foregroundColor(.gray)
                         .frame(maxWidth: .infinity, alignment: .trailing) // 时间靠右对齐
                         .padding(.top, 1)

                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            // --- 结束新增/确认 ---
            
            // Schedule type
            VStack {
                Text(NSLocalizedString("Schedule Type", comment: ""))
                    .font(.headline)
                    .foregroundColor(.secondary)

                // --- Modification: Explicitly access wrappedValue ---
                // Text(scheduleManager.currentScheduleType.localizedName) // Original line
                Text(scheduleManager.currentScheduleType.localizedName) // Try accessing wrappedValue
                // --- End Modification ---
                    .font(.title)
                    .fontWeight(.medium)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Work times
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("Work Hours", comment: ""))
                    .font(.headline)
                    .foregroundColor(.secondary)

                HStack {
                    Label {
                        // --- Modification: Explicitly access wrappedValue (Example) ---
                        // If the error persists for other lines, apply the same pattern:
                        // Text(formatTime(scheduleManager.workStartTime)) // Original
                        Text(formatTime(scheduleManager.workStartTime)) // Try accessing wrappedValue
                        // --- End Modification ---
                    } icon: {
                        Image(systemName: "sunrise")
                    }

                    Spacer()

                    Label {
                        // --- Modification: Explicitly access wrappedValue (Example) ---
                        // Text(formatTime(scheduleManager.workEndTime)) // Original
                        Text(formatTime(scheduleManager.workEndTime)) // Try accessing wrappedValue
                        // --- End Modification ---
                    } icon: {
                        Image(systemName: "sunset")
                    }
                }

                Text(NSLocalizedString("Lunch Break", comment: ""))
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                HStack {
                    Label {
                        // --- Modification: Explicitly access wrappedValue (Example) ---
                        // Text(formatTime(scheduleManager.lunchBreakStartTime)) // Original
                        Text(formatTime(scheduleManager.lunchBreakStartTime)) // Try accessing wrappedValue
                        // --- End Modification ---
                    } icon: {
                        Image(systemName: "fork.knife")
                    }

                    Spacer()

                    Label {
                        // --- Modification: Explicitly access wrappedValue (Example) ---
                        // Text(formatTime(scheduleManager.lunchBreakEndTime)) // Original
                        Text(formatTime(scheduleManager.lunchBreakEndTime)) // Try accessing wrappedValue
                        // --- End Modification ---
                    } icon: {
                        Image(systemName: "stopwatch")
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Spacer()
            
            // Settings button
            NavigationLink {
                SettingsView()
            } label: {
                Label("Settings", systemImage: "gear")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .navigationTitle("Working Time")
        .onReceive(timer) { inputDate in // 使用 timer 传递的日期确保一致性
            currentDate = inputDate // 更新当前时间显示
            // --- 关键：取消注释以更新状态和下一个事件 ---
            scheduleManager.updateStatus() // 确保这里会更新 currentStatus 和 nextEvent
            // --- 结束关键 ---
        }
        .onAppear { // 视图出现时也更新一次状态
             scheduleManager.updateStatus()
        }
    }
    
    // Format the time from a Date object
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // --- 确认：格式化时间间隔函数存在 ---
    private func formatTimeInterval(from startDate: Date, to endDate: Date) -> String {
        let interval = endDate.timeIntervalSince(startDate)
        // 处理时间已过或非常接近的情况
        guard interval > 1 else { return NSLocalizedString("Now", comment: "Time interval is now") }

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute] // 只显示小时和分钟
        formatter.unitsStyle = .full // 例如 "1 小时, 23 分钟" 或 "4 分钟"
        formatter.maximumUnitCount = 1 // 只显示最大的单位，例如 "1 小时" 或 "23 分钟" (如果需要更简洁)
        // formatter.unitsStyle = .abbreviated // 例如 "1h 23m"
        formatter.zeroFormattingBehavior = .dropLeading // 不显示 0 小时

        // 四舍五入到最近的分钟
        let roundedInterval = (interval / 60).rounded() * 60

        return formatter.string(from: roundedInterval) ?? ""
    }
    // --- 结束确认 ---

    // --- 确认：重载 statusColor 以接受参数 ---
    private func statusColor(for status: WorkStatus) -> Color {
        switch status {
        case .working: return .green
        case .lunchBreak: return .orange
        case .offWork: return .blue
        case .weekend: return .purple
        case .holiday: return .red
        case .restDay: return .indigo
        case .dinnerBreak: return .yellow // 假设是黄色
        }
    }
    // --- 结束确认 ---

    // --- 确认：重载 localizedStatusText 以接受参数 ---
    private func localizedStatusText(for status: WorkStatus) -> String {
         switch status {
         case .working: return NSLocalizedString("Working", comment: "")
         case .lunchBreak: return NSLocalizedString("Lunch Break", comment: "")
         case .offWork: return NSLocalizedString("Off Work", comment: "")
         case .weekend: return NSLocalizedString("Weekend", comment: "")
         case .holiday: return NSLocalizedString("Holiday", comment: "")
         case .restDay: return NSLocalizedString("休息日", comment: "Rest Day status")
         case .dinnerBreak: return NSLocalizedString("晚餐中", comment: "") // 晚餐状态文本
         }
     }
    // --- 结束确认 ---

    // --- 确认：使现有计算属性使用新的重载方法 ---
    private var statusColor: Color {
        statusColor(for: scheduleManager.currentStatus)
    }

    private var localizedStatusText: String {
        localizedStatusText(for: scheduleManager.currentStatus)
    }
    // --- 结束确认 ---
}

#Preview {
    NavigationView {
        StatusView()
    }
}
