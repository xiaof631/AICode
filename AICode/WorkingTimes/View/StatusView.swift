import SwiftUI

struct StatusView: View {
    
    init() {
        // Load holidays for the current year
        let currentYear = Calendar.current.component(.year, from: Date())
        HolidayManager.shared.loadHolidays(for: currentYear)
    }
    
    @ObservedObject var scheduleManager = WorkScheduleManager.shared
    @State private var currentDate = Date()
    
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
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
                
                Text(localizedStatusText)
                    .font(.system(size: 36))
                    .fontWeight(.bold)
                    .foregroundColor(statusColor)
                    .padding()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Schedule type
            VStack {
                Text(NSLocalizedString("Schedule Type", comment: ""))
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(scheduleManager.currentScheduleType.localizedName)
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
                        Text(formatTime(scheduleManager.workStartTime))
                    } icon: {
                        Image(systemName: "sunrise")
                    }
                    
                    Spacer()
                    
                    Label {
                        Text(formatTime(scheduleManager.workEndTime))
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
                        Text(formatTime(scheduleManager.lunchBreakStartTime))
                    } icon: {
                        Image(systemName: "fork.knife")
                    }
                    
                    Spacer()
                    
                    Label {
                        Text(formatTime(scheduleManager.lunchBreakEndTime))
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
        .onReceive(timer) { _ in
            currentDate = Date()
            scheduleManager.updateStatus()
        }
    }
    
    // Format the time from a Date object
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Get color based on current status
    private var statusColor: Color {
        switch scheduleManager.currentStatus {
        case .working:
            return .green
        case .lunchBreak:
            return .orange
        case .offWork:
            return .blue
        case .weekend:
            return .purple
        case .holiday:
            return .red
        case .restDay:
            return .indigo
        case .dinnerBreak:
            return .yellow
        }
    }
    
    // Localized status text
    private var localizedStatusText: String {
        switch scheduleManager.currentStatus {
        case .working:
            return NSLocalizedString("Working", comment: "")
        case .lunchBreak:
            return NSLocalizedString("Lunch Break", comment: "")
        case .offWork:
            return NSLocalizedString("Off Work", comment: "")
        case .weekend:
            return NSLocalizedString("Weekend", comment: "")
        case .holiday:
            return NSLocalizedString("Holiday", comment: "")
        case .restDay:
            return NSLocalizedString("休息日", comment: "Rest Day status")
        case .dinnerBreak:
            return NSLocalizedString("晚餐中", comment: "")
        }
    }
}

#Preview {
    NavigationView {
        StatusView()
    }
} 
