import SwiftUI

struct TimeMasterView: View {
    var body: some View {
        VStack {
            Text("全能时间管家")
                .font(.largeTitle)
                .padding()
            
            List {
                Section(header: Text("常用场景")) {
                    NavigationLink("工作场景") {
                        Text("工作场景")
                    }
                    NavigationLink("健康场景") {
                        Text("健康场景")
                    }
                    NavigationLink("家庭场景") {
                        Text("家庭场景")
                    }
                    NavigationLink("厨房场景") {
                        Text("厨房场景")
                    }
                }
                
                Section(header: Text("其他场景")) {
                    NavigationLink("学习场景") {
                        Text("学习场景")
                    }
                    NavigationLink("交通场景") {
                        Text("交通场景")
                    }
                    NavigationLink("社交场景") {
                        Text("社交场景")
                    }
                    NavigationLink("个人护理") {
                        Text("个人护理")
                    }
                    NavigationLink("休闲娱乐") {
                        Text("休闲娱乐")
                    }
                    NavigationLink("特殊场合") {
                        Text("特殊场合")
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        TimeMasterView()
    }
} 