import SwiftUI

struct ReflectionView: View {
    @ObservedObject var dataManager: TodoDataManager
    @State private var showingSaveConfirmation = false
    @State private var showingHistory = false
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // 如果当前日志没有复盘数据，创建一个空的
    private var reflection: Binding<Reflection> {
        if dataManager.currentLog.reflection == nil {
            dataManager.currentLog.reflection = Reflection()
        }
        return Binding(
            get: { self.dataManager.currentLog.reflection ?? Reflection() },
            set: { self.dataManager.currentLog.reflection = $0 }
        )
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题和按钮部分 - 改为两行显示
            VStack(spacing: 12) {
                // 第一行：标题
                HStack {
                    Text(dataManager.currentLog.dateString)
                        .font(.system(size: horizontalSizeClass == .regular ? 34 : 28, weight: .bold))
                    
                    Spacer()
                }
                
                // 第二行：按钮
                HStack {
                    // 历史记录按钮
                    Button(action: {
                        // 确保加载所有日志
                        dataManager.loadAllLogs()
                        showingHistory = true
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("历史")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.trailing, 8)
                    
                    // 保存按钮
                    Button(action: {
                        dataManager.saveData()
                        showingSaveConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("保存")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 描述经过部分
                    reflectionSection(
                        title: "① 描述经过",
                        subtitle: "以便日后回顾时能想起当时的场景",
                        color: .blue,
                        binding: reflection.description
                    )
                    
                    // 分析原因部分
                    reflectionSection(
                        title: "② 分析原因",
                        subtitle: "多问几个为什么，直到有深度的启发",
                        color: .orange,
                        binding: reflection.analysis
                    )
                    
                    // 改进措施部分
                    reflectionSection(
                        title: "③ 改进措施",
                        subtitle: "尽可能提炼出一个认知点或行动点",
                        color: .green,
                        binding: reflection.improvement
                    )
                }
                .padding()
            }
        }
        .alert(isPresented: $showingSaveConfirmation) {
            Alert(
                title: Text("保存成功"),
                message: Text("复盘数据已成功保存"),
                dismissButton: .default(Text("确定"))
            )
        }
        .sheet(isPresented: $showingHistory) {
            ReflectionHistoryListView(dataManager: dataManager)
        }
    }
    
    // 复盘部分通用视图
    private func reflectionSection(title: String, subtitle: String, color: Color, binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            TextEditor(text: binding)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        }
        .padding()
        .background(Color(.systemGray5).opacity(0.3))
        .cornerRadius(10)
    }
}

// 历史记录列表视图
struct ReflectionHistoryListView: View {
    @ObservedObject var dataManager: TodoDataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedLog: DailyLog? = nil
    @State private var showingDetail = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dataManager.allLogs.filter { $0.reflection != nil }) { log in
                    Button(action: {
                        selectedLog = log
                        showingDetail = true
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(log.dateString)
                                    .font(.headline)
                                
                                if let reflection = log.reflection {
                                    Text(reflection.description.prefix(50) + (reflection.description.count > 50 ? "..." : ""))
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("复盘历史")
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingDetail) {
                if let log = selectedLog {
                    HistoricalReflectionDetailView(log: log)
                }
            }
        }
    }
}

struct ReflectionView_Previews: PreviewProvider {
    static var previews: some View {
        ReflectionView(dataManager: TodoDataManager())
    }
}
