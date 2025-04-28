import SwiftUI

struct SettingsView: View {
    @ObservedObject var scheduleManager = WorkScheduleManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var scheduleType: WorkScheduleType = .fixed
    
    // Work hours
    @State private var workStartTime: Date = Date()
    @State private var workEndTime: Date = Date()
    @State private var lunchStartTime: Date = Date()
    @State private var lunchEndTime: Date = Date()
    @State private var dinnerStartTime: Date = Date() // 新增
    @State private var dinnerEndTime: Date = Date()   // 新增
    
    // Alternating schedule
    @State private var alternatingStartDate: Date = Date()
    @State private var weekType: WeekType = .bigWeek
    
    // Shift schedule
    @State private var shiftStartDate: Date = Date()
    @State private var workDays: Int = 5
    @State private var restDays: Int = 2
    
    // Custom schedule
    @State private var selectedDate: Date = Date()
    @State private var showingCustomDayPicker = false
    
    var body: some View {
        Form {
            // Schedule Type Picker
            Section(header: Text(NSLocalizedString("Schedule Type", comment: ""))) {
                Picker(NSLocalizedString("Type", comment: ""), selection: $scheduleType) {
                    ForEach(WorkScheduleType.allCases) { type in
                        Text(type.localizedName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: scheduleType) { _ in
                    updateSettings()
                }
            }
            
            // Work hours settings
            Section(header: Text(NSLocalizedString("Work Hours", comment: ""))) {
                DatePicker(NSLocalizedString("Start Time", comment: ""), selection: $workStartTime, displayedComponents: .hourAndMinute)
                DatePicker(NSLocalizedString("End Time", comment: ""), selection: $workEndTime, displayedComponents: .hourAndMinute)
            }
            
            // Lunch break settings
            Section(header: Text(NSLocalizedString("Lunch Break", comment: ""))) {
                DatePicker(NSLocalizedString("Start Time", comment: ""), selection: $lunchStartTime, displayedComponents: .hourAndMinute)
                DatePicker(NSLocalizedString("End Time", comment: ""), selection: $lunchEndTime, displayedComponents: .hourAndMinute)
            }
            
            // Dinner break settings // 新增 Section
            Section(header: Text(NSLocalizedString("Dinner Break", comment: ""))) {
                DatePicker(NSLocalizedString("Start Time", comment: ""), selection: $dinnerStartTime, displayedComponents: .hourAndMinute)
                DatePicker(NSLocalizedString("End Time", comment: ""), selection: $dinnerEndTime, displayedComponents: .hourAndMinute)
            }
            
            // Schedule-specific settings
            switch scheduleType {
            case .fixed:
                fixedScheduleSettings
            case .alternating:
                alternatingScheduleSettings
            case .shift:
                shiftScheduleSettings
            case .custom:
                customScheduleSettings
            }
            
            // Holiday management
            Section(header: Text(NSLocalizedString("Holidays", comment: ""))) {
                NavigationLink(destination: HolidayManagementView()) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.red)
                        Text(NSLocalizedString("Manage Holidays", comment: ""))
                    }
                }
            }
            
            // Apply button
            Section {
                Button(NSLocalizedString("Apply Settings", comment: "")) {
                    applySettings()
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
        .navigationTitle(NSLocalizedString("Schedule Settings", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    // Fixed schedule (just show an explanation)
    private var fixedScheduleSettings: some View {
        Section(header: Text(NSLocalizedString("Fixed Schedule", comment: ""))) {
            Text(NSLocalizedString("Monday to Friday are work days. Saturday and Sunday are rest days.", comment: ""))
                .foregroundColor(.secondary)
        }
    }
    
    // Alternating schedule settings
    private var alternatingScheduleSettings: some View {
        Section(header: Text(NSLocalizedString("Current Week Schedule", comment: ""))) {
            Picker(NSLocalizedString("This Week's Type", comment: ""), selection: $weekType) {
                ForEach(WeekType.allCases) { type in
                    Text(type.localizedName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("Schedule Pattern:", comment: ""))
                    .font(.headline)
                
                Text(NSLocalizedString("6-Day Week: Monday-Saturday work, Sunday rest", comment: ""))
                    .foregroundColor(.secondary)
                
                Text(NSLocalizedString("5-Day Week: Monday-Friday work, Saturday-Sunday rest", comment: ""))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
    
    // Shift schedule settings
    private var shiftScheduleSettings: some View {
        Section(header: Text(NSLocalizedString("Shift Schedule", comment: ""))) {
            DatePicker(NSLocalizedString("Starting Date", comment: ""), selection: $shiftStartDate, displayedComponents: .date)
            
            Stepper(value: $workDays, in: 1...14) {
                HStack {
                    Text(NSLocalizedString("Work Days", comment: ""))
                    Spacer()
                    Text("\(workDays)")
                        .foregroundColor(.secondary)
                }
            }
            
            Stepper(value: $restDays, in: 1...14) {
                HStack {
                    Text(NSLocalizedString("Rest Days", comment: ""))
                    Spacer()
                    Text("\(restDays)")
                        .foregroundColor(.secondary)
                }
            }
            
            Text(String(format: NSLocalizedString("Pattern: %@ days work, %@ days off, repeat", comment: ""), "\(workDays)", "\(restDays)"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // Custom schedule settings
    private var customScheduleSettings: some View {
        Section(header: Text(NSLocalizedString("Custom Schedule", comment: ""))) {
            Button(NSLocalizedString("Add Rest Day", comment: "")) {
                DispatchQueue.main.async {
                    showingCustomDayPicker = true
                }
            }
            
            if !scheduleManager.customRestDays.isEmpty {
                Text(NSLocalizedString("Selected Rest Days:", comment: ""))
                    .font(.subheadline)
                
                ForEach(scheduleManager.customRestDays, id: \.self) { date in
                    HStack {
                        Text(dateFormatter.string(from: date))
                        
                        Spacer()
                        
                        Button {
                            scheduleManager.removeCustomRestDay(date: date)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Button(NSLocalizedString("Clear All", comment: "")) {
                    scheduleManager.clearAllCustomRestDays()
                }
                .foregroundColor(.red)
            }
        }
        .sheet(isPresented: $showingCustomDayPicker) {
            MultiDatePickerView(onSave: { selectedDates in
                if !selectedDates.isEmpty {
                    DispatchQueue.main.async {
                        scheduleManager.addMultipleCustomRestDays(dates: selectedDates)
                        showingCustomDayPicker = false
                    }
                }
            })
        }
    }
    
    // Date formatter for display
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    // Load current settings from the manager
    private func loadCurrentSettings() {
        scheduleType = scheduleManager.currentScheduleType
        workStartTime = scheduleManager.workStartTime
        workEndTime = scheduleManager.workEndTime
        lunchStartTime = scheduleManager.lunchBreakStartTime
        lunchEndTime = scheduleManager.lunchBreakEndTime
        dinnerStartTime = scheduleManager.dinnerStartTime // 新增
        dinnerEndTime = scheduleManager.dinnerEndTime   // 新增
        alternatingStartDate = scheduleManager.alternatingStartDate
        weekType = scheduleManager.currentWeekType
        shiftStartDate = scheduleManager.shiftStartDate
        workDays = scheduleManager.shiftWorkDays
        restDays = scheduleManager.shiftRestDays
    }
    
    // Apply the settings to the manager
    private func applySettings() {
        // 调用更新后的方法
        scheduleManager.applyScheduleTimes(
            workStart: workStartTime,
            workEnd: workEndTime,
            lunchStart: lunchStartTime,
            lunchEnd: lunchEndTime,
            dinnerStart: dinnerStartTime, // 新增
            dinnerEnd: dinnerEndTime      // 新增
        )

        scheduleManager.alternatingStartDate = alternatingStartDate
        scheduleManager.currentWeekType = weekType
        scheduleManager.shiftStartDate = shiftStartDate
        scheduleManager.shiftWorkDays = workDays
        scheduleManager.shiftRestDays = restDays

        scheduleManager.changeScheduleType(type: scheduleType) // 这个会调用 updateActiveSchedule
    }
    
    // Update settings based on schedule type
    private func updateSettings() {
        // Nothing special needs to be done for now
    }
}

// Custom date picker for selecting work days
struct CustomDatePickerView: View {
    @Binding var selectedDate: Date
    var onSave: (Date) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                
                Spacer()
                
                Button("Add as Work Day") {
                    onSave(selectedDate)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .navigationTitle("Add Work Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}