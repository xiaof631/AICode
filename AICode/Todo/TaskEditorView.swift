import SwiftUI

struct TaskEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let task: TodoTask?
    let onSave: (TodoTask) -> Void
    
    @State private var title: String
    @State private var quadrant: TaskQuadrant
    @State private var isCompleted: Bool
    @State private var completionNotes: String // 新增：完成情况备注
    @State private var incompleteReason: String // 新增：未完成原因说明
    
    init(task: TodoTask?, onSave: @escaping (TodoTask) -> Void) {
        self.task = task
        self.onSave = onSave
        
        _title = State(initialValue: task?.title ?? "")
        _quadrant = State(initialValue: task?.quadrant ?? .importantUrgent)
        _isCompleted = State(initialValue: task?.isCompleted ?? false)
        _completionNotes = State(initialValue: task?.completionNotes ?? "")
        _incompleteReason = State(initialValue: task?.incompleteReason ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("任务信息")) {
                    TextField("任务标题", text: $title)
                    
                    Picker("重要性与紧急性", selection: $quadrant) {
                        ForEach(TaskQuadrant.allCases) { quadrant in
                            Text(quadrant.name).tag(quadrant)
                        }
                    }
                    
                    Toggle("已完成", isOn: $isCompleted)
                }
                
                Section(header: Text("备注信息")) {
                    if isCompleted {
                        // 如果任务已完成，显示完成情况备注
                        TextField("完成情况说明", text: $completionNotes)
                            .frame(height: 60)
                    } else {
                        // 如果任务未完成，显示未完成原因
                        TextField("未完成原因说明", text: $incompleteReason)
                            .frame(height: 60)
                    }
                }
            }
            .navigationBarTitle(task == nil ? "添加任务" : "编辑任务", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    let newTask = TodoTask(
                        id: task?.id ?? UUID(),
                        title: title,
                        quadrant: quadrant,
                        isCompleted: isCompleted,
                        completionNotes: completionNotes,
                        incompleteReason: incompleteReason
                    )
                    onSave(newTask)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(title.isEmpty)
            )
        }
    }
}