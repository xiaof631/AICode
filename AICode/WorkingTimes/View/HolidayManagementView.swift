import SwiftUI

struct HolidayManagementView: View {
    @ObservedObject var scheduleManager = WorkScheduleManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDate: Date = Date()
    @State private var showingAddHolidayPicker = false
    
    var body: some View {
        List {
            Section(header: Text(NSLocalizedString("Add Holiday", comment: ""))) {
                Button(NSLocalizedString("Add New Holiday", comment: "")) {
                    showingAddHolidayPicker = true
                }
            }
            
            Section(header: Text(NSLocalizedString("Current Holidays", comment: ""))) {
                let holidays = HolidayManager.shared.getAllHolidays().sorted()
                
                if holidays.isEmpty {
                    Text(NSLocalizedString("No holidays added", comment: ""))
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(holidays, id: \.self) { date in
                        HStack {
                            Text(dateFormatter.string(from: date))
                            
                            Spacer()
                            
                            Button {
                                HolidayManager.shared.removeHoliday(date: date)
                                scheduleManager.updateStatus()
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            
            Section(header: Text(NSLocalizedString("Default Holidays", comment: ""))) {
                Button(NSLocalizedString("Load Default Holidays for Current Year", comment: "")) {
                    // Load holidays for the current year
                    let currentYear = Calendar.current.component(.year, from: Date())
                    HolidayManager.shared.loadHolidays(for: currentYear)
                    scheduleManager.updateStatus()
                }
                
                Button(NSLocalizedString("Clear All Holidays", comment: ""), role: .destructive) {
                    HolidayManager.shared.clearHolidays()
                    scheduleManager.updateStatus()
                }
            }
        }
        .navigationTitle(NSLocalizedString("Manage Holidays", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddHolidayPicker) {
            AddHolidayView(selectedDate: $selectedDate, onSave: { date in
                HolidayManager.shared.addHoliday(date: date)
                scheduleManager.updateStatus()
                showingAddHolidayPicker = false
            })
        }
    }
    
    // Date formatter for display
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

// View for adding a holiday
struct AddHolidayView: View {
    @Binding var selectedDate: Date
    var onSave: (Date) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(NSLocalizedString("Select Date", comment: ""), selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                
                Spacer()
                
                Button(NSLocalizedString("Add as Holiday", comment: "")) {
                    onSave(selectedDate)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .navigationTitle(NSLocalizedString("Add Holiday", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Cancel", comment: "")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        HolidayManagementView()
    }
} 