import SwiftUI

struct MultiDatePickerView: View {
    var onSave: ([Date]) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDates: [Date] = []
    @State private var currentDate = Date()
    @State private var refreshToggle = false
    @State private var isSaving = false
    @State private var showSaveConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Month and year selector
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .padding()
                    }
                    
                    Text(monthYearFormatter.string(from: currentDate))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .padding()
                    }
                }
                .padding(.top)
                
                // Days of week header
                HStack {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .frame(maxWidth: .infinity)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Calendar grid - 使用下标而不是日期作为ID
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(0..<daysWithIndices.count, id: \.self) { index in
                        let element = daysWithIndices[index]
                        if let date = element.date {
                            DayButton(
                                date: date,
                                isSelected: isDateSelected(date),
                                onToggle: toggleDate
                            )
                            .id("day-\(index)-\(date.timeIntervalSince1970)-\(refreshToggle)")
                        } else {
                            // Empty space for days that don't exist in this month
                            Color.clear
                                .frame(height: 40)
                                .id("empty-\(index)")
                        }
                    }
                }
                .padding()
                .id("month-\(Calendar.current.component(.month, from: currentDate))-\(Calendar.current.component(.year, from: currentDate))")
                
                // Selected dates count
                if !selectedDates.isEmpty {
                    Text("\(selectedDates.count) \(NSLocalizedString("dates selected", comment: ""))")
                        .foregroundColor(.secondary)
                        .padding()
                }
                
                Spacer()
                
                // Save button
                Button(NSLocalizedString("Add as Rest Days", comment: "")) {
                    if !selectedDates.isEmpty && !isSaving {
                        isSaving = true
                        // 使用一个确认弹窗替代直接保存和关闭
                        showSaveConfirmation = true
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(selectedDates.isEmpty || isSaving)
            }
            .navigationTitle(NSLocalizedString("Select Rest Days", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Cancel", comment: "")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .destructiveAction) {
                    Button(NSLocalizedString("Clear", comment: "")) {
                        selectedDates.removeAll()
                        refreshToggle.toggle()
                    }
                    .disabled(selectedDates.isEmpty)
                }
            }
            .allowsHitTesting(!isSaving)
            .id("calendar-view-\(refreshToggle)")
            .alert(isPresented: $showSaveConfirmation) {
                Alert(
                    title: Text(NSLocalizedString("Add Rest Days", comment: "")),
                    message: Text(String(format: NSLocalizedString("Add %d rest days?", comment: ""), selectedDates.count)),
                    primaryButton: .default(Text(NSLocalizedString("Add", comment: ""))) {
                        let datesToSave = selectedDates
                        // 先取消弹窗，稍后进行保存操作
                        showSaveConfirmation = false
                        
                        // 使用timer延迟执行保存和关闭操作，避免与弹窗关闭冲突
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onSave(datesToSave)
                        }
                    },
                    secondaryButton: .cancel {
                        showSaveConfirmation = false
                        isSaving = false
                    }
                )
            }
        }
    }
    
    // Days of the week header
    private var daysOfWeek: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortWeekdaySymbols
    }
    
    // 日期和索引的组合结构体，确保每个单元格有唯一标识
    private struct DayWithIndex: Identifiable {
        let id: Int
        let date: Date?
    }
    
    // 带有索引的日期数组，确保每个位置都有唯一ID
    private var daysWithIndices: [DayWithIndex] {
        return days.enumerated().map { index, date in
            DayWithIndex(id: index, date: date)
        }
    }
    
    // Dates for the current month view
    private var days: [Date?] {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)!.count
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }
        
        // Pad the end to make the grid complete
        let remainingDays = (7 - (days.count % 7)) % 7
        days.append(contentsOf: Array(repeating: nil, count: remainingDays))
        
        return days
    }
    
    // Formatter for the month and year display
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    // Navigate to previous month
    private func previousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = newDate
        }
    }
    
    // Navigate to next month
    private func nextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = newDate
        }
    }
    
    // Check if a date is selected
    private func isDateSelected(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return selectedDates.contains(where: { calendar.isDate($0, inSameDayAs: date) })
    }
    
    // Toggle date selection
    private func toggleDate(_ date: Date) {
        let calendar = Calendar.current
        
        if let index = selectedDates.firstIndex(where: { calendar.isDate($0, inSameDayAs: date) }) {
            selectedDates.remove(at: index)
        } else {
            // Add the date with time set to the start of the day
            let startOfDay = calendar.startOfDay(for: date)
            selectedDates.append(startOfDay)
        }
        
        refreshToggle.toggle()
    }
}

// Individual day button component
struct DayButton: View {
    let date: Date
    let isSelected: Bool
    let onToggle: (Date) -> Void
    
    var body: some View {
        Button(action: {
            onToggle(date)
        }) {
            Text("\(Calendar.current.component(.day, from: date))")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .frame(height: 40)
    }
}

#Preview {
    MultiDatePickerView(onSave: { _ in })
} 